import os
import json
from pathlib import Path
import firebase_admin
from firebase_admin import messaging, credentials, storage
from pydantic import Field
from dotenv import load_dotenv

load_dotenv()


BASE_DIR = Path(__file__).resolve().parent

def get_firebase_credentials():
    service_account_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")

    if service_account_json:
        service_account_info = json.loads(service_account_json)
        return credentials.Certificate(service_account_info)

    service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")

    if service_account_path:
        path = Path(service_account_path)

        if not path.is_absolute():
            path = BASE_DIR.parent / path

        return credentials.Certificate(path)

    raise RuntimeError(
        "Firebase credentials are not configured. "
        "Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_PATH."
    )


if not firebase_admin._apps:
    cred = get_firebase_credentials()
    firebase_admin.initialize_app(cred, {
        'storageBucket': os.getenv("FIREBASE_STORAGE_BUCKET")
    })


def send_price_notification(fcm_token: str = Field(description="Device token"),
                            item_name: str = Field(description="Name of the item"),
                            price: float = Field(description="Price of the item"),
                            target_price: float = Field(description="Target price set by the user"),
                            premise_name: str = Field(description="Name of the premise")) -> bool:

    try:
        # send notification to the device with the given FCM token
        message = messaging.Message(
            notification=messaging.Notification(
                title = f"Latest Price",
                body=(
                    f"{item_name} is now RM{price:.2f} at {premise_name}. "
                ),
            ),

            data={
                "type": "price_alert",
                "item_name": item_name,
                "price": str(price),
                "target_price": str(target_price),
                "premise_name": premise_name    
            },

            token=fcm_token
        )

        response = messaging.send(message)

        print("Price notification sent successfully:", response)

        return True

    except Exception as e:
        print(e)
        return False