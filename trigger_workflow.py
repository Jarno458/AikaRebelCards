import base64
import requests
import os

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
GITHUB_REPO = "Jarno458/AikaRebelCards"

def trigger_github_workflow(image_data: bytes):
    """Trigger the GitHub image-upload workflow with file data already read"""
    
    # Encode the image data as base64
    image_base64 = base64.b64encode(image_data).decode("utf-8")
    
    # Trigger GitHub workflow
    response = requests.post(
        f"https://api.github.com/repos/{GITHUB_REPO}/dispatches",
        headers={
            "Authorization": f"token {GITHUB_TOKEN}",
            "Accept": "application/vnd.github.v3+json",
        },
        json={
            "event_type": "image-upload",
            "client_payload": {
                "image": image_base64
            }
        }
    )
    
    if response.status_code == 204:
        print("✓ GitHub workflow triggered successfully!")
    else:
        print(f"✗ Failed to trigger workflow: {response.status_code}")
        print(response.text)

# Usage in your script:
# If you already have image data read:
# with open("image.png", "rb") as f:
#     image_data = f.read()
# 
# trigger_github_workflow(image_data)
