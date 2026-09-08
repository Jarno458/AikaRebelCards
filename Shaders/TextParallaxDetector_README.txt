TextParallaxDetector Shader - Parameter Guide
===============================================

This shader detects text elements in an image and applies parallax depth effects,
keeping text in the foreground while the background shifts to create depth perception.

BASIC SETUP
-----------
1. Apply the shader to a material in Unity
2. Set _MainTex to your card image
3. Adjust parameters in the material inspector to match your specific card

TEXT DETECTION PARAMETERS
==========================

Red Text Detection:
  _RedTextMin (Range: 0.0-1.0, Default: 0.5)
    - Minimum brightness threshold for red text detection
    - Lower = detects darker reds; Higher = only bright reds
    
  _RedTextMax (Range: 0.0-1.0, Default: 1.0)
    - Maximum brightness threshold for red text detection
    - Caps how bright red pixels must be to be detected
    
  _RedHueRange (Range: 0.0-0.1, Default: 0.05)
    - Color range tolerance for red hue detection
    - Lower = only pure reds; Higher = includes orange-reds
    - Recommended: 0.05-0.08 for most cards

Gold/Tan Text Detection:
  _GoldTextMin (Range: 0.0-1.0, Default: 0.4)
    - Minimum brightness threshold for gold text
    - Lower = detects darker golds and shadows; Higher = only bright gold
    - Recommended for unique cards: 0.35
    
  _GoldTextMax (Range: 0.0-1.0, Default: 0.9)
    - Maximum brightness threshold for gold text
    - Controls how bright gold can be before being excluded
    - Recommended for unique cards: 0.95
    
  _GoldHueRange (Range: 0.0-0.2, Default: 0.12)
    - Color range tolerance for gold/yellow hue
    - Lower = only pure gold; Higher = includes orange and yellow tones
    - Recommended for unique cards: 0.10

White Text Detection:
  _WhiteTextThreshold (Range: 0.0-1.0, Default: 0.7)
    - Brightness threshold for white/light text detection
    - Lower = includes grays; Higher = only very bright whites

INTENSITY & ENHANCEMENT
========================

_RedIntensity (Range: 0.0-2.0, Default: 1.2)
  - Boost intensity of red text detection
  - Higher = red text detected more aggressively
  
_GoldIntensity (Range: 0.0-2.0, Default: 1.1)
  - Boost intensity of gold text detection
  - Higher = gold text detected more aggressively
  
_TextEnhance (Range: 0.0-2.0, Default: 1.3)
  - Color enhancement for detected text in final output
  - Higher = more vibrant/saturated text colors
  - Recommended for unique cards: 1.5


PARALLAX & DEPTH EFFECT
========================

_ParallaxStrength (Range: 0.0-1.0, Default: 0.5)
  - Overall intensity of the parallax background movement
  - 0.0 = no movement (static background)
  - 1.0 = maximum parallax effect
  
_ParallaxDistance (Range: -0.1 to 0.1, Default: 0.05)
  - How far the background shifts in pixels
  - Negative values shift in opposite direction
  - Typical range: 0.03-0.08 for subtle effects
  - Recommended for unique cards: 0.05

_SmoothingRadius (Range: 1-10, Default: 3.0)
  - Smoothing applied to text detection regions
  - Higher = smoother text edges, more blurred detection
  - Lower = sharper text detection, more noise
  - Recommended: 2.0-4.0


EDGE & CONTRAST DETECTION
==========================

_EdgeThreshold (Range: 0.0-1.0, Default: 0.3)
  - Sensitivity for edge detection (Sobel operator)
  - Lower = more edges detected (including noise)
  - Higher = only strong edges detected (cleaner but misses subtle text)
  - Recommended for unique cards: 0.25

_ContrastBoost (Range: 1.0-3.0, Default: 1.5)
  - Exponent applied to local contrast detection
  - Higher = emphasizes high-contrast text
  - Lower = more even detection across contrast ranges


TUNING TIPS FOR YOUR CARDS
===========================

1. START WITH DEFAULTS
   - Apply defaults and see how the shader performs on your card

2. ADJUST TEXT COLOR RANGES
   - If text isn't detected:
     * Lower _RedTextMin / _GoldTextMin to catch darker text
     * Increase _RedHueRange / _GoldHueRange for color tolerance
   
   - If too much background is detected as text:
     * Raise _RedTextMin / _GoldTextMin
     * Lower _RedHueRange / _GoldHueRange for stricter color matching

3. FINE-TUNE WITH INTENSITY
   - If text still faint: increase _TextEnhance
   - If false detections: lower _RedIntensity / _GoldIntensity

4. ADJUST PARALLAX
   - If background movement is too subtle: increase _ParallaxStrength
   - If too much movement: decrease _ParallaxStrength or _ParallaxDistance
   - If jittery: increase _SmoothingRadius

5. CREATE MATERIAL INSTANCES
   - Create unique material instances per card variant
   - Save your custom settings per instance
   - Allows different tuning for different card designs


EXAMPLE SETTINGS FOR UNIQUE CARDS (From Frequency Ghost & Chaos Architect)
===========================================================================

_RedTextMin: 0.5
_RedTextMax: 1.0
_RedHueRange: 0.05

_GoldTextMin: 0.35
_GoldTextMax: 0.95
_GoldHueRange: 0.10

_WhiteTextThreshold: 0.7
_EdgeThreshold: 0.25

_ParallaxStrength: 0.5
_ParallaxDistance: 0.05
_SmoothingRadius: 3.0

_ContrastBoost: 1.5
_TextEnhance: 1.5


TROUBLESHOOTING
===============

Text not being detected:
  - Lower the _Min thresholds
  - Increase _HueRange values
  - Increase _Intensity values
  - Lower _EdgeThreshold

Too much background detected as text:
  - Raise _Min thresholds
  - Lower _HueRange values
  - Lower _Intensity values
  - Increase _EdgeThreshold

Parallax looks stuttery:
  - Increase _SmoothingRadius
  - Decrease _ParallaxDistance

Text colors washed out:
  - Increase _TextEnhance
  - Lower the _Max thresholds to strengthen color detection

Parallax too subtle:
  - Increase _ParallaxStrength
  - Increase _ParallaxDistance
