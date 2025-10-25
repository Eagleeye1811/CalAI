import requests
from typing import Optional, Dict, Any
from app.exceptions import ValidationException
from app.models.error_models import ErrorCode


class BarcodeService:
    """Service for handling barcode scanning and product lookup."""
    
    @staticmethod
    def lookup_product_by_barcode(barcode: str) -> Optional[Dict[str, Any]]:
        """
        Look up product nutrition info from Open Food Facts database.
        
        Args:
            barcode: The barcode number
            
        Returns:
            Product data if found, None otherwise
        """
        try:
            url = f"https://world.openfoodfacts.org/api/v0/product/{barcode}.json"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get("status") == 1:  # Product found
                    product = data.get("product", {})
                    return {
                        "product_name": product.get("product_name", "Unknown Product"),
                        "brands": product.get("brands", ""),
                        "quantity": product.get("quantity", ""),
                        "image_url": product.get("image_url", ""),
                        "nutriments": product.get("nutriments", {}),
                        "serving_size": product.get("serving_size", ""),
                    }
            return None
        except Exception as e:
            print(f"Error looking up barcode: {e}")
            return None
    
    @staticmethod
    def extract_barcode_from_text(text: str) -> Optional[str]:
        """
        Extract barcode number from OCR text.
        Looks for sequences of 8, 12, or 13 digits (common barcode formats).
        
        Args:
            text: OCR extracted text
            
        Returns:
            Barcode number if found
        """
        import re
        
        # Look for 8, 12, or 13 digit numbers (common barcode formats)
        patterns = [
            r'\b\d{13}\b',  # EAN-13
            r'\b\d{12}\b',  # UPC-A
            r'\b\d{8}\b',   # EAN-8
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                return match.group(0)
        
        return None