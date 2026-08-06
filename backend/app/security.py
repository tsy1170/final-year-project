import os
from datetime import datetime, timedelta, timezone
from typing import Any
import jwt
from dotenv import load_dotenv
from fastapi import HTTPException, status
from jwt.exceptions import InvalidTokenError


load_dotenv()

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", 60))

if not JWT_SECRET_KEY:
    raise ValueError("JWT_SECRET_KEY is missing from the environment")


# function to create a JWT access token
def create_access_token(user_id: int, 
                        email: str,
                        expires_minutes: int | None = None) -> str:
    """
    Create a signed JWT access token.
    The subject claim stores the user ID as a string.
    """
    current_time = datetime.now(timezone.utc)

    # Determine the expiration time for the token, defaulting to JWT_ACCESS_TOKEN_EXPIRE_MINUTES if not provided (60 minutes)
    expiration_minutess = (
        expires_minutes if expires_minutes is not None else JWT_ACCESS_TOKEN_EXPIRE_MINUTES
    )

    # Calculate the expiration time
    expiration_time = current_time + timedelta(minutes = expiration_minutess)

    payload: dict[str, Any] = {
        "sub": str(user_id),
        "email": email,
        "iat": current_time,
        "exp": expiration_time
    }

    return jwt.encode(payload, JWT_SECRET_KEY, algorithm = JWT_ALGORITHM)


# function to decode and validate the JWT access token
def decode_access_token(
    token: str
) -> dict[str, Any]:
    """
    Validate a JWT token and return its payload.

    Validation includes:
    - signature
    - expiration
    - algorithm
    - subject claim
    """

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={
            "WWW-Authenticate": "Bearer"
        }
    )

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET_KEY,
            algorithms=[JWT_ALGORITHM],
            options={
                "require": [
                    "sub",
                    "exp",
                    "iat"
                ]
            }
        )

        user_id = payload.get("sub")

        if user_id is None:
            raise credentials_exception

        # Convert the user_id to int and add it back to payload
        try:
            payload["user_id"] = int(user_id)
        except (TypeError, ValueError):
            raise credentials_exception

        return payload

    except InvalidTokenError as error:
        raise credentials_exception from error