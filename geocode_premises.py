import os
import time
import requests
from dotenv import load_dotenv
from sqlalchemy import create_engine, text


load_dotenv()

GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")
DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)


def build_full_address(premise_name, address, district, state):
    # Build a clean search address.
    # Empty values will be skipped automatically.
    parts = [
        address,
        district,
        state,
        "Malaysia"
    ]

    return ", ".join(
        str(part).strip()
        for part in parts
        if part and str(part).strip()
    )


def geocode_address(full_address):
    """
    Send address to Google Geocoding API.
    Return latitude and longitude if Google finds the location.
    """
    url = "https://maps.googleapis.com/maps/api/geocode/json"

    params = {
        "address": full_address,
        "region": "my",
        "key": GOOGLE_MAPS_API_KEY
    }

    response = requests.get(url, params=params, timeout=20)
    data = response.json()

    status = data.get("status")

    if status == "OK" and data.get("results"):
        result = data["results"][0]
        location = result["geometry"]["location"]

        return {
            "status": "FOUND",
            "latitude": location["lat"],
            "longitude": location["lng"]
        }

    return {
        "status": status or "FAILED",
        "latitude": None,
        "longitude": None
    }


def main():
    if not GOOGLE_MAPS_API_KEY:
        raise ValueError("GOOGLE_MAPS_API_KEY is missing in .env file")

    with engine.connect() as conn:
        result = conn.execute(text("""
            SELECT premise_code, premise_name, address, district, state
            FROM premises
            WHERE latitude IS NULL
               OR longitude IS NULL
        """))

        premises = result.fetchall()

    print(f"Total premises to geocode: {len(premises)}")

    for index, row in enumerate(premises, start=1):
        premise_code = row.premise_code
        address = row.address
        district = row.district
        state = row.state

        full_address = build_full_address(
            address,
            district,
            state
        )

        print(f"\n[{index}/{len(premises)}]")
        print(f"Premise code: {premise_code}")
        print(f"Searching: {full_address}")

        try:
            geocode_result = geocode_address(full_address)

            with engine.begin() as conn:
                if geocode_result["status"] == "FOUND":
                    conn.execute(text("""
                        UPDATE premises
                        SET latitude = :latitude,
                            longitude = :longitude,
                            geocoding_status = :geocoding_status
                        WHERE premise_code = :premise_code
                    """), {
                        "latitude": geocode_result["latitude"],
                        "longitude": geocode_result["longitude"],
                        "geocoding_status": "FOUND",
                        "premise_code": premise_code
                    })

                    print(
                        f"FOUND: {geocode_result['latitude']}, "
                        f"{geocode_result['longitude']}"
                    )

                else:
                    conn.execute(text("""
                        UPDATE premises
                        SET geocoding_status = :geocoding_status
                        WHERE premise_code = :premise_code
                    """), {
                        "geocoding_status": geocode_result["status"],
                        "premise_code": premise_code
                    })

                    print(f"NOT FOUND / ERROR: {geocode_result['status']}")

        except requests.exceptions.RequestException as e:
            with engine.begin() as conn:
                conn.execute(text("""
                    UPDATE premises
                    SET geocoding_status = :geocoding_status
                    WHERE premise_code = :premise_code
                """), {
                    "geocoding_status": "REQUEST_ERROR",
                    "premise_code": premise_code
                })

            print(f"REQUEST ERROR: {e}")

        except Exception as e:
            print(f"UNKNOWN ERROR: {e}")

        time.sleep(0.2)

    print("\nGeocoding completed.")


if __name__ == "__main__":
    main()