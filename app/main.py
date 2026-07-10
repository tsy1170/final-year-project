from fastapi import FastAPI, Query
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)

app = FastAPI()


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