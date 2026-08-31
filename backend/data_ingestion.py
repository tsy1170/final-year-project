import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
import os
from datetime import datetime

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

current_month_str = datetime.now().strftime("%Y-%m")

ITEM_LOOKUP_URL = "https://storage.data.gov.my/pricecatcher/lookup_item.parquet"
PREMISE_LOOKUP_URL = "https://storage.data.gov.my/pricecatcher/lookup_premise.parquet"
PRICE_URL = f"https://storage.data.gov.my/pricecatcher/pricecatcher_{current_month_str}.parquet"

engine = create_engine(DATABASE_URL)


def load_items():
    print("Reading item lookup...")

    df = pd.read_parquet(ITEM_LOOKUP_URL)

    print("Item columns:", df.columns.tolist())

    df = df.rename(columns={
    "item": "item_name"
    })

    df = df[[
        "item_code",
        "item_name",
        "unit",
        "item_group",
        "item_category"
    ]]

    # Remove invalid rows
    df = df.dropna(subset=["item_code", "item_name"])

    # Remove placeholder item_code if exists
    df = df[df["item_code"] != -1]

    df.to_sql("_stg_items", engine, if_exists="replace", index=False)

    with engine.begin() as conn:
        conn.execute(text("""
            INSERT INTO items (
                item_code,
                item_name,
                unit,
                item_group,
                item_category
            )
            SELECT
                item_code,
                item_name,
                unit,
                item_group,
                item_category
            FROM _stg_items
            ON CONFLICT (item_code)
            DO UPDATE SET
                item_name = EXCLUDED.item_name,
                unit = EXCLUDED.unit,
                item_group = EXCLUDED.item_group,
                item_category = EXCLUDED.item_category;
        """))

        conn.execute(text("DROP TABLE _stg_items;"))

    print("Items loaded successfully.")


def load_premises():
    print("Reading premise lookup...")

    df = pd.read_parquet(PREMISE_LOOKUP_URL)

    print("Premise columns:", df.columns.tolist())

    df = df.rename(columns={
        "premise": "premise_name"
    })

    df = df[[
        "premise_code",
        "premise_name",
        "address",
        "premise_type",
        "state",
        "district"
    ]]

    # Remove invalid rows
    df = df.dropna(subset=["premise_code", "premise_name"])

    # Remove placeholder premise_code if exists
    df = df[df["premise_code"] != -1]

    df.to_sql("_stg_premises", engine, if_exists="replace", index=False)

    with engine.begin() as conn:
        conn.execute(text("""
            INSERT INTO premises (
                premise_code,
                premise_name,
                address,
                premise_type,
                state,
                district
            )
            SELECT
                premise_code,
                premise_name,
                address,
                premise_type,
                state,
                district
            FROM _stg_premises
            ON CONFLICT (premise_code)
            DO UPDATE SET
                premise_name = EXCLUDED.premise_name,
                address = EXCLUDED.address,
                premise_type = EXCLUDED.premise_type,
                state = EXCLUDED.state,
                district = EXCLUDED.district;
        """))

        conn.execute(text("DROP TABLE _stg_premises;"))

    print("Premises loaded successfully.")


def load_price_records():
    print("Reading PriceCatcher price records...")

    df = pd.read_parquet(PRICE_URL)

    df = df.rename(columns={
        "date": "price_date"
    })

    df["price_date"] = pd.to_datetime(df["price_date"]).dt.date
    df["premise_code"] = df["premise_code"].astype(int)
    df["item_code"] = df["item_code"].astype(int)
    df["price"] = pd.to_numeric(df["price"], errors="coerce")

    df = df.dropna(subset=[
        "price_date",
        "premise_code",
        "item_code",
        "price"
    ])

    df = df.drop_duplicates(subset=[
        "price_date", 
        "premise_code", 
        "item_code"
    ])

    df = df[[
        "price_date",
        "premise_code",
        "item_code",
        "price"
    ]]

    df.to_sql("_stg_price_records", engine, if_exists="replace", index=False)

    with engine.begin() as conn:
        skipped_count = conn.execute(text("""
            SELECT COUNT(*)
            FROM _stg_price_records s
            LEFT JOIN items i ON i.item_code = s.item_code
            LEFT JOIN premises p ON p.premise_code = s.premise_code
            WHERE i.item_code IS NULL OR p.premise_code IS NULL;
        """ )).scalar()

        conn.execute(text("""
            INSERT INTO price_records (
                price_date,
                premise_code,
                item_code,
                price
            )
            SELECT
                s.price_date,
                s.premise_code,
                s.item_code,
                s.price
            FROM _stg_price_records s
            JOIN items i ON i.item_code = s.item_code
            JOIN premises p ON p.premise_code = s.premise_code
            ON CONFLICT (price_date, premise_code, item_code)
            DO NOTHING;
        """))

        conn.execute(text("DROP TABLE _stg_price_records;"))

    if skipped_count:
        print(f"Skipped {skipped_count} price rows with missing item/premise references.")

    print("Price records loaded successfully.")


def main():
    load_items()
    load_premises()
    load_price_records()
    print("Ingestion completed.")


if __name__ == "__main__":
    main()