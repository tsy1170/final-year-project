import os
import httpx
from dotenv import load_dotenv
from fastapi import HTTPException, status

load_dotenv()

OSRM_BASE_URL = os.getenv(
    "OSRM_BASE_URL",
    "https://router.project-osrm.org"
).rstrip("/")

OSRM_PROFILE = os.getenv(
    "OSRM_PROFILE",
    "driving"
)

OSRM_TIMEOUT_SECONDS = float(
    os.getenv("OSRM_TIMEOUT_SECONDS", "20")
)


def get_road_distance(user_latitude: float,
                      user_longitude: float,
                      stores: list[dict]) -> list[dict]:
    # Calculate road-network distances from one user location
    # to multiple stores with the OSRM Table service.

    # Each store dictionary must contain:
    # - latitude
    # - longitude

    if not stores:
        return []

    # OSRM coordinate order is longitude, latitude.
    coordinates = [
        f"{user_longitude},{user_latitude}"
    ]

    for store in stores:
        coordinates.append(
            f"{store['longitude']},{store['latitude']}"
        )

    coordinate_string = ";".join(coordinates)

    # Coordinate index 0 is the user.
    # Coordinate indexes 1 onwards are stores.
    destination_indexes = ";".join(
        str(index)
        for index in range(1, len(coordinates))
    )

    url = (
        f"{OSRM_BASE_URL}/table/v1/"
        f"{OSRM_PROFILE}/{coordinate_string}"
    )

    params = {
        "sources": "0",
        "destinations": destination_indexes,
        "annotations": "duration,distance"
    }

    headers = {
        "User-Agent": (
            "IntelligentDailyNecessitiesPriceOptimisationSystem/1.0"
        )
    }

    try:
        with httpx.Client(timeout = OSRM_TIMEOUT_SECONDS) as client:
            response = client.get(
                url,
                params=params,
                headers=headers
            )

            response.raise_for_status()
            response_data = response.json()

    except httpx.TimeoutException as error:
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail=(
                "OSRM took too long to calculate road distances."
            )
        ) 

    except httpx.HTTPStatusError as error:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={
                "message": "OSRM returned an unsuccessful response.",
                "osrm_status_code": error.response.status_code,
            }
        )

    except httpx.RequestError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Unable to connect to the OSRM server."
        )

    except ValueError as error:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="OSRM returned an invalid JSON response."
        )

    if response_data.get("code") != "Ok":
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={
                "message": "OSRM could not calculate road distances.",
                "osrm_code": response_data.get("code"),
                "osrm_message": response_data.get("message")
            }
        )

    distance_matrix = response_data.get("distances")
    duration_matrix = response_data.get("durations")

    if not distance_matrix or not duration_matrix:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=(
                "OSRM did not return the expected distance "
                "and duration matrices."
            )
        )

    user_to_store_distances = distance_matrix[0]     # Single source (user) to multiple destinations (stores)  [[distance1, distance2, ...]]
    user_to_store_durations = duration_matrix[0]     # Same as distances

    stores_with_road_distance = []

    for index, store in enumerate(stores):
        distance_metres = user_to_store_distances[index]
        duration_seconds = user_to_store_durations[index]

        # OSRM can return null when a route cannot be found.
        if distance_metres is None or duration_seconds is None:
            continue

        store_result = store.copy()

        store_result["road_distance_km"] = float(distance_metres) / 1000

        store_result["driving_duration_minutes"] = float(duration_seconds) / 60

        stores_with_road_distance.append(
            store_result
        )

    return stores_with_road_distance


def get_road_distance_matrix(user_latitude: float,
                             user_longitude: float,
                             stores: list[dict]) -> dict:
    """Return an all-to-all OSRM matrix for the user and nearby stores.

    Matrix index 0 represents the user. Store indexes start at 1 and can be
    retrieved through ``store_index_by_code``. Distances are returned in
    metres and durations in seconds, matching the OSRM Table API response.
    """
    if not stores:
        return {
            "distance_matrix": [[0.0]],
            "duration_matrix": [[0.0]],
            "store_index_by_code": {}
        }

    # OSRM requires coordinates in longitude,latitude order.
    coordinates = [
        f"{user_longitude},{user_latitude}"
    ]

    store_index_by_code = {}

    for matrix_index, store in enumerate(stores, start=1):
        store_index_by_code[store["premise_code"]] = matrix_index
        coordinates.append(
            f"{store['longitude']},{store['latitude']}"
        )

    coordinate_string = ";".join(coordinates)

    url = (
        f"{OSRM_BASE_URL}/table/v1/"
        f"{OSRM_PROFILE}/{coordinate_string}"
    )

    # Omitting sources and destinations requests the complete matrix.
    params = {
        "annotations": "duration,distance"
    }

    headers = {
        "User-Agent": (
            "IntelligentDailyNecessitiesPriceOptimisationSystem/1.0"
        )
    }

    try:
        with httpx.Client(timeout=OSRM_TIMEOUT_SECONDS) as client:
            response = client.get(
                url,
                params = params,
                headers = headers
            )

            response.raise_for_status()
            response_data = response.json()

    except httpx.TimeoutException:
        raise HTTPException(
            status_code = status.HTTP_504_GATEWAY_TIMEOUT,
            detail = "OSRM took too long to calculate the road-distance matrix."
        )

    except httpx.HTTPStatusError as error:
        raise HTTPException(
            status_code = status.HTTP_502_BAD_GATEWAY,
            detail = {
                "message": "OSRM returned an unsuccessful response.",
                "osrm_status_code": error.response.status_code
            }
        )

    except httpx.RequestError:
        raise HTTPException(
            status_code = status.HTTP_503_SERVICE_UNAVAILABLE,
            detail = "Unable to connect to the OSRM server."
        )

    except ValueError:
        raise HTTPException(
            status_code = status.HTTP_502_BAD_GATEWAY,
            detail = "OSRM returned an invalid JSON response."
        )

    if response_data.get("code") != "Ok":
        raise HTTPException(
            status_code = status.HTTP_502_BAD_GATEWAY,
            detail = {
                "message": "OSRM could not calculate the road-distance matrix.",
                "osrm_code": response_data.get("code"),
                "osrm_message": response_data.get("message")
            }
        )

    distance_matrix = response_data.get("distances")
    duration_matrix = response_data.get("durations")
    expected_size = len(coordinates)

    def is_valid_square_matrix(matrix: object) -> bool:
        return (
            isinstance(matrix, list)
            and len(matrix) == expected_size
            and all(
                isinstance(row, list) and len(row) == expected_size
                for row in matrix
            )
        )

    if (
        not is_valid_square_matrix(distance_matrix)
        or not is_valid_square_matrix(duration_matrix)
    ):
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=(
                "OSRM did not return the expected square distance "
                "and duration matrices."
            )
        )

    return {
        "distance_matrix": distance_matrix,  
        "duration_matrix": duration_matrix,
        "store_index_by_code": store_index_by_code
    }


def filter_stores_by_road_distance(
    stores: list[dict],
    distance_matrix: list[list[float | None]],
    store_index_by_code: dict[int, int],
    maximum_distance_km: float
) -> list[dict]:
    maximum_distance_metres = maximum_distance_km * 1000
    eligible_stores = []

    for store in stores:
        premise_code = store["premise_code"]
        matrix_index = store_index_by_code[premise_code]

        # Matrix index 0 represents the user.
        outbound_distance_metres = distance_matrix[0][matrix_index]
        return_distance_metres = distance_matrix[matrix_index][0]

        # A valid round trip must be possible.
        if (
            outbound_distance_metres is None
            or return_distance_metres is None
        ):
            continue

        # Apply the 10 km limit to User -> Store.
        if outbound_distance_metres > maximum_distance_metres:
            continue

        store_result = store.copy()
        store_result["road_distance_from_user_km"] = round(
            outbound_distance_metres / 1000,
            3
        )
        store_result["road_distance_to_user_km"] = round(
            return_distance_metres / 1000,
            3
        )

        eligible_stores.append(store_result)

    return eligible_stores