#!/bin/bash
set -e

TARGET_FOLDER="Cards"
JSON_COLLECTION="cards"
LIMIT="${LIMIT:-10}"

if [ -z "$SUPABASE_URL" ]; then
  echo "Missing Supabase URL"
  exit 1
fi

if [ -z "$SUPABASE_API_TOKEN" ]; then
  echo "Missing SUPABASE_API_TOKEN secret"
  exit 1
fi

mkdir -p "$TARGET_FOLDER"

if ! CARDS=$(curl --fail --silent --show-error \
  -H "apikey: $SUPABASE_API_TOKEN" \
  -H "Accept: application/json" \
  "${SUPABASE_URL%/}/rest/v1/cards?select=name,owner_discord_id,series,description,rarity,finish,image_url,created_at,number_in_series&order=created_at.desc&limit=${LIMIT}"); then
  echo "Failed to fetch latest cards from Supabase"
  exit 1
fi

if ! printf '%s' "$CARDS" | jq -e 'type == "array"' > /dev/null; then
  echo "Supabase returned an invalid response"
  printf '%s\n' "$CARDS"
  exit 1
fi

COUNT=$(printf '%s' "$CARDS" | jq 'length')
if [ "$COUNT" -eq 0 ]; then
  echo "No cards returned from Supabase"
  exit 1
fi

echo "Fetched ${COUNT} card(s)"

for i in $(seq 0 $((COUNT - 1))); do
  SLOT=$((i + 1))
  CARD=$(printf '%s' "$CARDS" | jq -c ".[$i]")
  IMAGE_URL=$(printf '%s' "$CARD" | jq -r '.image_url // ""')

  if [ -z "$IMAGE_URL" ]; then
    echo "Slot ${SLOT}: no image_url, skipping"
    continue
  fi

  if ! wget --quiet --output-document="${TARGET_FOLDER}/${SLOT}.png" "$IMAGE_URL"; then
    echo "Slot ${SLOT}: failed to download ${IMAGE_URL}"
    rm -f "${TARGET_FOLDER}/${SLOT}.png"
    exit 1
  fi

  jq --argjson slot "$SLOT" \
     --argjson card "$CARD" \
     --arg collection "$JSON_COLLECTION" \
     '.[$collection] |= map(
       if .slot == $slot then
         .name = ($card.name // "") |
         .image_url = ($card.image_url // "") |
         .creator = ($card.owner_discord_id // "") |
         .series = ($card.series // "") |
         .description = ($card.description // "") |
         .rarity = ($card.rarity // "") |
         .finish = ($card.finish // "") |
         .uploadTimestamp = ($card.created_at // "") |
         .number_in_series = (($card.number_in_series // "") | tostring)
       else
         .
       end
     )' \
     properties.json > properties.json.tmp && mv properties.json.tmp properties.json

  echo "Slot ${SLOT}: $(printf '%s' "$CARD" | jq -r '.name // "(unnamed)"')"
done
