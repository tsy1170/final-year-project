from fastapi import FastAPI, Query, Request, HTTPException
from fastapi.staticfiles import StaticFiles
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
from pathlib import Path
import os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)

app = FastAPI()

BASE_DIR = Path(__file__).resolve().parent.parent

IMAGE_DIRECTORY = BASE_DIR / "product_images" 
app.mount("/product_images", StaticFiles(directory=IMAGE_DIRECTORY), name="product_images")

@app.get("/")
def root():
    return {
        "message": "PriceCatcher backend is running"
    }


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
