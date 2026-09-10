from PIL import Image
import numpy as np

# Define enums
RARITY = {
    'common': 0,
    'uncommon': 1,
    'rare': 2,
    'legendary': 3,
    'mythic': 4
}

FINISH = {
    'none': 0,
    'golden': 1,
    'foil': 2,
    'phantom': 3
}

def encode_properties(image_path: str, output_path: str, rarity: str, finish: str):
    """
    Encode rarity and finish into the top-left corner of an image.
    Uses 2 pixels: 1st pixel = rarity, 2nd pixel = finish
    
    Args:
        image_path: Path to input image
        output_path: Path to save encoded image
        rarity: One of 'common', 'uncommon', 'rare', 'legendary', 'mythic'
        finish: One of 'none', 'golden', 'foil', 'phantom'
    """
    
    if rarity not in RARITY:
        raise ValueError(f"Invalid rarity: {rarity}. Must be one of {list(RARITY.keys())}")
    if finish not in FINISH:
        raise ValueError(f"Invalid finish: {finish}. Must be one of {list(FINISH.keys())}")
    
    # Load image
    img = Image.open(image_path)
    img_array = np.array(img.convert('RGBA'))
    
    rarity_value = RARITY[rarity]
    finish_value = FINISH[finish]
    
    # Encode into first two pixels' channels
    # Pixel [0,0] red channel: packed data (rarity in upper 4 bits, finish in lower 4 bits)
    packed_value = (rarity_value << 4) | finish_value
    img_array[0, 0, 0] = packed_value
    img_array[0, 0, 3] = 255  # Ensure full alpha
    
    # Pixel [0,1]: Backup uncompressed data
    # Red = rarity value, Green = finish value, Blue = magic marker (42)
    img_array[0, 1, 0] = rarity_value
    img_array[0, 1, 1] = finish_value
    img_array[0, 1, 2] = 42  # Magic marker to validate encoded data
    img_array[0, 1, 3] = 255  # Ensure full alpha
    
    # Convert back to image and save
    result_img = Image.fromarray(img_array, 'RGBA')
    result_img.save(output_path)
    print(f"✓ Encoded '{rarity}' (rarity={rarity_value}) + '{finish}' (finish={finish_value}) to {output_path}")

def decode_image_properties(image_path: str) -> tuple:
    """
    Decode rarity and finish from an encoded image.
    
    Args:
        image_path: Path to encoded image
        
    Returns:
        Tuple of (rarity_name, finish_name, rarity_value, finish_value)
    """
    img = Image.open(image_path)
    img_array = np.array(img.convert('RGBA'))
    
    # Try backup method first (more reliable)
    rarity = int(img_array[0, 1, 0])
    finish = int(img_array[0, 1, 1])
    magic = int(img_array[0, 1, 2])
    
    if magic != 42:
        # Fallback to packed method
        packed_value = int(img_array[0, 0, 0])
        rarity = (packed_value >> 4) & 0x0F
        finish = packed_value & 0x0F
    
    rarity_names = ['common', 'uncommon', 'rare', 'legendary', 'mythic']
    finish_names = ['none', 'golden', 'foil', 'phantom']
    
    if 0 <= rarity < len(rarity_names) and 0 <= finish < len(finish_names):
        return (rarity_names[rarity], finish_names[finish], rarity, finish)
    else:
        return ('unknown', 'unknown', -1, -1)

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 4:
        print("Usage: python encode_card_properties.py <input.png> <output.png> <rarity> <finish>")
        print(f"\nRarity options: {', '.join(RARITY.keys())}")
        print(f"Finish options: {', '.join(FINISH.keys())}")
        sys.exit(1)
    
    input_img = sys.argv[1]
    output_img = sys.argv[2]
    rarity = sys.argv[3].lower()
    finish = sys.argv[4].lower()
    
    try:
        encode_properties(input_img, output_img, rarity, finish)
        # Verify by decoding
        decoded = decode_image_properties(output_img)
        print(f"✓ Verification: {decoded[0]}, {decoded[1]}")
    except Exception as e:
        print(f"✗ Error: {e}")
        sys.exit(1)
