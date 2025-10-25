import base64
import json
import os
import time
from typing import Optional, List, Dict, Any, Union
from google import genai
from dotenv import load_dotenv
from app.models.nutrition_output_payload import NutritionResponseModel
from app.services.image_service import ImageService
from app.services.prompt_service import PromptService
from app.services.barcode_service import BarcodeService
from app.models.nutrition_input_payload import NutritionInputPayload
from app.models.service_response import (
    NutritionServiceResponse,
    ErrorResponse,
    ServiceMetadata,
)

import requests

from app.utils.token import calculate_cost
from app.exceptions import (
    ExternalServiceException,
    ConfigurationException,
    NutritionAnalysisException,
    BusinessLogicException,
    ValidationException,
    ImageProcessingException,
    gemini_api_error,
    env_variable_missing,
    api_key_invalid,
    no_food_detected,
    low_confidence_analysis,
)
from app.models.error_models import ErrorCode
from google.genai import types

load_dotenv()


class NutritionService:
    """
    Service class for handling nutrition analysis operations.
    Provides methods for analyzing food images and extracting nutritional information.
    """

    _client = None

    @classmethod
    def _get_client(cls) -> genai.Client:
        """Get or create the Gemini client instance with proper error handling."""
        if cls._client is None:
            try:
                api_key = os.getenv("GOOGLE_API_KEY")
                if not api_key:
                    raise env_variable_missing("GOOGLE_API_KEY")

                cls._client = genai.Client(api_key=api_key)

            except Exception as e:
                if "authentication" in str(e).lower() or "api key" in str(e).lower():
                    raise api_key_invalid("Google Gemini AI")
                else:
                    raise ConfigurationException(
                        message=f"Failed to initialize Gemini client: {str(e)}",
                        error_code=ErrorCode.CONFIGURATION_ERROR,
                    ) from e

        return cls._client

    @staticmethod
    def _handle_barcode_scan(
        query: NutritionInputPayload,
        start_time: float
    ) -> NutritionServiceResponse:
        """
        Handle barcode scanning by using Gemini to extract barcode 
        and looking it up in product database.
        
        Args:
            query: NutritionInputPayload containing image URL and scan mode
            start_time: Start time of the request
            
        Returns:
            NutritionServiceResponse with product nutrition data
        """
        try:
            client = NutritionService._get_client()
            
            # Download image
            image_path = query.imageUrl
            if '/uploads/' in image_path:
                filename = image_path.split('/uploads/')[-1]
                local_file_path = os.path.join('uploads', filename)
                
                if not os.path.exists(local_file_path):
                    raise ImageProcessingException(
                        message=f"Image file not found: {filename}",
                        error_code=ErrorCode.INTERNAL_SERVER_ERROR,
                    )
                
                with open(local_file_path, 'rb') as f:
                    image_bytes = f.read()
            else:
                response = requests.get(image_path, timeout=10)
                response.raise_for_status()
                image_bytes = response.content
            
            image = types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg")
            
            # Use Gemini to extract barcode number
            ocr_prompt = "Extract the barcode number from this image. Look for any numeric barcode (UPC, EAN, etc.). Return ONLY the numeric barcode value, nothing else. If you cannot find a barcode, respond with 'NO_BARCODE'."
            
            response = client.models.generate_content(
                model="gemini-2.0-flash",
                contents=[ocr_prompt, image],
            )
            
            barcode_text = response.text.strip()
            
            if barcode_text == "NO_BARCODE":
                raise ValidationException(
                    message="Could not detect barcode in image. Please ensure the barcode is clearly visible and try again.",
                    error_code=ErrorCode.MISSING_REQUIRED_FIELD,
                    field="barcode",
                    suggestion="Make sure the barcode is in focus and well-lit.",
                )
            
            barcode = BarcodeService.extract_barcode_from_text(barcode_text)
            
            if not barcode:
                raise ValidationException(
                    message=f"Could not parse barcode from detected text: {barcode_text}. Please try again.",
                    error_code=ErrorCode.MISSING_REQUIRED_FIELD,
                    field="barcode",
                    suggestion="Ensure the barcode is clearly visible in the image.",
                )
            
            print(f"🔍 Detected barcode: {barcode}")
            
            # Look up product in database
            product_data = BarcodeService.lookup_product_by_barcode(barcode)
            
            if not product_data:
                raise ValidationException(
                    message=f"Product with barcode {barcode} not found in the Open Food Facts database.",
                    error_code=ErrorCode.MISSING_REQUIRED_FIELD,
                    field="barcode",
                    suggestion="Try scanning a different product or use regular food scanning.",
                )
            
            print(f"✅ Product found: {product_data.get('product_name')}")
            
            # Convert Open Food Facts data to NutritionResponseModel format
            from app.models.nutrition_output_payload import NutritionInfo, Portion
            
            nutriments = product_data.get("nutriments", {})
            
            # Create nutrition info from product data
            nutrition_info = NutritionInfo(
                name=product_data.get("product_name", "Unknown Product"),
                calories=int(nutriments.get("energy-kcal_100g", 0)),
                protein=int(nutriments.get("proteins_100g", 0)),
                carbs=int(nutriments.get("carbohydrates_100g", 0)),
                fat=int(nutriments.get("fat_100g", 0)),
                fiber=int(nutriments.get("fiber_100g", 0)),
                healthScore=75,  # Default for packaged products
                healthComments=f"Packaged product: {product_data.get('brands', 'Unknown brand')}"
            )
            
            # Create nutrition response matching your schema
            nutrition_data = NutritionResponseModel(
                foodName=product_data.get("product_name", "Unknown Product"),
                portion=Portion.GRAM,
                portionSize=100.0,  # Open Food Facts provides per 100g/100ml
                confidenceScore=10,  # High confidence for barcode lookup
                ingredients=[nutrition_info],
                primaryConcerns=[],
                suggestAlternatives=[],
                overallHealthScore=75,
                overallHealthComments=f"Scanned product from barcode database. Brand: {product_data.get('brands', 'Unknown')}. Nutritional values are per 100g/100ml.",
            )
            
            execution_time = time.time() - start_time
            metadata = ServiceMetadata(
                execution_time_seconds=round(execution_time, 4)
            )
            
            return NutritionServiceResponse(
                response=nutrition_data,
                status=200,
                message=f"SUCCESS - Product found: {product_data.get('product_name')}",
                metadata=metadata,
            )
            
        except (ValidationException, ImageProcessingException) as e:
            raise e
        except Exception as e:
            raise NutritionAnalysisException(
                message=f"Error processing barcode scan: {str(e)}",
                error_code=ErrorCode.INTERNAL_SERVER_ERROR,
            ) from e

    @staticmethod
    def get_nutrition_data(
        query: NutritionInputPayload,
    ) -> NutritionServiceResponse:
        """
        Analyze food image and extract nutritional information using Gemini AI 
        or barcode lookup with comprehensive error handling.

        Args:
            query: NutritionInputPayload containing image data and user preferences

        Returns:
            Union[NutritionServiceResponse, ErrorResponse]: Structured response with nutrition data and metadata
        """
        start_time = time.time()

        try:
            # Handle barcode scanning mode
            if query.scanMode == "barcode":
                return NutritionService._handle_barcode_scan(query, start_time)

            # Regular food image analysis
            try:
                prompt = PromptService.get_nutrition_analysis_prompt_for_image(
                    user_message=query.food_description,
                    selectedGoal=query.selectedGoals,
                    selectedDiet=query.dietaryPreferences,
                    selectedAllergy=query.allergies,
                    imageUrl=query.imageUrl,
                )
            except Exception as e:
                raise BusinessLogicException(
                    message=f"Failed to generate analysis prompt: {str(e)}",
                    error_code=ErrorCode.INTERNAL_SERVER_ERROR,
                ) from e

            client = NutritionService._get_client()

            image_path = query.imageUrl
            
            # Check if this is a local upload (contains /uploads/)
            if '/uploads/' in image_path:
                # Extract filename from URL and read directly from filesystem
                filename = image_path.split('/uploads/')[-1]
                local_file_path = os.path.join('uploads', filename)
                
                if not os.path.exists(local_file_path):
                    raise ImageProcessingException(
                        message=f"Image file not found: {filename}",
                        error_code=ErrorCode.INTERNAL_SERVER_ERROR,
                    )
                
                with open(local_file_path, 'rb') as f:
                    image_bytes = f.read()
            else:
                # Download from external URL
                try:
                    response = requests.get(image_path, timeout=10)
                    response.raise_for_status()
                    image_bytes = response.content
                except requests.exceptions.RequestException as e:
                    raise ImageProcessingException(
                        message=f"Failed to download image from URL: {str(e)}",
                        error_code=ErrorCode.INTERNAL_SERVER_ERROR,
                    ) from e

            image = types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg")

            try:
                response = client.models.generate_content(
                    config={
                        "response_mime_type": "application/json",
                        "response_schema": NutritionResponseModel,
                        "temperature": 0,
                    },
                    model="gemini-2.0-flash",
                    contents=[prompt, image],
                )
            except Exception as e:
                error_message = str(e).lower()

                if "rate limit" in error_message or "quota" in error_message:
                    raise ExternalServiceException(
                        message="API rate limit exceeded. Please try again later.",
                        error_code=ErrorCode.API_RATE_LIMIT_EXCEEDED,
                        service_name="Gemini AI",
                        retry_after=60,
                    ) from e
                elif "authentication" in error_message or "api key" in error_message:
                    raise api_key_invalid("Google Gemini AI")
                elif "timeout" in error_message:
                    raise ExternalServiceException(
                        message="Request to Gemini AI timed out. Please try again.",
                        error_code=ErrorCode.EXTERNAL_SERVICE_TIMEOUT,
                        service_name="Gemini AI",
                    ) from e
                else:
                    raise gemini_api_error(
                        message=f"Gemini AI service error: {str(e)}"
                    ) from e

            try:
                input_token_count = response.usage_metadata.prompt_token_count  # type: ignore
                output_token_count = response.usage_metadata.candidates_token_count  # type: ignore
                total_token_count = response.usage_metadata.total_token_count  # type: ignore
                total_cost = calculate_cost(input_token_count, output_token_count)
            except Exception as e:
                input_token_count = 0
                output_token_count = 0
                total_token_count = 0
                total_cost = 0.0

            try:
                nutrition_data = response.parsed

                if not nutrition_data:
                    raise NutritionAnalysisException(
                        message="No nutrition data received from analysis service",
                        error_code=ErrorCode.INTERNAL_SERVER_ERROR,
                    )

                print("Parsed response from Gemini:", nutrition_data)

            except NutritionAnalysisException:
                raise
            except Exception as e:
                raise NutritionAnalysisException(
                    message=f"Failed to parse nutrition analysis results: {str(e)}",
                    error_code=ErrorCode.INTERNAL_SERVER_ERROR,
                ) from e

            execution_time = time.time() - start_time

            metadata = ServiceMetadata(
                input_token_count=input_token_count,
                output_token_count=output_token_count,
                total_token_count=total_token_count,
                estimated_cost=total_cost,
                execution_time_seconds=round(execution_time, 4),
            )

            return NutritionServiceResponse(
                response=nutrition_data,
                status=200,
                message="SUCCESS",
                metadata=metadata,
            )

        except (
            ValidationException,
            ImageProcessingException,
            NutritionAnalysisException,
            ExternalServiceException,
            ConfigurationException,
            BusinessLogicException,
        ) as e:
            raise e

        except Exception as e:
            execution_time = time.time() - start_time
            metadata = ServiceMetadata(execution_time_seconds=round(execution_time, 4))

            return ErrorResponse(
                response="",
                status=500,
                message=f"Internal server error: {str(e)}",
                metadata=metadata,
            )

    @staticmethod
    def log_food_nutrition_data_using_description(
        payload: NutritionInputPayload,
    ) -> NutritionServiceResponse:
        """
        Log food nutrition data using a description with proper error handling.
        This function is a placeholder for future implementation.

        Args:
            payload: NutritionInputPayload containing image data and metadata

        Returns:
            LogNutritionResponse: Response indicating success/failure of logging operation
        """
        start_time = time.time()

        try:

            try:
                prompt = PromptService.get_nutrition_analysis_prompt_from_description(
                    user_message=payload.food_description,
                    selectedGoal=payload.selectedGoals,
                    selectedDiet=payload.dietaryPreferences,
                    selectedAllergy=payload.allergies,
                )
            except Exception as e:
                raise BusinessLogicException(
                    message=f"Failed to generate analysis prompt: {str(e)}",
                    error_code=ErrorCode.INTERNAL_SERVER_ERROR,
                ) from e

            client = NutritionService._get_client()

            try:
                response = client.models.generate_content(
                    config={
                        "response_mime_type": "application/json",
                        "response_schema": NutritionResponseModel,
                        "temperature": 0,
                    },
                    model="gemini-2.0-flash",
                    contents=prompt,
                )
            except Exception as e:
                error_message = str(e).lower()

                if "rate limit" in error_message or "quota" in error_message:
                    raise ExternalServiceException(
                        message="API rate limit exceeded. Please try again later.",
                        error_code=ErrorCode.API_RATE_LIMIT_EXCEEDED,
                        service_name="Gemini AI",
                        retry_after=60,
                    ) from e
                elif "authentication" in error_message or "api key" in error_message:
                    raise api_key_invalid("Google Gemini AI")
                elif "timeout" in error_message:
                    raise ExternalServiceException(
                        message="Request to Gemini AI timed out. Please try again.",
                        error_code=ErrorCode.EXTERNAL_SERVICE_TIMEOUT,
                        service_name="Gemini AI",
                    ) from e
                else:
                    raise gemini_api_error(
                        message=f"Gemini AI service error: {str(e)}"
                    ) from e

            try:
                input_token_count = response.usage_metadata.prompt_token_count  # type: ignore
                output_token_count = response.usage_metadata.candidates_token_count  # type: ignore
                total_token_count = response.usage_metadata.total_token_count  # type: ignore
                total_cost = calculate_cost(input_token_count, output_token_count)
            except Exception as e:
                input_token_count = 0
                output_token_count = 0
                total_token_count = 0
                total_cost = 0.0

            try:
                nutrition_data = response.parsed

                if not nutrition_data:
                    raise NutritionAnalysisException(
                        message="No nutrition data received from analysis service",
                        error_code=ErrorCode.INTERNAL_SERVER_ERROR,
                    )

            except NutritionAnalysisException:
                raise
            except Exception as e:
                raise NutritionAnalysisException(
                    message=f"Failed to parse nutrition analysis results: {str(e)}",
                    error_code=ErrorCode.INTERNAL_SERVER_ERROR,
                ) from e

            execution_time = time.time() - start_time

            metadata = ServiceMetadata(
                input_token_count=input_token_count,
                output_token_count=output_token_count,
                total_token_count=total_token_count,
                estimated_cost=total_cost,
                execution_time_seconds=round(execution_time, 4),
            )

            return NutritionServiceResponse(
                response=nutrition_data,
                status=200,
                message="SUCCESS",
                metadata=metadata,
            )

        except (
            ValidationException,
            ImageProcessingException,
            NutritionAnalysisException,
            ExternalServiceException,
            ConfigurationException,
            BusinessLogicException,
        ) as e:
            raise e

        except Exception as e:
            execution_time = time.time() - start_time
            metadata = ServiceMetadata(execution_time_seconds=round(execution_time, 4))

            return ErrorResponse(
                response="",
                status=500,
                message=f"Internal server error: {str(e)}",
                metadata=metadata,
            )