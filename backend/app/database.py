from dotenv import load_dotenv
from sqlalchemy import create_engine
import os


load_dotenv()


def create_database_engine():
    DATABASE_URL = os.getenv("DATABASE_URL")
    if not DATABASE_URL:
        raise RuntimeError("DATABASE_URL is not set")

    return create_engine(DATABASE_URL)


engine = create_database_engine()
