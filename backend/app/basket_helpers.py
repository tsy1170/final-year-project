# Helper functions for basket optimization related logic.
from fastapi import HTTPException, status
from .schemas import BasketOptimizationInput, BasketItemInput
from sqlalchemy import text, bindparam
from sqlalchemy.exc import SQLAlchemyError
import traceback
from .database import engine


def get_unique_item_codes(basket_items: list[BasketItemInput]) -> list[int]:
    """Extract unique item codes while preserving order."""
    return list(dict.fromkeys(item.item_code for item in basket_items))


def load_basket_data(request_data: BasketOptimizationInput) -> tuple[list[int], dict[int, dict], list[dict]]:
    # Prepare basket input for the optimization workflow.
    basket_item_codes = get_unique_item_codes(request_data.basket_items)  # the list of codes that user sent
    
    try:
        with engine.begin() as conn:
            # get the selected items information
            item_rows = conn.execute(
                text("""
                    SELECT 
                        item_code,
                        item_name, 
                        unit
                    FROM items 
                    WHERE item_code IN :item_codes
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
                        "invalid_items_code": invalid_items_code  # list
                    }
                )
            
            # get the latest price records from premsie within defined user geographical radius
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
                                    ST_MakePoint(
                                        :user_longitude,
                                        :user_latitude
                                    ),
                                    4326
                                )::geography
                            ) / 1000.0 AS distance_from_user_km

                        FROM premises p

                        WHERE p.location IS NOT NULL
                        AND p.latitude IS NOT NULL
                        AND p.longitude IS NOT NULL

                        AND ST_DWithin(
                                p.location,
                                ST_SetSRID(
                                    ST_MakePoint(
                                        :user_longitude,
                                        :user_latitude
                                    ),
                                    4326
                                )::geography,
                                :radius_metres
                        )
                    ),

                    latest_prices AS (
                        SELECT DISTINCT ON (
                            pr.premise_code,
                            pr.item_code
                        )
                            pr.premise_code,
                            pr.item_code,
                            pr.price,
                            pr.price_date

                        FROM price_records pr

                        JOIN nearby_premises np
                            ON np.premise_code = pr.premise_code

                        WHERE pr.item_code IN :item_codes

                        ORDER BY
                            pr.premise_code,
                            pr.item_code,
                            pr.price_date DESC
                    )

                    SELECT
                        np.premise_code,
                        np.premise_name,
                        np.address,
                        np.district,
                        np.state,
                        np.latitude,
                        np.longitude,
                        np.distance_from_user_km,

                        lp.item_code,
                        lp.price,
                        lp.price_date

                    FROM nearby_premises np

                    JOIN latest_prices lp
                        ON lp.premise_code = np.premise_code

                    ORDER BY
                        np.distance_from_user_km,
                        np.premise_code,
                        lp.item_code
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
        traceback.print_exc()

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


def build_missing_items(basket_item_codes: list[int],
                        item_information: dict[int, dict],
                        available_item_codes: set[int]) -> list[dict]:
    # Build a list of basket items that are not available in the selected store or store pair.
    missing_items = []

    for item_code in basket_item_codes:
        if item_code not in available_item_codes:
            missing_items.append({
                "item_code": item_code,
                "item_name": item_information[item_code]["item_name"],
                "unit": item_information[item_code]["unit"]
            })

    return missing_items


def build_store_information(store: dict,
                            selected_items: list[dict]) -> dict:
    # Create the store response 
    return {
        "premise_code": store["premise_code"],
        "premise_name": store["premise_name"],
        "address": store["address"],
        "district": store["district"],
        "state": store["state"],
        "latitude": store["latitude"],
        "longitude": store["longitude"],
        "distance_from_user_km": round(store["distance_from_user_km"], 3),
        "items": selected_items
    }
    


def calculate_single_store_recommendation(request_data: BasketOptimizationInput,  # entire passed data from user side
                                          basket_item_codes: list[int],  # items passed from user side
                                          item_information: dict[int, dict],   # informations of items that passed from user side
                                          stores: list[dict]) -> dict:   # Each store holds the available item prices
    total_item_count = len(basket_item_codes)

    single_store_results = []

    # loop through all store one-by-one
    for store in stores:
        available_item_codes = {
            item_code for item_code in basket_item_codes
            if item_code in store["prices"]
        }

        # if the store does not contains any user's request items, skip the store
        if not available_item_codes:
            continue

        selected_items = []
        product_cost = 0.0

        # goes through the basket items one by one,
        # checks whether each item exists in the current store’s price map
        for item_code in basket_item_codes:
            price_data = store["prices"].get(item_code)

            # if item not appear in user's request item, skip the item
            if price_data is None:
                continue

            product_cost += price_data["price"]

            # append the matching item details
            selected_items.append({
                "item_code": item_code,
                "item_name": item_information[item_code]["item_name"],
                "unit": item_information[item_code]["unit"],
                "price": round(price_data["price"], 2),
                "price_date": price_data["price_date"]
            })

        # count how any available items
        available_item_count = len(available_item_codes)

        missing_items = build_missing_items(basket_item_codes, item_information, available_item_codes)


        # Calculate route cost
        route_distance_km = store["distance_from_user_km"] * 2
        travel_cost = route_distance_km * request_data.travel_cost_per_km

        # total product cost plus travel cost
        total_cost = product_cost + travel_cost

        result_status = "complete" if available_item_codes == total_item_count else "partial"

        # saved each single-store recommendations
        single_store_results.append({
            "status": result_status,
            "recommended_type": "single-store",
            "available_item_count": available_item_count,
            "total_item_count": total_item_count,
            "coverage_percentage": round((available_item_count/total_item_count) * 100, 2),
            "missing_items": missing_items,
            "store": build_store_information(store, selected_items),
            "product_cost": product_cost,
            "estimated_route_distance_km": route_distance_km,
            "travel_cost": travel_cost,
            "total_cost": total_cost
        })

    # handle empty result
    if not single_store_results:
        return {
            "status": "unavailable",
            "recommendation_type": "single-store",
            "message": "No nearby premise contains any selected items"
        }
    
    # Ranking
    best_single_store = min(
        single_store_results,
        key = lambda result: (
            -result["available_item_count"],
            result["total_cost"],
            result["estimated_route_distance_km"]
        )
    )

    # return result
    return best_single_store
        

         
            
    

