from datetime import date
import shutil
import uuid
from uuid import UUID
from fastapi import FastAPI, File, Query, Request, HTTPException, status, Depends, UploadFile, Form
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import EmailStr
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from pathlib import Path
from typing import Annotated
from .schemas import AccessTokenResponse, UserRegister, BasketOptimizationInput, FavouriteItem
from .schemas import UpdateUsernameInput, UpdatePhoneNumberInput, UpdateDobInput, UpdateEmailInput, UpdateNricInput, UpdatePasswordInput, CreateComplaintInput, DeleteComplaintInput
from .database import engine
from .image_url_builder import build_image_url
from .basket_helpers import load_basket_data, calculate_single_store_recommendation, calculate_multi_store_recommendation
from .osrm_services import get_road_distance, get_road_distance_matrix, filter_stores_by_road_distance
from .price_level_helpers import calculate_percentile
from .auth_service import verify_password, hash_password
from .auth_dependencies import get_current_user
from .security import JWT_ACCESS_TOKEN_EXPIRE_MINUTES, create_access_token
import traceback

# Initialize FastAPI app and database connection
app = FastAPI()

# Set up static file serving for product images
BASE_DIR = Path(__file__).resolve().parent.parent
IMAGE_DIRECTORY = BASE_DIR / "product_images" 
app.mount("/product_images", StaticFiles(directory=IMAGE_DIRECTORY), name="product_images")

# Set up static file serving for complaint attachments
COMPLAINT_BASE_DIR = Path(__file__).resolve().parent.parent
COMPLAINT_ATTACHMENT_DIRECTORY = COMPLAINT_BASE_DIR / "complaint_attachments"
app.mount("/complaint_attachments", StaticFiles(directory=COMPLAINT_ATTACHMENT_DIRECTORY), name="complaint_attachments")


# ----------------------------API Endpoints--------------------------------
@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    traceback.print_exc()
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": str(exc)}
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request,
    exc: RequestValidationError
):
    errors = exc.errors()

    print("=== VALIDATION ERROR ===")
    print(exc.errors())  # prints to your server terminal

    for error in errors:
        location = error["loc"]

        if location == ("body", "new_email"):
            return JSONResponse(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                content={"detail": "Please enter a valid email address."}
            )

        if location == ("body", "current_password"):
            if error["type"] in ("string_too_short", "string_too_long"):
                return JSONResponse(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    content={"detail": "Current password is incorrect"}
                )

        if location == ("body", "new_password"):
            if error["type"] == "string_too_short":
                return JSONResponse(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    content={"detail": "New password must be at least 8 characters long."}
                )
            if error["type"] == "string_too_long":
                return JSONResponse(
                    status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                    content={"detail": "New password must not exceed 128 characters."}
                )

            

    # still return a readable response to Flutter
    return JSONResponse(
        status_code=422,
        content={"detail": exc.errors()}
    )

    

# Root endpoint
@app.get("/")
def root():
    return {
        "message": "PriceCatcher backend is running"
    }


# get premises within the user's road-distance radius
@app.get("/premises/nearby")
def get_nearby_premises(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(default=10, gt=0, le=50)
):
    try:
        with engine.connect() as conn:
            rows = conn.execute(text("""
                WITH user_location AS (
                    SELECT ST_SetSRID(
                        ST_MakePoint(
                            :user_longitude,
                            :user_latitude
                        ),
                        4326
                    )::geography AS location
                )

                SELECT
                    p.premise_code,
                    p.premise_name,
                    p.premise_type,
                    p.address,
                    p.district,
                    p.state,
                    p.latitude,
                    p.longitude,
                    ST_Distance(
                        p.location,
                        ul.location
                    ) / 1000.0 AS straight_line_distance_km

                FROM premises p
                CROSS JOIN user_location ul

                WHERE p.location IS NOT NULL
                  AND p.latitude IS NOT NULL
                  AND p.longitude IS NOT NULL
                  AND ST_DWithin(
                      p.location,
                      ul.location,
                      :radius_metres
                  )

                ORDER BY straight_line_distance_km
            """), {
                "user_latitude": latitude,
                "user_longitude": longitude,
                "radius_metres": radius_km * 1000
            }).mappings().all()

    except SQLAlchemyError as e:
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to retrieve nearby premises"
        ) from e

    if not rows:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No premises were found within the selected radius"
        )

    candidate_premises = [
        {
            "premise_code": row["premise_code"],
            "premise_name": row["premise_name"],
            "premise_type": row["premise_type"],
            "address": row["address"],
            "district": row["district"],
            "state": row["state"],
            "latitude": float(row["latitude"]),
            "longitude": float(row["longitude"]),
            "straight_line_distance_km": round(
                float(row["straight_line_distance_km"]),
                3
            )
        }
        for row in rows
    ]

    premises_with_road_distance = get_road_distance(
        user_latitude=latitude,
        user_longitude=longitude,
        stores=candidate_premises
    )

    nearby_premises = [
        premise for premise in premises_with_road_distance
        if premise["road_distance_km"] <= radius_km
    ]

    nearby_premises.sort(key=lambda premise: premise["road_distance_km"])

    if not nearby_premises:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Premises were found within the straight-line radius, but "
                "none are within the selected road-distance radius"
            )
        )

    for premise in nearby_premises:
        premise["road_distance_km"] = round(
            float(premise["road_distance_km"]),
            3
        )
        premise["driving_duration_minutes"] = round(
            float(premise["driving_duration_minutes"]),
            1
        )

    return {
        "count": len(nearby_premises),
        "radius_km": radius_km,
        "premises": nearby_premises
    }


# get items group and item category
@app.get("/products/categories")
def get_product_categories():
    sql = text("""
        SELECT DISTINCT
            item_group,
            item_category
        FROM items
        WHERE item_group IS NOT NULL
          AND item_group <> ''
          AND item_category IS NOT NULL
          AND item_category <> ''
        ORDER BY
            item_group,
            item_category
    """)

    try:
        with engine.connect() as conn:
            rows = conn.execute(sql).mappings().all()

    except SQLAlchemyError as error:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to retrieve product categories"
        ) from error

    grouped_categories: dict[str, list[str]] = {}

    for row in rows:
        item_group = row["item_group"]
        item_category = row["item_category"]

        if item_group not in grouped_categories:
            grouped_categories[item_group] = []

        grouped_categories[item_group].append(item_category)

    return {
        "count": len(grouped_categories),
        "item_groups": [
            {
                "item_group": item_group,
                "item_categories": item_categories
            }
            for item_group, item_categories
            in grouped_categories.items()
        ]
    }


# get all the prices with level (low, medium, and high) across nearby shops
@app.get("/products/{item_code}/nearby-price-levels")
def get_nearby_price_levels(item_code: int,
                            latitude: float = Query(..., ge=-90, le=90),
                            longitude: float = Query(..., ge=-180, le=180),
                            radius_km: float = Query(default=10, gt=0, le=50),
                            request: Request = None):

    try:
        with engine.connect() as conn:
            rows = conn.execute(text("""
                WITH user_location AS (
                    SELECT ST_SetSRID(
                        ST_MakePoint(
                            :user_longitude,
                            :user_latitude
                        ),
                        4326
                    )::geography AS location
                ),

                nearby_premises AS (
                    SELECT
                        p.premise_code,
                        p.premise_name,
                        p.address,
                        p.district,
                        p.state,
                        p.latitude,
                        p.longitude,

                        ST_Distance(
                            p.location,
                            ul.location
                        ) / 1000.0
                            AS straight_line_distance_km

                    FROM premises p

                    CROSS JOIN user_location ul

                    WHERE p.location IS NOT NULL
                    AND p.latitude IS NOT NULL
                    AND p.longitude IS NOT NULL

                    AND ST_DWithin(
                            p.location,
                            ul.location,
                            :radius_metres
                    )
                ),

                latest_prices AS (
                    SELECT DISTINCT ON (
                        pr.premise_code
                    )
                        pr.premise_code,
                        pr.item_code,
                        pr.price,
                        pr.price_date

                    FROM price_records pr

                    JOIN nearby_premises np
                        ON np.premise_code =
                        pr.premise_code

                    WHERE pr.item_code = :item_code

                    ORDER BY
                        pr.premise_code,
                        pr.price_date DESC
                )

                SELECT
                    i.item_code,
                    i.item_name,
                    i.unit,
                    i.image_path,

                    np.premise_code,
                    np.premise_name,
                    np.address,
                    np.district,
                    np.state,
                    np.latitude,
                    np.longitude,
                    np.straight_line_distance_km,

                    lp.price,
                    lp.price_date

                FROM latest_prices lp

                JOIN nearby_premises np
                    ON np.premise_code =
                    lp.premise_code

                JOIN items i
                    ON i.item_code =
                    lp.item_code

                ORDER BY
                    np.straight_line_distance_km,
                    lp.price
            """),{
                "item_code": item_code,
                "user_latitude": latitude,
                "user_longitude": longitude,
                "radius_metres": radius_km * 1000
            }
        ).mappings().all()

    except SQLAlchemyError as error:
        traceback.print_exc()
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = f"Unable to retrieve nearby item prices"
        )

    if not rows:
        raise HTTPException(
            status_code = status.HTTP_404_NOT_FOUND,
            detail = "No price records for this item were found"
        )

    # get the shared values like item code, store count, price statistics 
    first_row = rows[0]
    item_image_url = build_image_url(request, first_row["image_path"])

    candidate_stores = []

    for row in rows:
        candidate_stores.append({
            "premise_code": row["premise_code"],
            "premise_name": row["premise_name"],
            "address": row["address"],
            "district": row["district"],
            "state": row["state"],
            "latitude": float(row["latitude"]),
            "longitude": float(row["longitude"]),
            "straight_line_distance_km": round(float(row["straight_line_distance_km"]), 3),
            "price": round(float(row["price"]), 2),
            "price_date": row["price_date"]
        })

    # Calculate actual road distances using OSRM
    stores_with_road_distance = get_road_distance(
        user_latitude = latitude,
        user_longitude = longitude,
        stores = candidate_stores
    )

    # Remove stores whose driving distance exceeds the requested radius
    road_filtered_stores = [
        store for store in stores_with_road_distance
        if store["road_distance_km"] <= radius_km
    ]

    if not road_filtered_stores:
        raise HTTPException(
            status_code = status.HTTP_404_NOT_FOUND,
            detail = "Stores were found within the straight-line radius, but none are within the selected radius after considering actual road distances"
        )

    # Only road-filtered stores affect the the low, medium, and high price categories
    prices = [
        store["price"] for store in road_filtered_stores
    ]

    # price statistics
    lowest_price = min(prices)
    average_price = sum(prices) / len(prices)
    highest_price = max(prices)

    low_cutoff = calculate_percentile(prices, 1/3)
    high_cutoff = calculate_percentile(prices, 2/3)

    # add the price level to each store based on the cutoffs
    stores_response = []

    for store in road_filtered_stores:
        price = store["price"]

        if len(prices) == 1 or (lowest_price == highest_price):
            price_level = "medium"

        elif price <= low_cutoff:
            price_level = "low"

        elif price <= high_cutoff:
            price_level = "medium"

        else:
            price_level = "high"

        stores_response.append({
            "premise_code": store["premise_code"],
            "premise_name": store["premise_name"],
            "address": store["address"],
            "district": store["district"],
            "state": store["state"],
            "latitude": float(store["latitude"]),
            "longitude": float(store["longitude"]),
            "road_distance_km": round(float(store["road_distance_km"]), 3),
            "price": round(float(price), 2),
            "price_date": store["price_date"],
            "price_level": price_level
        })

    # sort the stores by price, the by road distance
    stores_response.sort(
        key = lambda store: (
            store["price"],
            store["road_distance_km"]
        )
    )

    # return results
    return {
        "item": {
            "item_code": first_row["item_code"],
            "item_name": first_row["item_name"],
            "unit": first_row["unit"],
            "image_url": item_image_url
        },

        "search": {
            "latitude": latitude,
            "longitude": longitude,
            "radius_km": radius_km,
            "road_filtered_store_count": len(stores_response)
        },

        "price_summary": {
            "lowest_price": round(lowest_price, 2),
            "average_price": round(average_price, 2),
            "highest_price": round(highest_price, 2),
            "low_cutoff": round(low_cutoff, 2),
            "high_cutoff": round(high_cutoff, 2)
        },

        # list[dict] of stores with price and distance information
        "stores": stores_response   
    }


# Search products by name
@app.get("/products/search")
def search_products(q: str = Query(...), request: Request = None):
    with engine.connect() as conn:
        result = conn.execute(text("""
            SELECT
                item_code,
                item_name,
                unit,
                item_group,
                item_category,
                image_path
            FROM items
            WHERE item_name ILIKE :keyword
            ORDER BY item_name
            LIMIT 20;
        """), {
            "keyword": f"%{q}%"
        }).mappings().all()

        search_results = []

        for row in result:
            product = dict(row)
            image_path = product.pop("image_path", None)
            product["image_url"] = build_image_url(request, image_path)
            search_results.append(product)

        return search_results


#  Get products with optional filters and pagination
@app.get("/products")
def get_products(item_group: str = Query(default = None, description = "Major products group"),
                 item_category: str = Query(default = None, description = "Sub-category under selected item group"),
                 limit: int = Query(default = 20, ge = 1, le = 100, description = "Number of products to return"),
                 offset: int = Query(default = 0, ge = 0, description = "Offset for pagination"),
                 request: Request = None):
    
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT 
                    item_code,
                    item_name,
                    unit,
                    item_group,
                    item_category,
                    image_path
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

            products = []

            for row in result:
                product = dict(row._mapping)
                image_path = product.pop("image_path", None)
                product["image_url"] = build_image_url(request, image_path)
                products.append(product)

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
            detail = f"Failed to retrieve products"
        ) from e


# User registration endpoint
@app.post("/users/register", status_code=status.HTTP_201_CREATED)
def register_user(user: UserRegister):
    normalized_email = str(user.email).lower().strip()
    normalized_user_name = str(user.user_name).strip()
    normalized_phone_number = user.phone_number.strip()
    normalized_nric = user.nric.strip()
    hashed_password = hash_password(user.password)
    
    try:
        with engine.begin() as conn:
            result = conn.execute(text("""
                INSERT INTO users (
                    user_name,
                    email,
                    password_hash,
                    phone_number,
                    dob,
                    nric
                )
                VALUES (
                    :user_name,
                    :email,
                    :password_hash,
                    :phone_number,
                    :dob,
                    :nric
                )
                ON CONFLICT DO NOTHING
                RETURNING user_id, user_name, email, phone_number, dob, nric
            """), {
                "user_name": normalized_user_name,
                "email": normalized_email,
                "password_hash": hashed_password,
                "phone_number": normalized_phone_number,
                "dob": user.dob,
                "nric": normalized_nric,
            })

            new_user = result.mappings().first()

    except HTTPException:
        raise

    except IntegrityError:
        raise HTTPException(
            status_code = status.HTTP_409_CONFLICT,
            detail = "This email already exists."
        )
    
    except Exception as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = f"Failed to register user"
        )

    if new_user is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This email already exists."
        )

    return {
        "message": "User registered successfully",
        "user": dict(new_user)
    }


# User login endpoint
@app.post("/users/login", response_model = AccessTokenResponse)
def login_user(form_data: Annotated[OAuth2PasswordRequestForm, Depends()]):
    # Although OAuth2PasswordRequestForm uses 'username', we treat it as email here
    normalized_email = str(form_data.username).lower().strip()  

    try:
        with engine.begin() as conn:
            user = conn.execute(text(""" 
                SELECT 
                    user_id,
                    user_name,
                    email,
                    password_hash
                FROM users
                WHERE LOWER(email) = LOWER(:email)
                LIMIT 1
            """), {
                "email": normalized_email
            }).mappings().first()

    except SQLAlchemyError as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = "Unable to process login"
        ) from e

    # Use the same error for missing email and wrong password.
    # To avoids revealing whether an account exists.
    if user is None:
        raise HTTPException(
            status_code = status.HTTP_401_UNAUTHORIZED,
            detail = "Invalid email or password",
            headers = {"WWW-Authenticate": "Bearer"}
        )

    try:
        password_is_valid = verify_password(form_data.password, user["password_hash"])
    except Exception as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = "Unable to verify password"
        ) from e

    # Use the same error for missing email and wrong password.
    if not password_is_valid:
        raise HTTPException(
            status_code = status.HTTP_401_UNAUTHORIZED,
            detail = "Invalid email or password",
            headers = {"WWW-Authenticate": "Bearer"}
        )

    # Generate JWT access token for the authenticated user
    access_token = create_access_token(
        user_id = user["user_id"],
        email = user["email"],
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "user": {
            "user_id": user["user_id"],
            "user_name": user["user_name"],
            "email": user["email"] 
        }
    }


# Get the currently logged-in user's information
@app.get("/users/me")
def get_logged_in_user(current_user: Annotated[dict, Depends(get_current_user)]):
    return current_user


# Update username
@app.patch("/users/me/username")
def update_username(request_data: UpdateUsernameInput,
                    current_user: Annotated[dict, Depends(get_current_user)]): 
    user_id = current_user["user_id"]

    normalized_user_name = request_data.user_name.strip()

    if len(normalized_user_name) < 2:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Username must at least contain 2 characters"
        )

    try:
        with engine.begin() as conn:
            updated_user_name = conn.execute(text("""
                UPDATE users
                    SET user_name = :user_name
                    WHERE user_id = :user_id
                RETURNING user_id, user_name, email, phone_number, dob, nric
            """), {
                "user_name": normalized_user_name,
                "user_id": user_id
            }).mappings().first()

    except SQLAlchemyError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to update username"
        ) from e

    if updated_user_name is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return {
        "message": "Username updated successfully",
        "user": dict(updated_user_name)
    }


@app.patch("/users/me/phone-number")
async def update_phone_number(request_data: UpdatePhoneNumberInput,
                              current_user: Annotated[dict, Depends(get_current_user)]):
    try:
        user_id = current_user["user_id"]

        with engine.begin() as conn:
            updated_phone_number = conn.execute(
                text("""
                    UPDATE users
                    SET phone_number = :phone_number
                    WHERE user_id = :user_id
                    RETURNING user_id, user_name, email, phone_number, dob, nric
                """),
                {
                    "phone_number": request_data.phone_number,
                    "user_id": user_id
                }
            ).mappings().first()

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to update phone number"
        ) from e

    if updated_phone_number is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return {
        "message": "Phone number updated successfully",
        "user": dict(updated_phone_number)
    }
    

@app.patch("/users/me/dob")
async def update_dob(request_data: UpdateDobInput,
                     current_user: Annotated[dict, Depends(get_current_user)]):
    try:
        user_id = current_user["user_id"]

        with engine.begin() as conn:
            updated_dob = conn.execute(
                text("""
                    UPDATE users
                    SET dob = :dob
                    WHERE user_id = :user_id
                    RETURNING user_id, user_name, email, phone_number, dob, nric
                """),
                {
                    "dob": request_data.dob,
                    "user_id": user_id
                }
            ).mappings().first()

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to update date of birth"
        ) from e

    if updated_dob is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return {
        "message": "Date of birth updated successfully",
        "user": dict(updated_dob)
    }


# Edit user's NRIC
@app.patch("/users/me/nric")
async def update_nric(request_data: UpdateNricInput,
                      current_user: Annotated[dict, Depends(get_current_user)]):
    try:
        user_id = current_user["user_id"]

        with engine.begin() as conn:
            updated_nric = conn.execute(
                text("""
                    UPDATE users
                    SET nric = :nric
                    WHERE user_id = :user_id
                    RETURNING user_id, user_name, email, phone_number, dob, nric
                """),
                {
                    "nric": request_data.nric.strip(),
                    "user_id": user_id
                }
            ).mappings().first()

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to update NRIC"
        ) from e

    if updated_nric is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return {
        "message": "NRIC updated successfully",
        "user": dict(updated_nric)
    }


# Update user's email
@app.patch("/users/me/email")
def update_email(request_data: UpdateEmailInput,
                 current_user: Annotated[dict, Depends(get_current_user)]):
    user_id = current_user["user_id"]

    normalized_email = str(request_data.new_email).strip().lower()

    try:
        with engine.begin() as conn:
            user = conn.execute(
                text("""
                SELECT
                    user_id,
                    email,
                    password_hash
                FROM users
                WHERE user_id = :user_id
                LIMIT 1
                """),
                {
                    "user_id": user_id
                }
            ).mappings().first()

            if user is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User not found"
                )

            password_is_valid = verify_password(
                request_data.current_password,
                user["password_hash"]
            )

            if not password_is_valid:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Current password is incorrect"
                )

            if normalized_email == user["email"].lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="The new email is the same as current email."
                )

            existing_email = conn.execute(
                text("""
                    SELECT user_id
                    FROM users
                    WHERE LOWER(email) = :email
                    AND user_id <> :user_id
                    LIMIT 1
                """),
                {
                    "email": normalized_email,
                    "user_id": user_id
                }
            ).first()

            if existing_email is not None:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=(
                        "An account with this email "
                        "already exists"
                    )
                )

            updated_user_email = conn.execute(
                text("""
                    UPDATE users
                    SET email = :email
                    WHERE user_id = :user_id

                    RETURNING
                        user_id,
                        user_name,
                        email
                """),
                {
                    "email": normalized_email,
                    "user_id": user_id
                }
            ).mappings().first()

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to update email"
        ) from e

    return {
        "message": "Email updated successfully. Please login again",
        "user": dict(updated_user_email)
    }

# Update user's password
@app.patch("/users/me/password")
def update_password(request_data: UpdatePasswordInput, 
                    current_user: Annotated[dict, Depends(get_current_user)]):
    user_id = current_user["user_id"]

    try:
        with engine.begin() as conn:
            user = conn.execute(
                text("""
                    SELECT password_hash
                    FROM users
                    WHERE user_id = :user_id
                    LIMIT 1
                """), {
                    "user_id": user_id
                }
            ).mappings().first()

            if user is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User not found"
                )

            current_password_is_valid = verify_password(request_data.current_password, user["password_hash"])

            if not current_password_is_valid:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Current password is incorrect"
                )

            if (request_data.current_password == request_data.new_password):
                 raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(
                        "New password must be different from current password"
                    )
                )

            new_password_hash = hash_password(request_data.new_password)

            conn.execute(
                text("""
                    UPDATE users
                    SET password_hash = :password_hash
                    WHERE user_id = :user_id
                    RETURNING user_id, user_name, email
                """),{
                    "password_hash": new_password_hash,
                    "user_id": user_id
                }
            ).mappings().first()

    except HTTPException:
        raise

    except SQLAlchemyError as e:
         raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to update password"
        ) from e

    return {
        "message": "Password updated successfully"
    }


# add product to favourite
@app.post("/favourites")
def add_favourite(request_data: FavouriteItem, 
                  current_user: Annotated[dict, Depends(get_current_user)]):
    # get the user_id from JWT payload
    user_id = current_user["user_id"]

    try: 
        with engine.begin() as conn:
            favourite = conn.execute(text("""
                INSERT INTO favourites(user_id, item_code)
                VALUES (:user_id, :item_code)
                ON CONFLICT(user_id, item_code)
                DO NOTHING
                RETURNING user_id, item_code
            """), {
                "user_id": user_id,
                "item_code": request_data.item_code
            }).mappings().first()

    except SQLAlchemyError as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = "Unable to add favourite"
        ) from e

    if favourite is None:
        return {
            "message": "Item is already in favourite"
        }

    return {
        "message": "Item already added to favourite",
        "favourite": dict(favourite)
    }


# Get user favourites products
@app.get("/favourites")
def get_user_favourites(current_user: Annotated[dict, Depends(get_current_user)], request: Request = None):
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
                "user_id": current_user["user_id"]
            })

            favourites = [dict(row._mapping) for row in result]

            for favourite in favourites:
                image_path = favourite.pop("image_path", None)
                favourite["image_url"] = build_image_url(request, image_path)

            return {
                "message": "User favourites retrieved successfully",
                "user_id": current_user["user_id"],
                "favourites": favourites
            }
        
    except Exception as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = f"Failed to retrieve favourites: {str(e)}"
        )
    

#  Remove product from user favourites
@app.delete("/favourites/{item_code}")
def remove_favourite(item_code: int, 
                     current_user: Annotated[dict, Depends(get_current_user)]):
    # get the user_id from JWT payload
    user_id = current_user["user_id"]

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
                "item_code": deleted_item
            }
        
    except Exception as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = f"Failed to remove favourite"
        ) from e
    

# ---------------------------------------------------
# Single-store basket optimization endpoint
# ---------------------------------------------------
@app.post("/basket-optimizations/single-store")
def optimize_single_store(request: Request,
                          request_data: BasketOptimizationInput,
                          current_user: Annotated[dict, Depends(get_current_user)]):
    (basket_item_codes, item_information, stores) = load_basket_data(request_data)

    for item in item_information.values():
        image_path = item.pop("image_path", None)
        item["image_url"] = build_image_url(request, image_path)

    matrix_result = get_road_distance_matrix(
        request_data.latitude,
        request_data.longitude,
        stores
    )
    road_filtered_stores = filter_stores_by_road_distance(
        stores,
        matrix_result["distance_matrix"],
        matrix_result["store_index_by_code"],
        request_data.radius_km
    )

    if not road_filtered_stores:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Stores were found within the straight-line radius, but none "
                "are within the selected driving-distance radius."
            )
        )

    recommendation = calculate_single_store_recommendation(
        request_data,
        basket_item_codes,
        item_information,
        road_filtered_stores,
        matrix_result["distance_matrix"],
        matrix_result["store_index_by_code"]
    )

    return {
        "basket_summary": {
            "item_count": len(basket_item_codes),
            "radius_km": request_data.radius_km,
            "travel_cost_per_km": request_data.travel_cost_per_km,
            "straight_line_candidate_store_count": len(stores),
            "road_filtered_store_count": len(road_filtered_stores)
        },

        "single-store-recommendation": recommendation
    }


# ---------------------------------------------------
# Multi-store basket optimization endpoint
# ---------------------------------------------------
@app.post("/basket-optimizations/multi-store")
def optimize_multi_store(request: Request,
                         request_data: BasketOptimizationInput,
                         current_user: Annotated[dict, Depends(get_current_user)]):
    (basket_item_codes, item_information, stores) = load_basket_data(request_data)

    for item in item_information.values():
        image_path = item.pop("image_path", None)
        item["image_url"] = build_image_url(request, image_path)

    matrix_result = get_road_distance_matrix(
        request_data.latitude,
        request_data.longitude,
        stores
    )
    road_filtered_stores = filter_stores_by_road_distance(
        stores,
        matrix_result["distance_matrix"],
        matrix_result["store_index_by_code"],
        request_data.radius_km
    )

    if not road_filtered_stores:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Stores were found within the straight-line radius, but none "
                "are within the selected driving-distance radius."
            )
        )

    recommendation = calculate_multi_store_recommendation(
        request_data,
        basket_item_codes,
        item_information,
        road_filtered_stores,
        matrix_result["distance_matrix"],
        matrix_result["store_index_by_code"]
    )

    return {
        "basket_summary": {
            "item_count": len(basket_item_codes),
            "radius_km": request_data.radius_km,
            "travel_cost_per_km": request_data.travel_cost_per_km,
            "straight_line_candidate_store_count": len(stores),
            "road_filtered_store_count": len(road_filtered_stores),
            "evaluated_pair_count": (
                len(road_filtered_stores) * (len(road_filtered_stores) - 1)
            ) // 2
        },
        "multi_store_recommendation": recommendation
    }
    

# Create complaint
@app.post("/complaints")
async def create_complaint(
    current_user: Annotated[dict, Depends(get_current_user)],

    idempotency_key: Annotated[UUID, Form()],
    category: Annotated[str, Form()],
    product_name: Annotated[str, Form()],
    product_price: Annotated[float, Form()],
    loss_amount: Annotated[float, Form()],
    date_issue: Annotated[date, Form()],
    premise_type: Annotated[str, Form()],
    premise_name: Annotated[str, Form()],
    premise_address: Annotated[str, Form()],
    full_name: Annotated[str, Form()],
    nric: Annotated[str, Form()],
    postal_code: Annotated[str | None, Form()] = None,
    phone_no: Annotated[str | None, Form()] = None,
    email: Annotated[EmailStr | None, Form()] = None,
    district: Annotated[str | None, Form()] = None,
    state: Annotated[str | None, Form()] = None,
    description: Annotated[str | None, Form()] = None,
    longitude: Annotated[float | None, Form()] = None,
    latitude: Annotated[float | None, Form()] = None,
    attachments: Annotated[list[UploadFile], File()] = []
):
    request_data = CreateComplaintInput(
        category=category, 
        product_name=product_name, 
        product_price=product_price,
        loss_amount=loss_amount, 
        date_issue=date_issue, 
        full_name=full_name,
        nric=nric,
        phone_no=phone_no, 
        email=email,
        premise_type=premise_type, 
        premise_name=premise_name, 
        premise_address=premise_address,
        postal_code=postal_code, 
        district=district, state=state, 
        description=description,
        longitude=longitude, 
        latitude=latitude,
    )

    user_id = current_user["user_id"]

    if attachments and len(attachments) > 4:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You can upload a maximum of 4 images."
        )

    try:
        with engine.begin() as conn:
            existing_complaint = conn.execute(
                text("""
                    SELECT 
                        user_id,
                        complaint_id,
                        idempotency_key
                    FROM complaints
                    WHERE user_id = :user_id 
                    AND idempotency_key = :idempotency_key
                    LIMIT 1
                """), {
                    "user_id": user_id,
                    "idempotency_key": idempotency_key
                }
            ).mappings().first()

            if existing_complaint:
                return {
                    "message": "Complaint already submitted",
                    "complaint_id": existing_complaint["complaint_id"],
                    "already_submitted": True
                } 

            complaint = conn.execute(
                text("""
                    INSERT INTO complaints (
                        user_id,
                        category,
                        product_name,
                        product_price,
                        loss_amount,
                        date_issue,
                        premise_type,
                        premise_name,
                        full_name,
                        nric,
                        phone_no,
                        email,
                        premise_address,
                        postal_code,
                        district,
                        state,
                        description,
                        longitude,
                        latitude,
                        idempotency_key
                    )
                    VALUES (
                        :user_id,
                        :category,
                        :product_name,
                        :product_price,
                        :loss_amount,
                        :date_issue,
                        :premise_type,
                        :premise_name,
                        :full_name,
                        :nric,
                        :phone_no,
                        :email,
                        :premise_address,
                        :postal_code,
                        :district,
                        :state,
                        :description,
                        :longitude,
                        :latitude,
                        :idempotency_key
                    )
                    RETURNING complaint_id, created_at
                """),{
                    "user_id": user_id,
                    "category": request_data.category,
                    "product_name": request_data.product_name,
                    "product_price": request_data.product_price,
                    "loss_amount": request_data.loss_amount,
                    "date_issue": request_data.date_issue,
                    "premise_type": request_data.premise_type,
                    "premise_name": request_data.premise_name,
                    "full_name": request_data.full_name,
                    "nric": request_data.nric,
                    "phone_no": request_data.phone_no,
                    "email": request_data.email,
                    "premise_address": request_data.premise_address,
                    "postal_code": request_data.postal_code,
                    "district": request_data.district,
                    "state": request_data.state,
                    "description": request_data.description,
                    "longitude": request_data.longitude,
                    "latitude": request_data.latitude,
                    "idempotency_key": idempotency_key
                }
            ).mappings().first()

    except SQLAlchemyError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to create complaint"
        ) from e

    complaint_id = complaint["complaint_id"]

    # Create directory inside complaint_attachments folder. For example, complaint_attachments/13
    complaint_directory = (
        COMPLAINT_ATTACHMENT_DIRECTORY
        / str(complaint_id)
    )

    complaint_directory.mkdir(
        parents=True,
        exist_ok=True
    )

    # saved attachments
    saved_attachments = []

    if attachments:
        for index, attachment in enumerate(attachments, start=1):
            if not attachment.filename:
                continue

            # Check file type
            allowed_type = {
                "image/jpeg",
                "image/png",
                "image/webp"
            }

            if attachment.content_type not in allowed_type:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=(
                        "Only JPG, PNG and WEBP "
                        "images are allowed."
                    )
                )

            file_extension = Path(attachment.filename).suffix.lower()
            file_name = f"image_{index}{file_extension}"
            file_path = complaint_directory / file_name

            try:
                with file_path.open("wb") as buffer:
                    while True:
                        chunk = await attachment.read(
                            1024 * 1024
                        )

                        if not chunk:
                            break

                        buffer.write(chunk)

            except OSError as e:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Unable to save complaint attachment"
                ) from e

            # Relative path saved in database
            relative_path = f"/complaint_attachments/{complaint_id}/{file_name}"
            saved_attachments.append(relative_path)

    # Saved attachment to database
    if saved_attachments:
        try:
            with engine.begin() as conn:
                for file_relative_path in saved_attachments:
                    conn.execute(
                        text("""
                            INSERT INTO complaint_attachments (
                                complaint_id,
                                file_path
                            )
                            VALUES (
                                :complaint_id,
                                :file_path
                            )
                        """), {
                            "complaint_id": complaint_id,
                            "file_path": file_relative_path
                        }
                    )

        except SQLAlchemyError as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Complaint created, but attachments could not be saved."
            ) from e

    return {
        "message": "Complaint submitted successfully",
        "complaint_id": complaint_id,
        "attachment_count": len(saved_attachments),
        "already_submitted": False
    }


# Get the complaints for user
@app.get("/complaints")
async def get_complaints(request: Request, current_user: Annotated[dict, Depends(get_current_user)]):
    user_id = current_user["user_id"]

    try:
        with engine.begin() as conn:
            rows = conn.execute(
                text("""
                    SELECT
                        c.complaint_id,
                        c.category,
                        c.product_name,
                        c.product_price,
                        c.loss_amount,
                        c.date_issue,
                        c.premise_type,
                        c.premise_name,
                        c.full_name,
                        c.nric,
                        c.phone_no,
                        c.email,
                        c.premise_address,
                        c.postal_code,
                        c.district,
                        c.state,
                        c.latitude,
                        c.longitude,
                        c.description,
                        c.created_at,

                        ca.attachment_id,
                        ca.file_path

                    FROM complaints c

                    LEFT JOIN complaint_attachments ca
                        ON c.complaint_id = ca.complaint_id

                    WHERE c.user_id = :user_id

                    ORDER BY c.created_at DESC
                """), {
                    "user_id": user_id
                }
            ).mappings().all()

            complaints = {}

            for row in rows:
                complaint_id = row["complaint_id"]

                if complaint_id not in complaints:
                    complaints[complaint_id] = {
                        "complaint_id": complaint_id,
                        "category": row["category"],
                        "product_name": row["product_name"],
                        "product_price": row["product_price"],
                        "loss_amount": row["loss_amount"],
                        "date_issue": row["date_issue"],

                        "full_name": row["full_name"],
                        "nric": row["nric"],
                        "phone_no": row["phone_no"],
                        "email": row["email"],

                        "premise_type": row["premise_type"],
                        "premise_name": row["premise_name"],
                        "premise_address": row["premise_address"],
                        "postal_code": row["postal_code"],
                        "district": row["district"],
                        "state": row["state"],

                        "latitude": row["latitude"],
                        "longitude": row["longitude"],

                        "description": row["description"],
                        "created_at": row["created_at"],

                        "attachments": []
                    }

                if row["attachment_id"] is not None:
                    file_url = build_image_url(request, row["file_path"])

                    complaints[complaint_id]["attachments"].append({
                        "attachment_id": row["attachment_id"],
                        "file_url": file_url
                    })

            return list(complaints.values())

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to retrieve complaints"
        ) from e


# Delete complaints
@app.delete("/complaints")
def delete_complaints(request_data: DeleteComplaintInput,
                      current_user: Annotated[dict, Depends(get_current_user)]):
    user_id = current_user["user_id"]
    complaints_ids = list(set(request_data.complaint_ids))

    try:
        with engine.begin() as conn:
            results = conn.execute(
                text("""
                    SELECT complaint_id
                    FROM complaints
                    WHERE complaint_id = ANY(:complaint_ids)
                    AND user_id = :user_id
                """), {
                    "complaint_ids": complaints_ids,
                    "user_id": user_id
                }
            )

            existing_ids = [row[0] for row in results]

            if not existing_ids:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="No matching complaints found"
                )

            conn.execute(
                text("""
                    DELETE FROM complaints
                    WHERE complaint_id = ANY(:complaint_ids)
                    AND user_id = :user_id
                """), {
                    "complaint_ids": complaints_ids,
                    "user_id": user_id
                }
            )

            # Delete the local attachments (images)
        for complaint_id in existing_ids:
            complaint_directory = COMPLAINT_ATTACHMENT_DIRECTORY / str(complaint_id)

            if complaint_directory.exists():
                shutil.rmtree(complaint_directory)

        return {
            "message": "Complaints deleted successfully",
            "deleted_complaint_ids": existing_ids
        }

    except HTTPException:
        raise

    except SQLAlchemyError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to delete complaints"
        ) from e


# print(
#     app.openapi()["components"]["schemas"]["Body_create_complaint_complaints_post"]
# )

