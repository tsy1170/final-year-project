from pathlib import Path
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

BASE_DIR = Path(__file__).resolve().parent
IMAGE_DIRECTORY = BASE_DIR / "product_images"

ALLOWED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif"}

engine = create_engine(DATABASE_URL)

def update_image_path():
    if not IMAGE_DIRECTORY.exists():
        raise FileNotFoundError(f"Image directory '{IMAGE_DIRECTORY}' does not exist.")
    
    updated_count = 0
    unmatched_count = 0
    skipped_count = 0
    existing_filled_count = 0

    with engine.begin() as conn:
        for image_file in IMAGE_DIRECTORY.iterdir():
            if not image_file.is_file():
                continue

            extension = image_file.suffix.lower()
            if extension not in ALLOWED_IMAGE_EXTENSIONS:
                print(f"Skipping unsupported file type: {image_file.name}")
                skipped_count += 1
                continue

            item_code_text = image_file.stem  # Get the filename without extension

            if not item_code_text.isdigit():
                print(f"Skipped invalid filename: {image_file.name}")
                skipped_count += 1
                continue
                
            item_code = int(item_code_text)
            
            image_path = f"/product_images/{image_file.name}"

            result = conn.execute(text("""
                UPDATE items
                SET image_path = :image_path
                WHERE item_code = :item_code
                AND (image_path IS NULL OR image_path = '')
            """), {
                "image_path": image_path,
                "item_code": item_code
            })

            if result.rowcount > 0:
                updated_count += 1
                print(f"Updated item {item_code} with image path: {image_path}")

            else:
                existing_path = conn.execute(text("""
                    SELECT image_path
                    FROM items
                    WHERE item_code = :item_code
                """), {
                    "item_code": item_code
                }).scalar_one_or_none()

                if existing_path is None:
                    unmatched_count += 1
                    print(f"No matching item found for image: {image_file.name}")

                else:
                    existing_filled_count += 1
                    print(f"Item {item_code} already has an image path: {existing_path}.")


    print("\nUpdate completed")
    print(f"Updated items: {updated_count}")
    print(f"Images without matching items: {unmatched_count}")
    print(f"Skipped files: {skipped_count}")
    print(f"Items with existing image paths: {existing_filled_count}")


if __name__ == "__main__":
    update_image_path()
