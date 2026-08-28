from typing import Annotated
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from .database import engine
from .security import decode_access_token


# Set up OAuth2PasswordBearer for token extraction from requests
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl = "/users/login"
)

# Dependency function to get the current authenticated user from the JWT token
def get_current_user(token: Annotated[str, Depends(oauth2_scheme)]) -> dict:
    payload = decode_access_token(token)

    user_id = payload.get("user_id")

    try:
        with engine.connect() as conn:
            user = conn.execute(text("""
                SELECT
                    user_id,
                    user_name,
                    email,
                    phone_number,
                    dob,
                    nric
                FROM users
                WHERE user_id = :user_id
            """), {
                "user_id": user_id
            }).mappings().first()

    except SQLAlchemyError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to retrieve authenticated user"
        ) from e

    if user is None:
        raise HTTPException(
            status_code = status.HTTP_401_UNAUTHORIZED,
            detail = "User no longer exists",
            headers = {
                "WWW-Authentication": "Bearer"
            }
        )

    return dict(user)