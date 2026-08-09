from fastapi import Request

def build_image_url(request: Request | None, image_path: str | None) -> str | None:
    if not image_path:
        return None

    base_url = str(request.base_url).rstrip("/") if request is not None else None
    return f"{base_url}{image_path}" if base_url else image_path