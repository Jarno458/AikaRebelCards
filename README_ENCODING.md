# Image Property Encoding System

This system encodes card properties (rarity and finish type) directly into PNG pixel data that can be read in VRChat via `VRCAsyncGpuReadback`.

## Supported Values

### Rarity Levels
- `common` (0)
- `uncommon` (1)
- `rare` (2)
- `legendary` (3)
- `mythic` (4)

### Finish Types
- `none` (0)
- `golden` (1)
- `foil` (2)
- `phantom` (3)

## Python Usage

### Basic Encoding

```bash
python encode_card_properties.py input.png output.png mythic phantom
```

### In Python Code

```python
from encode_card_properties import encode_properties, decode_image_properties

# Encode properties into image
encode_properties('aika.png', 'aika_mythic_phantom.png', 'mythic', 'phantom')

# Verify by decoding
rarity_name, finish_name, rarity_val, finish_val = decode_image_properties('aika_mythic_phantom.png')
print(f"Rarity: {rarity_name} ({rarity_val})")
print(f"Finish: {finish_name} ({finish_val})")
```

## UdonSharp Usage

### Setup

1. Add `ImagePropertyReader.cs` to your VRChat world project
2. Create a GameObject and attach the `ImagePropertyReader` script
3. Assign your encoded image to the `encodedImage` field in the inspector

### Reading Properties

```csharp
public ImagePropertyReader cardReader;

void Start()
{
    // Wait for decode to complete
    StartCoroutine(WaitForDecode());
}

IEnumerator WaitForDecode()
{
    while (!cardReader.IsDecoded())
    {
        yield return null;
    }
    
    string rarity = cardReader.GetRarity();  // "mythic"
    string finish = cardReader.GetFinish();   // "phantom"
    int rarityVal = cardReader.GetRarityValue();
    int finishVal = cardReader.GetFinishValue();
    
    Debug.Log($"Card is {rarity} with {finish} finish!");
}
```

## Encoding Details

### Pixel Storage

Data is stored in the top-left corner of the image:

**Pixel [0,0]** - Packed format (primary)
- Red channel: `(rarity << 4) | finish`
- Alpha channel: 255 (full opacity)

**Pixel [0,1]** - Uncompressed backup (recommended)
- Red channel: rarity value (0-4)
- Green channel: finish value (0-3)
- Blue channel: 42 (magic marker for validation)
- Alpha channel: 255 (full opacity)

### Why This Works

- ✓ Only 2 corner pixels modified (invisible in detailed images)
- ✓ Redundant encoding for reliability
- ✓ Magic marker (42) validates data integrity
- ✓ No data loss with RGBA32 texture format
- ✓ Works with `VRCAsyncGpuReadback.TryGetData()`

## Workflow Example

```bash
# 1. Encode a card image with properties
python encode_card_properties.py card_template.png aika_mythic_phantom.png mythic phantom

# 2. Upload the encoded image to your VRChat world
# 3. Assign it to ImagePropertyReader in your scene
# 4. At runtime, VRChat will decode the properties automatically
```

## Notes

- Images must be at least 2x1 pixels for encoding
- Encoding modifies only 2 corner pixels - safe for detailed artwork
- The backup method (pixel [0,1]) is more reliable and used by default
- All image formats supported by PIL are compatible (PNG, JPG, etc.)
