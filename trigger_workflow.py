import requests as http_requests
import os

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")

def upload_image_to_jarnos_github(supabase_url: str, supabase_bucket: str, storage_path: str, guid: str, type: str):
    try:
        # Trigger GitHub workflow
        response = http_requests.post(
            f"https://api.github.com/repos/Jarno458/AikaRebelCards/dispatches",
            headers={
                "Authorization": f"Bearer {GITHUB_TOKEN}",
                "Accept": "application/vnd.github.v3+json",
            },
            json={
                "event_type": f"{type}-upload",
                "client_payload": {
                    "supabase_url": supabase_url,
                    "supabase_bucket": supabase_bucket,
                    "storage_path": storage_path,
                    "guid": guid,
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

upload_image_to_jarnos_github(
    supabase_url="https://your-project.supabase.co",
    supabase_bucket="images",
    storage_path="uploads/my_image.png",
    guid="734b9a44-3dbd-49ef-92d3-198a990267d2",
    type="photo",
)

