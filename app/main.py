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
def get_product_prices(item_code: int):
    with engine.connect() as conn:
        result = conn.execute(text("""
            SELECT
                i.item_code,
                i.item_name,
                i.unit,
                p.premise_code,
                p.premise_name,
                p.address,
                p.state,
                p.district,
                pr.price,
                pr.price_date
            FROM price_records pr
            JOIN items i
                ON pr.item_code = i.item_code
            JOIN premises p
                ON pr.premise_code = p.premise_code
            WHERE pr.item_code = :item_code
            ORDER BY pr.price ASC
            LIMIT 50;
        """), {
            "item_code": item_code
        })

        return [dict(row._mapping) for row in result]