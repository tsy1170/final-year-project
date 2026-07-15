# Helper functions for basket optimization related logic.
from fastapi import HTTPException, status
from .schemas import BasketOptimizationInput, BasketItemInput
from sqlalchemy import text, bindparam
from sqlalchemy.exc import SQLAlchemyError
from .database import engine


def get_unique_item_codes(basket_items: list[BasketItemInput]) -> list[int]:
    """Extract unique item codes while preserving order."""
    return list(dict.fromkeys(item.item_code for item in basket_items))


def load_basket_data(request_data: BasketOptimizationInput) -> tuple[list[int], dict[int, dict], list[dict]]:
    """Prepare basket input for the optimization workflow."""
    basket_item_codes = get_unique_item_codes(request_data.basket_items)  # the list of codes the user sent
    
    try:
        with engine.begin() as conn:
            item_rows = conn.execute(
                text("""
                    SELECT 
                        item_code,
                        item_name, 
                        unit
                    FROM items IN :item_codes
                """).bindparams(
                        bindparam(
                            "item_codes",
                            expanding = True
                        )      
                    ), {
                        "item_codes": basket_item_codes
                    }
            ).mappings().all()


            # the set of item codes that actually exist in the items table
            existing_item_codes = {      
                row["item_code"] for row in item_rows
            }

            invalid_items_code = sorted(
                set(basket_item_codes) - existing_item_codes
            )

            if invalid_items_code:
                raise HTTPException(
                    status_code = status.HTTP_404_NOT_FOUND,
                    detail = {
                        "message": (
                            "Some submitted item codes do not exist in items table"
                        ),
                        "invalid_items_code": invalid_items_code
                    }
                )
            
            price_rows = conn.execute(
                text("""
                    WITH nearby_premises AS (
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
                                ST_SetSRID(
                                    ST_MakePoint(:user_longitude, :user_latitude), 4326
                                )::geography
                            ) / 1000.0 AS distance_from_user_km
                    )
                    FROM premises p
                    WHERE p.location IS NOT NULL
                    AND p.longitude IS NOT NULL
                    AND p.latitude IS NOT NULL

                    AND ST_DWithin(
                        p.location,
                        ST_SetSRID(
                            ST_MakePoint(:user_longitude, :user_latitude), 4326
                        )::geography,
                        :radius_metres
                    ),
                     
                    latest_price AS (
                        SELECT DISTINCT ON (premise_code, item_code)
                            pr.premise_code,
                            pr.item_code,
                            pr.price,
                            pr.price_date
                        FROM price_records pr
                        JOIN nearby_premises np
                            ON np.premise_code = pr.premise_code
                        WHERE pr.item_code IN :item_codes
                        
                        ORDER BY pr.premise_code, pr.item_code, pr.price_date DESC
                    )
                     
                    SELECT 
                        np.premise_code,
                        np.premise_name,
                        np.address,
                        np.state,  
                        np.latitude,
                        np.longitude,
                        np.distance_from_user_km,
                     
                        lp.item_code,
                        lp.price,
                        lp.price_date
                    FROM nearby_premises np
                    JOIN latest_price lp
                        ON lp.premise_code = np.premise_code
                    ORDER BY np.distance_from_user_km, np.premise_code, lp.item_code
                """).bindparams(
                    bindparam(
                        "item_codes",
                        expanding = True
                    )
                ), {
                    "user_longitude": (request_data.longitude),
                    "user_latitude": (request_data.latitude),
                    "radius_metres": (request_data.radius_km * 1000),
                    "item_codes": basket_item_codes
                }
            ).mappings().all()

    except SQLAlchemyError as e:
        raise HTTPException(
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail = f"A database error occurred while retrieving basket optimisation data: {str(e)}"
        )
    
    if not price_rows:
        raise HTTPException(
            status_code = status.HTTP_404_NOT_FOUND,
            detail = "No nearby premises contain any of the selected basket items."
        )
    
    # all selected items information
    item_information = {
        row["item_code"]: {
            "item_name": row["item_name"],
            "unit": row["unit"]
        }
        for row in item_rows
    }

    # Available stores
    stores: dict[int, dict] = {}

    for row in price_rows:
        premise_code = row["premise_code"]

        if premise_code not in stores:
            stores[premise_code] = {
                "premise_code": premise_code,
                "premise_name": row["premise_name"],
                "address": row["address"],
                "district": row["district"],
                "state": row["state"],
                "latitude": float(row["latitude"]),
                "longitude": float(row["longitude"]),

                "distance_from_user_km": float(
                    row["distance_from_user_km"]
                ),
                "prices": {}
            }

        item_code = row["item_code"]

        stores[premise_code]["prices"][item_code] = {
            "price": float(row["price"]),
            "price_date": row["price_date"]
        }

    return (
        basket_item_codes,
        item_information,
        list(stores.values())
    )

    

