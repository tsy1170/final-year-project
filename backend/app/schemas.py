from pydantic import BaseModel, EmailStr, Field


#  ------------------------Pydantic model for user registration----------------------------
class UserRegister(BaseModel):
    user_name: str = Field(min_length=2, max_length=100, description="User's name")
    email: EmailStr = Field(description="User's email address")
    password: str = Field(min_length=8, max_length=128, description="User's password")
# -----------------------------------------------------------------------------------------


# -----------------------Pydantic model for access token response-----------------------
class AccessTokenResponse(BaseModel):
    access_token: str = Field(description="JWT access token for authenticated user")
    token_type: str = Field(description="Type of the token, typically 'bearer'")
    expires_in: int = Field(description="Time in seconds until the token expires")
    user: dict = Field(description="User information associated with the token")
# --------------------------------------------------------------------------------------


class FavouriteItem(BaseModel):
    item_code: int = Field(gt = 0, description="Unique identifier for the product")


# ------------------------Pydantic model for basket optimization input----------------------------
class BasketItemInput(BaseModel):
    item_code: int = Field(gt=0, description="Unique identifier for the product")


class BasketOptimizationInput(BaseModel):
    latitude: float = Field(ge=-90, le=90, description="User's current latitude")
    longitude: float = Field(ge=-180, le=180, description="User's current longitude")
    basket_items: list[BasketItemInput] = Field(min_length=1, max_length=30, description="List of items in the user's basket")
    radius_km: float = Field(default=10, gt=0, le=30, description="Search radius in kilometers for finding product prices")
    travel_cost_per_km: float = Field(default=0.15, ge=0, le=10, description="Travel cost per kilometer for the user")
# ------------------------------------------------------------------------------------------------
