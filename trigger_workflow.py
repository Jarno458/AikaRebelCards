import requests as http_requests
import os

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")

def upload_image_to_jarnos_github(supabase_url: str, card_id: str, type: str):
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
                    "guid": card_id,
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
    supabase_url="https://twyfuamtvdbtbnvbalbe.supabase.co/",
    card_id="5a361c4f-04e4-4fe4-b79c-6b9353cd0fa8",
    type="card",
)

