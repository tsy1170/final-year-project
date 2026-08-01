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
                "osrm_response": error.response.text
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


