from typing import Optional, List
from pydantic import BaseModel, Field


class NutritionInputPayload(BaseModel):
    """
    Represents the input payload for nutrition data.
    """

    imageData: Optional[str] = Field(None, description="Base64 encoded image data")
    imageUrl: Optional[str] = Field(
        None, description="URL of the image for nutrition analysis"
    )
    food_description: Optional[str] = Field(
        None, description="Description of the food item"
    )
    dietaryPreferences: List[str] = Field(
        default_factory=list, description="User's dietary preferences"
    )
    allergies: List[str] = Field(
        default_factory=list, description="User's food allergies"
    )
    selectedGoals: List[str] = Field(
        default_factory=list, description="User's health goals"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "imageUrl": "https://example.com/image.jpg",
                "food_description": "Chicken Caesar Salad with croutons",
                "dietaryPreferences": ["low-carb", "high-protein"],
                "allergies": ["nuts", "shellfish"],
                "selectedGoals": ["weight_loss", "muscle_gain"],
            }
        }