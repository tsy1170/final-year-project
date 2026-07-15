from fastapi import FastAPI, Query, Request, HTTPException, status
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import create_engine, text
from sqlalchemy.exc import IntegrityError
from dotenv import load_dotenv
from pathlib import Path
from pwdlib import PasswordHash
import os

#  ------------------------Pydantic model for user registration----------------------------
class UserRegister(BaseModel):
    user_name: str = Field(min_length=2, max_length=100, description="User's name")
    email: EmailStr = Field(description="User's email address")
    password: str = Field(min_length=8, max_length=128, description="User's password")
# -----------------------------------------------------------------------------------------

# load environment variables from .env file
load_dotenv()

# Initialize FastAPI app and database connection
app = FastAPI()
DATABASE_URL = os.getenv("DATABASE_URL")

# Create SQLAlchemy engine for database connection
engine = create_engine(DATABASE_URL)

# Initialize password hasher
password_hasher = PasswordHash.recommended()

# Set up static file serving for product images
BASE_DIR = Path(__file__).resolve().parent.parent
IMAGE_DIRECTORY = BASE_DIR / "product_images" 
app.mount("/product_images", StaticFiles(directory=IMAGE_DIRECTORY), name="product_images")


# ----------------------------API Endpoints--------------------------------
# Root endpoint
@app.get("/")
def root():
    return {
        "message": "PriceCatcher backend is running"
    }


# Search products by name
@app.get("/products/search")
def search_products(q: str = Query(...)):
    with engine.connect() as conn:
        result = conn.execute(text("""
            SELECT
                item_code,
                item_name,
                unit,
                item_group,
                item_category
            FROM items
            WHERE item_name ILIKE :keyword
            ORDER BY item_name
            LIMIT 20;
        """), {
            "keyword": f"%{q}%"
        })

        return [dict(row._mapping) for row in result]


# Get product prices within a radius of the user's location
@app.get("/products/{item_code}/prices")
def get_product_prices(item_code: int, user_lng: float = Query(...), user_lat: float = Query(...), radius_km: float = Query(10.0)): 
    with engine.connect() as conn:
        result = conn.execute(text("""
            SELECT
                i.item_code,
                i.item_name,
                i.unit,
                p.premise_code,
                p.premise_name,
                p.address,
                p.district,
                p.state,
                p.latitude,
                p.longitude,
                pr.price,
                pr.price_date,
                ST_Distance(
                    p.location,
                    ST_SetSRID(ST_MakePoint(:user_lng, :user_lat), 4326)::geography
                ) / 1000 AS distance_km
            FROM price_records pr
            JOIN items i
                ON pr.item_code = i.item_code
            JOIN premises p
                ON pr.premise_code = p.premise_code
            WHERE pr.item_code = :item_code
            AND ST_DWithin(
                    p.location,
                    ST_SetSRID(ST_MakePoint(:user_lng, :user_lat), 4326)::geography,
                    :radius_km * 1000
            )
            ORDER BY pr.price ASC, distance_km ASC
            LIMIT 50; """), {
                "item_code": item_code,
                "user_lng": user_lng,
                "user_lat": user_lat,
                "radius_km": radius_km
            })
        
        return [dict(row._mapping) for row in result]
    

# Get product details
@app.get("/products/{item_code}")
def get_product(item_code: int, request: Request):
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT
                    item_code,
                    item_name,
                    unit,
                    item_group,
                    item_category,
                    image_path
                FROM items
                WHERE item_code = :item_code
            """),
            {
                "item_code": item_code
            }
        )

        product = result.mappings().first()

    if product is None:
        raise HTTPException(
            status_code=404,
            detail="Product not found"
        )

    image_url = None

    if product["image_path"]:
        base_url = str(request.base_url).rstrip("/")
        image_url = base_url + product["image_path"]

    return {
        "item_code": product["item_code"],
        "item_name": product["item_name"],
        "unit": product["unit"],
        "item_group": product["item_group"],
        "item_category": product["item_category"],
        "image_url": image_url,
    }


#  Get products with optional filters and pagination
@app.get("/products")
def get_products(item_group: str = Query(default = None, description = "Major products group"),
                 item_category: str = Query(default = None, description = "Sub-category under selected item group"),
                 limit: int = Query(default = 20, ge = 1, le = 100, description = "Number of products to return"),
                 offset: int = Query(default = 0, ge = 0, description = "Offset for pagination")):
    
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT 
                    item_code,
                    item_name,
                    unit,
                    item_group,
                    item_category
                FROM items
                WHERE (:item_group IS NULL OR LOWER(item_group) = LOWER(:item_group))
                AND (
                    :item_group IS NULL 
                    OR :item_category IS NULL 
                    OR LOWER(item_category) = LOWER(:item_category)
                )
                ORDER BY item_name
                LIMIT :limit 
                OFFSET :offset
            """), {
                "item_group": item_group,
                "item_category": item_category,
                "limit": limit,
                "offset": offset
            })

            products = [dict(row._mapping) for row in result]

            return {
                "item_group": item_group,
                "item_category": item_category,
                "limit": limit,
                "offset": offset,
                "products": products
            }
        
    except Exception as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = f"Failed to retrieve products: {str(e)}"
        )


# add product to favourites
@app.get("/favourites/{item_code}")
def add_favourites(item_code: int, user_id: int = Query(...)):
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                INSERT INTO favourites (user_id, item_code)
                VALUES (:user_id, :item_code)
                ON CONFLICT (user_id, item_code) DO NOTHING;
                RETURNING user_id, item_code;
            """), {
                "user_id": user_id,
                "item_code": item_code
            })

            favourite = result.mappings().first()

            if favourite is None:
                return {
                    "message": "Item already exists in favourites"
                }
            else:
                return {
                    "message": "Item added to favourites",
                    "favourite": dict(favourite)
                }
    
    except Exception as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = f"Failed to add favourite: {str(e)}"
        )


# User registration endpoint
@app.post("/users/register", status_code=status.HTTP_201_CREATED)
def register_user(user: UserRegister):
    normalized_email = str(user.email).lower().strip()
    normalized_user_name = str(user.user_name).strip()
    hashed_password = password_hasher.hash(user.password)

    try:
        with engine.begin() as conn:
            existing_user = conn.execute(text("""
                SELECT user_id FROM users
                WHERE email = :email
            """), {
                "email": normalized_email
            }).first()

            if existing_user is not None:
                raise HTTPException(
                    status_code = status.HTTP_409_CONFLICT,
                    detail = "An account with this email already exists."
                )
            
            result = conn.execute(text("""
                INSERT INTO users (user_name, email, password_hash)
                VALUES (:user_name, :email, :password_hash)  
                RETURNING user_id, user_name, email;               
            """), {
                "user_name": normalized_user_name,
                "email": normalized_email,
                "password_hash": hashed_password
            })

            new_user = result.mappings().first()

            return {
                "message": "User registered successfully",
                "user": dict(new_user)
            }

    except IntegrityError:
        raise HTTPException(
            status_code = status.HTTP_409_CONFLICT,
            detail = "An account with this email already exists."
        )
    
    except Exception as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = f"Failed to register user: {str(e)}"
        )


# Get user favourites products
@app.get("/favourites")
def get_user_favourites(user_id: int = Query(...)):
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT 
                    i.item_code,
                    i.item_name, 
                    i.unit,
                    i.item_group,
                    i.item_category,
                    i.image_path
                FROM favourites f
                JOIN items i ON f.item_code = i.item_code
                WHERE f.user_id = :user_id     
                ORDER BY i.item_name ASC;        
            """), {
                "user_id": user_id
            })

            favourites = [dict(row._mapping) for row in result]

            return {
                "message": "User favourites retrieved successfully",
                "user_id": user_id,
                "favourites": favourites
            }
        
    except Exception as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = f"Failed to retrieve favourites: {str(e)}"
        )
    

#  Remove product from user favourites
@app.delete("/favourites/{item_code}")
def remove_favourite(item_code: int, user_id: int = Query(...)):
    try:
        with engine.begin() as conn:
            deleted_item = conn.execute(text("""
                DELETE FROM favourites
                WHERE user_id = :user_id AND item_code = :item_code
                RETURNING item_code;
            """), {
                "user_id": user_id,
                "item_code": item_code
            }).scalar_one_or_none()

            if deleted_item is None:
                raise HTTPException(
                    status_code = status.HTTP_404_NOT_FOUND,
                    detail = "Item not found in user's favourites."
                )

            return {
                "message": "Item removed from favourites",
                "item__code": deleted_item
            }
        
    except Exception as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = f"Failed to remove favourite: {str(e)}"
        )
    

# Check whether a product is in user's favourites
@app.get("/favourites/{item_code}/status")
def check_favourite_status(item_code: int, user_id: int = Query(...)):
    try:
        with engine.begin() as conn:
            is_favourite = conn.execute(text("""
                SELECT EXISTS (
                    SELECT 1 FROM favourites
                    WHERE user_id = :user_id AND item_code = :item_code)
            """), {
                "user_id": user_id,
                "item_code": item_code
            }).scalar_one()

            return {
                "item_code": item_code,
                "is_favourite": is_favourite
            }
        
    except Exception as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = f"Failed to check favourite status: {str(e)}"
        )

            

            