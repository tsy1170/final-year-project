from pathlib import Path
import firebase_admin
from firebase_admin import messaging, credentials
from pydantic import Field

BASE_DIR = Path(__file__).resolve().parent

FIREBASE_SERVICE_ACCOUNT_PATH = BASE_DIR / (
    "fyp-push-notifications-firebase-adminsdk-fbsvc-edae814911.json"
)

# Initialize Firebase Admin SDK only once
if not firebase_admin._apps:
    cred = credentials.Certificate(
        FIREBASE_SERVICE_ACCOUNT_PATH
    )

    firebase_admin.initialize_app(cred)

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