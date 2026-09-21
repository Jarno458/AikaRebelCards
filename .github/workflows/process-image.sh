#!/bin/bash
set -e

if [ "$IMAGE_TYPE" = "card-upload" ]; then
  TARGET_FOLDER="Cards"
  JSON_COLLECTION="cards"
elif [ "$IMAGE_TYPE" = "photo-upload" ]; then
  TARGET_FOLDER="Photos"
  JSON_COLLECTION="photos"
else
  echo "Unknown image type: $IMAGE_TYPE"
  exit 1
fi

mkdir -p "$TARGET_FOLDER"

if [ -z "$SUPABASE_URL" ] || [ -z "$GUID" ]; then
  echo "Missing Supabase URL, bucket, storage path, or GUID"
  exit 1
fi

if [ -z "$SUPABASE_API_TOKEN" ]; then
  echo "Missing SUPABASE_API_TOKEN secret"
  exit 1
fi

# Download card info from Supabase REST API
CARD_DETAILS=$(wget --quiet --output-document=- \
  --header="apikey: $SUPABASE_API_TOKEN" \
  "${SUPABASE_URL%/}/rest/v1/cards?select=owner_discord_id,series,description,rarity,finish,image_url,created_at,number_in_series&id=eq.${GUID}")

if [ "$(echo "$CARD_DETAILS" | jq 'length')" -ne 1 ]; then
  echo "No unique card found for GUID: $GUID"
  exit 1
fi

CREATOR=$(echo "$CARD_DETAILS" | jq -r '.[0].owner_discord_id // ""')
SERIES=$(echo "$CARD_DETAILS" | jq -r '.[0].series // ""')
DESCRIPTION=$(echo "$CARD_DETAILS" | jq -r '.[0].description // ""')
RARITY=$(echo "$CARD_DETAILS" | jq -r '.[0].rarity // ""')
FINISH=$(echo "$CARD_DETAILS" | jq -r '.[0].finish // ""')
IMAGE_URL=$(echo "$CARD_DETAILS" | jq -r '.[0].image_url // ""')
TIMESTAMP=$(echo "$CARD_DETAILS" | jq -r '.[0].created_at // ""')
NUMBER_IN_SERIES=$(echo "$CARD_DETAILS" | jq -r '.[0].number_in_series // ""')

# Read properties.json and find the oldest item in the selected collection
OLDEST_SLOT=$(jq -r --arg collection "$JSON_COLLECTION" '.[$collection] | sort_by(.uploadTimestamp // "9999-12-31T23:59:59") | .[0].slot' properties.json)

# Download the image from the public Supabase Storage URL
wget --quiet --output-document="${TARGET_FOLDER}/${OLDEST_SLOT}.png" "$IMAGE_URL"

# Update properties.json with new card data
jq --arg slot "$OLDEST_SLOT" \
   --arg image_url "$IMAGE_URL" \
   --arg creator "$CREATOR" \
   --arg series "$SERIES" \
   --arg description "$DESCRIPTION" \
   --arg rarity "$RARITY" \
   --arg finish "$FINISH" \
   --arg timestamp "$TIMESTAMP" \
  --arg number_in_series "$NUMBER_IN_SERIES" \
   --arg collection "$JSON_COLLECTION" \
   '.[$collection] |= map(
     if .slot == ($slot | tonumber) then
       .image_url = $image_url |
       .creator = $creator |
       .series = $series |
       .description = $description |
       .rarity = $rarity |
       .finish = $finish |
      .uploadTimestamp = $timestamp |
      .number_in_series = $number_in_series
     else
       .
     end
   )' \
   properties.json > properties.json.tmp && mv properties.json.tmp properties.json

echo "Replaced ${JSON_COLLECTION%?} in slot ${OLDEST_SLOT}"
echo "  Dispatch type: ${IMAGE_TYPE}"
echo "  Folder: ${TARGET_FOLDER}"
echo "  GUID: ${GUID}"
echo "  Creator: ${CREATOR}"
echo "  Series: ${SERIES}"
echo "  Description: ${DESCRIPTION}"
echo "  Rarity: ${RARITY}"
echo "  Finish: ${FINISH}"
echo "  Timestamp: ${TIMESTAMP}"
echo "  Number in series: ${NUMBER_IN_SERIES}"
