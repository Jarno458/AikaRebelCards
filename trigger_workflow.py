import base64
import requests as http_requests
import os

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")

def upload_image_to_jarnos_github(image_data: bytes, filename: str, creator: str, type: str, series: str = "", rarity: str = "", finish: str = "", description: str = ""):
    try:
        # Encode the image data as base64
        image_base64 = base64.b64encode(image_data).decode("utf-8")
        
        # Trigger GitHub workflow
        response = http_requests.post(
            f"https://api.github.com/repos/Jarno458/AikaRebelCards/dispatches",
            headers={
                "Authorization": f"Bearer {GITHUB_TOKEN}",
                "Accept": "application/vnd.github.v3+json",
            },
            json={
                "event_type": "image-upload",
                "client_payload": {
                    "image": image_base64,
                    "filename": filename,
                    "rarity": rarity,
                    "finish": finish,
                    "creator": creator,
                    "type": type,
                    "series": series,
                    "description": description,
                }
            }
        )
        
        if response.status_code == 204:
            print("✓ Image dispatched to GitHub successfully!")
        else:
            print(f"✗ Failed to dispatch image to github workflow: {response.status_code}")
            print(response.text)
    
    except Exception as e:
        print(f"✗ Error dispatching image to GitHub workflow: {str(e)}")

# Usage in your script:
# If you already have image data read (bytes):
# image_data = b"...your image bytes..."

image_data = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
    # 1x1 PNG with a red pixel
)
upload_image_to_jarnos_github(image_data, "my_image.png", creator="my_creator", type="card", series="my_series", rarity="rare", finish="holo", description="my_description")


