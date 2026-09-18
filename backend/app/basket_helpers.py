# Helper functions for basket optimization related logic.
from fastapi import HTTPException, status
from .schemas import BasketOptimizationInput, BasketItemInput
from sqlalchemy import text, bindparam
from sqlalchemy.exc import SQLAlchemyError
import traceback
from itertools import combinations
from .database import engine


def get_unique_item_codes(basket_items: list[BasketItemInput]) -> list[int]:
    """Extract unique item codes while preserving order."""
    return list(dict.fromkeys(item.item_code for item in basket_items))


# load the all the item code in user's basket, item information, and store from database
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
                        unit,
                        image_path
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
                        AND pr.price_date IS NOT NULL
                        AND pr.price_date >= CURRENT_DATE - INTERVAL '30 days'

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
            detail = f"A database error occurred while retrieving basket optimisation data"
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
            "unit": row["unit"],
            "image_path": row["image_path"]
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


# build the information of missing item in user's basket
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
                "unit": item_information[item_code]["unit"],
                "image_url": item_information[item_code]["image_url"]
            })

    return missing_items


# build the selected store information 
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
        "straight_line_distance_from_user_km": round(
            store["distance_from_user_km"], 3
        ),
        "distance_from_user_km": round(
            store["road_distance_from_user_km"], 3
        ),
        "road_distance_from_user_km": round(
            store["road_distance_from_user_km"], 3
        ),
        "items": selected_items
    }
    

# calculate the optimized result for the selected items in single-store
def calculate_single_store_recommendation(request_data: BasketOptimizationInput,  # entire passed data from user side
                                          basket_item_codes: list[int],  # items passed from user side
                                          item_information: dict[int, dict],   # informations of items that passed from user side
                                          stores: list[dict],
                                          distance_matrix: list[list[float | None]],
                                          store_index_by_code: dict[int, int]) -> dict:   # Each nearby store holds the available item prices
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
                "image_url": item_information[item_code]["image_url"],
                "price": round(price_data["price"], 2),
                "price_date": price_data["price_date"]
            })

        # count how any available items
        available_item_count = len(available_item_codes)

        missing_items = build_missing_items(basket_item_codes, item_information, available_item_codes)


        # Calculate User -> Store -> User using directional road distances.
        store_index = store_index_by_code[store["premise_code"]]
        outbound_distance_metres = distance_matrix[0][store_index]
        return_distance_metres = distance_matrix[store_index][0]

        if outbound_distance_metres is None or return_distance_metres is None:
            continue

        route_distance_km = (
            outbound_distance_metres + return_distance_metres
        ) / 1000
        travel_cost = route_distance_km * request_data.travel_cost_per_km

        # total product cost plus travel cost
        total_cost = product_cost + travel_cost

        result_status = "complete" if available_item_count == total_item_count else "partial"

        # saved each single-store recommendations
        single_store_results.append({
            "status": result_status,
            "recommendation_type": "single-store",
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
    
    # Ranking (minimum)
    # 1. first compare available items in the store
    # 2. if tie, then compare the total cost among these store
    # 3. if tie, then compare the route distance 
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
        

def assign_items_to_store_pair(basket_items_codes: list[int],
                               store_1: dict,
                               store_2: dict) -> dict[int, int] | None:
    # Assign each available item to one of the two stores.
    # When both stores contain the item, the cheaper store is selected.
    # The method also ensures that both stores provide at least one basket item.
    store_1_code = store_1["premise_code"]
    store_2_code = store_2["premise_code"]

    store_1_prices = store_1["prices"]
    store_2_prices = store_2["prices"]

    assignments = {}

    for item_code in basket_items_codes:
        store_1_price_data = store_1_prices.get(item_code)
        store_2_price_data = store_2_prices.get(item_code)

        # Item is not available in either store
        if store_1_price_data is None and store_2_price_data is None:
            continue

        # Item is only available in store 1
        if store_1_price_data is not None and store_2_price_data is None:
            assignments[item_code] = store_1_code
        
        # Item is only available in store 2
        elif store_2_price_data is not None and store_1_price_data is None:
            assignments[item_code] = store_2_code

        # Item available in both stores
        elif store_1_price_data["price"] <= store_2_price_data["price"]:
            assignments[item_code] = store_1_code

        else:
            assignments[item_code] = store_2_code

    # Neither store provides any selected item.
    if not assignments:
        return None

    # Every item was assigned to only one store.
    # Therefore, this is not a genuine multi-store result.
    if len(set(assignments.values())) < 2:
        return None
    
    return assignments


# calculate the optimized result for the selected items in multi-store
def calculate_multi_store_recommendation(request_data: BasketOptimizationInput,
                                         basket_item_codes: list[int],
                                         item_information: dict[int, dict],
                                         stores: list[dict],
                                         distance_matrix: list[list[float | None]],
                                         store_index_by_code: dict[int, int]) -> dict:
    total_item_count = len(basket_item_codes)

    if len(stores) < 2:
        return {
            "status": "unavailable",
            "recommendation_type": "multi_store",
            "message": "At least 2 nearby stores are required for multi-store basket optimization"
        }
    
    if total_item_count < 2:
        return {
            "status": "unavailable",
            "recommendation_type": "multi_store",
            "message": "At least 2 different items are required for multi-store basket optimization"
        }
    
    multi_store_results = []

    for store_1, store_2 in combinations(stores, 2):
        assignments = assign_items_to_store_pair(basket_item_codes, store_1, store_2)

        if assignments is None:
            continue

        store_1_code = store_1["premise_code"]
        store_2_code = store_2["premise_code"]

        items_by_store = {
            store_1_code: [],
            store_2_code: []
        }

        store_subtotals = {
            store_1_code: 0.0,
            store_2_code: 0.0
        }

        product_cost = 0.0

        for item_code, selected_store_code in assignments.items():
            if selected_store_code == store_1_code:
                selected_store = store_1
            else:
                selected_store = store_2

            price_data = selected_store["prices"][item_code]   # {}

            item_price = price_data["price"]

            # sub-total for each store
            store_subtotals[selected_store_code] += item_price

            # total items price
            product_cost += item_price

            items_by_store[selected_store_code].append({
                "item_code": item_code,
                "item_name": item_information[item_code]["item_name"],
                "unit": item_information[item_code]["unit"],
                "image_url": item_information[item_code]["image_url"],
                "price": round(item_price, 2),
                "price_date": price_data["price_date"]
            })

        available_item_codes = set(assignments.keys())

        available_item_count = len(available_item_codes)

        missing_items = build_missing_items(basket_item_codes, item_information, available_item_codes)

        store_1_index = store_index_by_code[store_1_code]
        store_2_index = store_index_by_code[store_2_code]

        # Road distances are directional, so evaluate both visit orders.
        route_options = []

        route_1_distances = (
            distance_matrix[0][store_1_index],
            distance_matrix[store_1_index][store_2_index],
            distance_matrix[store_2_index][0]
        )
        if all(distance is not None for distance in route_1_distances):
            route_options.append((
                sum(route_1_distances) / 1000,
                [store_1_code, store_2_code]
            ))

        route_2_distances = (
            distance_matrix[0][store_2_index],
            distance_matrix[store_2_index][store_1_index],
            distance_matrix[store_1_index][0]
        )
        if all(distance is not None for distance in route_2_distances):
            route_options.append((
                sum(route_2_distances) / 1000,
                [store_2_code, store_1_code]
            ))

        if not route_options:
            continue

        route_distance_km, route_order = min(
            route_options,
            key=lambda route: route[0]
        )

        stores_by_code = {
            store_1_code: store_1,
            store_2_code: store_2
        }

        recommended_stores = []
        previous_matrix_index = 0

        for premise_code in route_order:
            store = stores_by_code[premise_code]
            current_matrix_index = store_index_by_code[premise_code]

            # get the store information
            store_information = build_store_information(store, items_by_store[premise_code])

            # For the first store this is User -> Store 1. For the second
            # store this is Store 1 -> Store 2.
            route_leg_distance_metres = distance_matrix[previous_matrix_index][current_matrix_index]
            store_information["distance_from_previous_stop_km"] = round(
                route_leg_distance_metres / 1000,
                3
            )

            # append a new entry for subtotal (multi-store only)
            store_information["subtotal"] = round(store_subtotals[premise_code], 2)

            recommended_stores.append(store_information)
            previous_matrix_index = current_matrix_index

        travel_cost = route_distance_km * request_data.travel_cost_per_km

        total_cost = product_cost + travel_cost

        result_status = "complete" if available_item_count == total_item_count else "partial"

        multi_store_results.append({
            "status": result_status,
            "recommendation_type": "multi_store",
            "available_item_count": available_item_count,
            "total_item_count": total_item_count,
            "coverage_percentage": round((available_item_count / total_item_count) * 100, 2),
            "missing_items": missing_items,
            "route_order": route_order,
            "stores": recommended_stores,
            "product_cost": round(product_cost, 2),
            # "store_to_store_distance_km": round(store_to_store_distance_km, 3),
            "estimated_route_distance_km": round(route_distance_km, 3),
            "travel_cost": round(travel_cost, 2),
            "total_cost": total_cost
        })

    if not multi_store_results:
        return {
            "status": "unavailable",
            "recommendation_type": "multi-store",
            "message": "No valid two_premise combination could be created for the selected items"
        }
    
    best_multi_store = min(
        multi_store_results,
        key = lambda result: (
            -result["available_item_count"],
            result["total_cost"],
            result["estimated_route_distance_km"]
        )
    )

    return best_multi_store
