from sqlalchemy import text

if __package__ in (None, ""):
    from database import engine
    from firebase_service import send_price_notification
    from osrm_services import get_road_distance
else:
    from .database import engine
    from .firebase_service import send_price_notification
    from .osrm_services import get_road_distance

def check_price_alerts(radius_km: int = 10):
    """
    Check active price alerts against the latest price records.

    The user location stored in each price_alert is used to calculate
    actual road-network distance to candidate premises.
    """

    try:

        with engine.begin() as connection:
            # ==================================================
            # 1. Get the latest available price date
            # ==================================================
            latest_price_date = connection.execute(
                text("""
                    SELECT MAX(price_date)
                    FROM price_records
                """)
            ).scalar()

            if latest_price_date is None:
                print("No price records found.")
                return
            
            print(
                f"Checking price alerts for "
                f"price date: {latest_price_date}"
            )

            # ==================================================
            # 2. Get candidate price records
            #
            # SQL handles:
            # - Active alerts
            # - Latest price date
            # - Price <= target price
            #
            # Python + OSRM handles:
            # - Actual road distance <= radius_km
            # ==================================================

            result = connection.execute(
                text("""
                    SELECT
                        pa.alert_id,
                        pa.user_id,
                        pa.item_code,
                        pa.target_price,

                        pa.user_latitude,
                        pa.user_longitude,

                        u.fcm_token,

                        i.item_name,

                        pr.price,
                        pr.price_date,

                        p.premise_code,
                        p.premise_name,
                        p.latitude AS premise_latitude,
                        p.longitude AS premise_longitude

                    FROM price_alerts pa

                    JOIN users u
                        ON u.user_id = pa.user_id

                    JOIN items i
                        ON i.item_code = pa.item_code

                    JOIN price_records pr
                        ON pr.item_code = pa.item_code
                        AND pr.price_date = :latest_price_date

                    JOIN premises p
                        ON p.premise_code = pr.premise_code

                    WHERE pa.is_active = TRUE
                        AND u.fcm_token IS NOT NULL
                        AND u.fcm_token <> ''

                        AND pa.user_latitude IS NOT NULL
                        AND pa.user_longitude IS NOT NULL

                        AND p.latitude IS NOT NULL
                        AND p.longitude IS NOT NULL

                        AND pr.price <= pa.target_price

                        -- Straight-line distance pre-filter
                        AND ST_DWithin(
                            p.location,
                            ST_SetSRID(
                                ST_MakePoint(
                                    pa.user_longitude,
                                    pa.user_latitude
                                ),
                                4326
                            )::geography,
                            :radius_m
                        )

                    ORDER BY pa.alert_id, pr.price ASC
                """),
                {
                    "latest_price_date": latest_price_date,
                    "radius_m": radius_km * 1000 
                }
            )

            candidates = result.mappings().all()

            if not candidates:
                print("No price alerts currently meet the target price.")
                return

            # ==================================================
            # 3. Group candidate premises by alert
            # ==================================================
            candidates_by_alert = {}

            for candidate in candidates:
                alert_id = candidate["alert_id"]
                if alert_id not in candidates_by_alert:
                    candidates_by_alert[alert_id] = {
                        "alert_info": {
                            "alert_id": alert_id,
                            "user_id": candidate["user_id"],
                            "item_code": candidate["item_code"],
                            "target_price": float(candidate["target_price"]),
                            "user_latitude": float(candidate["user_latitude"]),
                            "user_longitude": float(candidate["user_longitude"]),
                            "fcm_token": candidate["fcm_token"],
                            "item_name": candidate["item_name"],
                        },

                        "stores": [],
                    }

                # Add the candidate premise.
                # This dictionary will be passed to get_road_distance().
                candidates_by_alert[alert_id]["stores"].append(
                    {
                        "premise_code": candidate["premise_code"],
                        "premise_name": candidate["premise_name"],
                        "latitude": float(candidate["premise_latitude"]),
                        "longitude": float(candidate["premise_longitude"]),
                        "price": float(candidate["price"]),
                    }
                )

            # ==================================================
            # 4. Process every alert
            # ==================================================
            for alert_id, alert_data in candidates_by_alert.items():
                alert_info = alert_data["alert_info"]
                candidate_premises = alert_data["stores"]

                # ==============================================
                # 5. Calculate actual road-network distance
                # ==============================================
                premises_with_road_distance = get_road_distance(
                    user_latitude=alert_info["user_latitude"],
                    user_longitude=alert_info["user_longitude"],
                    stores=candidate_premises,
                )

                # ==============================================
                # 6. Keep only premises within radius
                # ==============================================
                nearby_premises = [
                    premise
                    for premise in premises_with_road_distance
                    if premise.get("road_distance_km") is not None
                    and premise["road_distance_km"] <= radius_km
                ]

                if not nearby_premises:
                    print(
                        f"Alert {alert_id}: "
                        f"No qualifying premises within "
                        f"{radius_km} km."
                    )
                    continue

                # ==============================================
                # 7. Select the cheapest nearby premise
                # ==============================================
                best_premise = min(
                    nearby_premises,
                    key=lambda premise: premise["price"],
                )

                # ==============================================
                # 8. Send notification
                # ==============================================
                success = send_price_notification(
                    fcm_token=alert_info["fcm_token"],
                    item_name=alert_info["item_name"],
                    price=float(best_premise["price"]),
                    target_price=alert_info["target_price"],
                    premise_name=best_premise["premise_name"],
                )

                # ==============================================
                # 9. Update only after successful notification
                # ==============================================
                if success:
                    connection.execute(
                        text("""
                            UPDATE price_alerts
                            SET
                                is_active = FALSE,
                                last_notified = CURRENT_TIMESTAMP
                            WHERE alert_id = :alert_id
                        """), {
                            "alert_id": alert_id,
                        }
                    )

                    print(f"Alert {alert_id} triggered successfully.")

                else:
                    print(
                        f"Failed to send notification "
                        f"for alert {alert_id}."
                    )

    except Exception as error:
        print("=== CHECK PRICE ALERT ERROR ===")
        print(error)
        raise

if __name__ == "__main__":
    check_price_alerts(radius_km=10)