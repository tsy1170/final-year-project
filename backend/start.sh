#!/bin/bash
set -e

# Upgrade pip and install wheel to ensure psycopg2 compiles correctly
pip install --upgrade pip wheel setuptools

# Install dependencies from requirements.txt
pip install -r requirements.txt

# Run the FastAPI app with uvicorn
uvicorn app.main:app --host 0.0.0.0 --port 8000
