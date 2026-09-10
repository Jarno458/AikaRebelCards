using UdonSharp;
using UnityEngine;
using VRC.SDK3.Rendering;
using VRC.Udon.Common.Interfaces;

public class ImagePropertyReader : UdonSharpBehaviour
{
    [Tooltip("Encoded image with rarity and finish data in pixel values")]
    public Texture2D encodedImage;
    
    private RenderTexture readbackTexture;
    private Color32[] pixelData;
    
    private int decodedRarity = -1;
    private int decodedFinish = -1;
    private bool isDecoded = false;
    
    private string[] rarityNames = { "common", "uncommon", "rare", "legendary", "mythic" };
    private string[] finishNames = { "none", "golden", "foil", "phantom" };

    void Start()
    {
        if (encodedImage == null)
        {
            Debug.LogError("[ImagePropertyReader] No encoded image assigned!");
            return;
        }
        
        // Convert Texture2D to RenderTexture for async readback
        readbackTexture = new RenderTexture(
            encodedImage.width,
            encodedImage.height,
            0,
            RenderTextureFormat.ARGB32
        );
        Graphics.Blit(encodedImage, readbackTexture);
        
        // Request async GPU readback
        VRCAsyncGPUReadback.Request(
            readbackTexture,
            0,
            TextureFormat.RGBA32,
            (IUdonEventReceiver)this
        );
    }

    public override void OnAsyncGpuReadbackComplete(VRCAsyncGPUReadbackRequest request)
    {
        if (request.hasError)
        {
            Debug.LogError("[ImagePropertyReader] GPU readback error!");
            return;
        }

        pixelData = new Color32[readbackTexture.width * readbackTexture.height];
        if (request.TryGetData(pixelData))
        {
            DecodeProperties();
            isDecoded = true;
        }
    }

    void DecodeProperties()
    {
        // Method 1: Try backup method first (more reliable)
        // Pixel [0,1]: Red = rarity, Green = finish, Blue = magic marker (42)
        int rarity = pixelData[1].r;
        int finish = pixelData[1].g;
        int magic = pixelData[1].b;
        
        if (magic == 42)
        {
            // Valid backup data
            decodedRarity = rarity;
            decodedFinish = finish;
        }
        else
        {
            // Method 2: Fallback to packed method
            // Pixel [0,0] red channel: packed data (rarity in upper 4 bits, finish in lower 4 bits)
            byte packedValue = pixelData[0].r;
            
            decodedRarity = (packedValue >> 4) & 0x0F;  // Upper 4 bits
            decodedFinish = packedValue & 0x0F;         // Lower 4 bits
        }
        
        // Validate ranges
        if (decodedRarity >= 0 && decodedRarity < rarityNames.Length &&
            decodedFinish >= 0 && decodedFinish < finishNames.Length)
        {
            Debug.Log($"[ImagePropertyReader] ✓ Decoded: Rarity = {rarityNames[decodedRarity]}, Finish = {finishNames[decodedFinish]}");
        }
        else
        {
            Debug.LogWarning($"[ImagePropertyReader] Invalid decoded values: rarity={decodedRarity}, finish={decodedFinish}");
        }
    }

    /// <summary>
    /// Get the decoded rarity as a string.
    /// </summary>
    public string GetRarity()
    {
        if (!isDecoded) return "unknown";
        return (decodedRarity >= 0 && decodedRarity < rarityNames.Length) 
            ? rarityNames[decodedRarity] 
            : "unknown";
    }

    /// <summary>
    /// Get the decoded finish type as a string.
    /// </summary>
    public string GetFinish()
    {
        if (!isDecoded) return "unknown";
        return (decodedFinish >= 0 && decodedFinish < finishNames.Length) 
            ? finishNames[decodedFinish] 
            : "unknown";
    }

    /// <summary>
    /// Get the decoded rarity as an integer (0-4).
    /// </summary>
    public int GetRarityValue()
    {
        return decodedRarity;
    }

    /// <summary>
    /// Get the decoded finish type as an integer (0-3).
    /// </summary>
    public int GetFinishValue()
    {
        return decodedFinish;
    }

    /// <summary>
    /// Check if decoding is complete.
    /// </summary>
    public bool IsDecoded()
    {
        return isDecoded;
    }
}
