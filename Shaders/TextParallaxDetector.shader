Shader "VRChat/TextParallaxDetector"
{
    Properties
    {
        _MainTex ("Image Texture", 2D) = "white" {}
        
        // Text Color Detection
        _RedTextMin ("Red Text Min Threshold", Range(0.0, 1.0)) = 0.5
        _RedTextMax ("Red Text Max Threshold", Range(0.0, 1.0)) = 1.0
        _RedIntensity ("Red Channel Intensity", Range(0.0, 2.0)) = 1.2
        
        _GoldTextMin ("Gold Text Min Threshold", Range(0.0, 1.0)) = 0.4
        _GoldTextMax ("Gold Text Max Threshold", Range(0.0, 1.0)) = 0.9
        _GoldIntensity ("Gold Channel Intensity", Range(0.0, 2.0)) = 1.1
        
        _WhiteTextThreshold ("White Text Threshold", Range(0.0, 1.0)) = 0.7
        
        // Color Range Tuning (HSV-based detection)
        _RedHueRange ("Red Hue Range", Range(0.0, 0.1)) = 0.05
        _GoldHueRange ("Gold Hue Range", Range(0.0, 0.2)) = 0.12
        
        _EdgeThreshold ("Edge Detection Threshold", Range(0.0, 1.0)) = 0.3
        _ParallaxStrength ("Parallax Strength", Range(0.0, 1.0)) = 0.5
        _ParallaxDistance ("Parallax Distance", Range(-0.1, 0.1)) = 0.05
        _SmoothingRadius ("Text Smoothing Radius", Range(1, 10)) = 3.0
        _ContrastBoost ("Contrast Boost", Range(1.0, 3.0)) = 1.5
        _TextEnhance ("Text Color Enhancement", Range(0.0, 2.0)) = 1.3
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            // Red text properties
            float _RedTextMin;
            float _RedTextMax;
            float _RedIntensity;
            float _RedHueRange;
            
            // Gold text properties
            float _GoldTextMin;
            float _GoldTextMax;
            float _GoldIntensity;
            float _GoldHueRange;
            
            // White text properties
            float _WhiteTextThreshold;
            
            // Effect properties
            float _EdgeThreshold;
            float _ParallaxStrength;
            float _ParallaxDistance;
            float _SmoothingRadius;
            float _ContrastBoost;
            float _TextEnhance;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            // Convert RGB to HSV
            float3 RGBtoHSV(float3 rgb)
            {
                float maxc = max(max(rgb.r, rgb.g), rgb.b);
                float minc = min(min(rgb.r, rgb.g), rgb.b);
                float v = maxc;
                
                float delta = maxc - minc;
                float s = maxc > 0.0 ? delta / maxc : 0.0;
                
                float h = 0.0;
                if (delta != 0.0)
                {
                    if (maxc == rgb.r)
                        h = fmod((rgb.g - rgb.b) / delta, 6.0) / 6.0;
                    else if (maxc == rgb.g)
                        h = ((rgb.b - rgb.r) / delta + 2.0) / 6.0;
                    else
                        h = ((rgb.r - rgb.g) / delta + 4.0) / 6.0;
                }
                
                return float3(h, s, v);
            }
            
            // Detect red text by color range
            float DetectRedText(float3 rgb, float3 hsv)
            {
                // Red hue is around 0.0 (wraps around)
                float hueDistance = min(abs(hsv.x - 0.0), min(abs(hsv.x - 1.0), 1.0 - abs(hsv.x)));
                float hueMatch = smoothstep(_RedHueRange, 0.0, hueDistance);
                
                // Check saturation and value ranges for red text
                float satMatch = smoothstep(_RedTextMin - 0.2, _RedTextMin, hsv.y) * 
                                smoothstep(_RedTextMax + 0.1, _RedTextMax, hsv.y);
                float valMatch = smoothstep(_RedTextMin - 0.1, _RedTextMin, hsv.z) *
                                smoothstep(_RedTextMax, _RedTextMax - 0.1, hsv.z);
                
                // Direct red channel check
                float redDominance = rgb.r > (rgb.g + rgb.b) * 0.5 ? 1.0 : 0.0;
                
                return max(hueMatch * satMatch * valMatch, redDominance * rgb.r);
            }
            
            // Detect gold/tan text by color range
            float DetectGoldText(float3 rgb, float3 hsv)
            {
                // Gold hue is around 0.08-0.15 (yellow-orange range)
                float goldHue = 0.12;
                float hueDistance = abs(hsv.x - goldHue);
                float hueMatch = smoothstep(_GoldHueRange, 0.0, hueDistance);
                
                // Check saturation and value for gold
                float satMatch = smoothstep(_GoldTextMin - 0.1, _GoldTextMin, hsv.y) *
                                smoothstep(_GoldTextMax + 0.1, _GoldTextMax, hsv.y);
                float valMatch = smoothstep(_GoldTextMin, _GoldTextMax, hsv.z);
                
                // Direct channel check for gold (high R+G, lower B)
                float goldDominance = (rgb.r + rgb.g) > rgb.b * 1.5 && rgb.r > 0.3 ? 1.0 : 0.0;
                
                return max(hueMatch * satMatch * valMatch, goldDominance * (rgb.r + rgb.g) * 0.5);
            }
            
            // Detect white/light text
            float DetectWhiteText(float3 rgb, float3 hsv)
            {
                // White has low saturation and high value
                float isWhite = step(_WhiteTextThreshold, hsv.z) * smoothstep(0.3, 0.0, hsv.y);
                
                // Also check if all channels are similarly high
                float channelBalance = 1.0 - (abs(rgb.r - rgb.g) + abs(rgb.g - rgb.b) + abs(rgb.b - rgb.r)) / 3.0;
                
                return max(isWhite, channelBalance * hsv.z);
            }
            
            // Combined text detection using color ranges
            float DetectColoredText(float2 uv)
            {
                float4 texel = tex2D(_MainTex, uv);
                float3 rgb = texel.rgb;
                float3 hsv = RGBtoHSV(rgb);
                
                float redScore = DetectRedText(rgb, hsv);
                float goldScore = DetectGoldText(rgb, hsv);
                float whiteScore = DetectWhiteText(rgb, hsv);
                
                // Combine all text detection methods
                float textScore = max(max(redScore, goldScore), whiteScore);
                
                return textScore;
            }
            
            // Edge detection using Sobel operator
            float EdgeDetection(float2 uv, float pixelSize)
            {
                float sobelX = 0.0;
                float sobelY = 0.0;
                
                float sobel[9] = {
                    -1, 0, 1,
                    -2, 0, 2,
                    -1, 0, 1
                };
                
                float sobelY_kernel[9] = {
                    -1, -2, -1,
                    0, 0, 0,
                    1, 2, 1
                };
                
                for(int i = 0; i < 3; i++)
                {
                    for(int j = 0; j < 3; j++)
                    {
                        float2 offset = float2((i - 1) * pixelSize, (j - 1) * pixelSize);
                        float4 texel = tex2D(_MainTex, uv + offset);
                        float gray = dot(texel.rgb, float3(0.299, 0.587, 0.114));
                        
                        sobelX += gray * sobel[i * 3 + j];
                        sobelY += gray * sobelY_kernel[i * 3 + j];
                    }
                }
                
                return sqrt(sobelX * sobelX + sobelY * sobelY);
            }
            
            // Hybrid text detection: color + edge + contrast
            float DetectText(float2 uv, float pixelSize)
            {
                float colorScore = DetectColoredText(uv);
                float edgeScore = EdgeDetection(uv, pixelSize);
                edgeScore = smoothstep(_EdgeThreshold - 0.1, _EdgeThreshold + 0.1, edgeScore);
                
                // Local contrast detection
                float4 center = tex2D(_MainTex, uv);
                float centerGray = dot(center.rgb, float3(0.299, 0.587, 0.114));
                
                float contrast = 0.0;
                int samples = 4;
                for(int i = 0; i < samples; i++)
                {
                    float angle = (float(i) / float(samples)) * 6.28318;
                    float2 offset = float2(cos(angle), sin(angle)) * pixelSize * 2.0;
                    float4 neighbor = tex2D(_MainTex, uv + offset);
                    float neighborGray = dot(neighbor.rgb, float3(0.299, 0.587, 0.114));
                    contrast += abs(centerGray - neighborGray);
                }
                contrast /= float(samples);
                contrast = pow(contrast, _ContrastBoost);
                
                // Combine: color detection is primary, edges and contrast support it
                return max(colorScore, max(edgeScore * 0.6, contrast * 0.4));
            }
            
            // Apply median filter for text region smoothing
            float MedianFilter(float2 uv, float pixelSize)
            {
                float values[9];
                
                for(int i = 0; i < 3; i++)
                {
                    for(int j = 0; j < 3; j++)
                    {
                        float2 offset = float2((i - 1) * pixelSize, (j - 1) * pixelSize);
                        values[i * 3 + j] = DetectText(uv + offset, pixelSize);
                    }
                }
                
                // Simple sort for median
                for(int i = 0; i < 9; i++)
                {
                    for(int j = i + 1; j < 9; j++)
                    {
                        if(values[j] < values[i])
                        {
                            float temp = values[i];
                            values[i] = values[j];
                            values[j] = temp;
                        }
                    }
                }
                
                return values[4];
            }
            
            // Apply parallax offset based on depth perception
            float2 ApplyParallax(float2 uv, float textMask)
            {
                float2 parallaxOffset = textMask > 0.5 ? float2(0, 0) : 
                    float2(sin(_Time.y * 0.5) * _ParallaxDistance, 
                            cos(_Time.y * 0.3) * _ParallaxDistance) * _ParallaxStrength;
                return uv + parallaxOffset;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float pixelSize = 1.0 / 512.0;
                
                // Detect text regions with color awareness
                float textMask = MedianFilter(i.uv, pixelSize * _SmoothingRadius);
                textMask = smoothstep(0.2, 0.8, textMask);
                
                // Apply parallax to background only
                float2 parallaxUV = ApplyParallax(i.uv, textMask);
                float4 texColor = tex2D(_MainTex, parallaxUV);
                float4 textColor = tex2D(_MainTex, i.uv);
                
                // Enhance text layer with detected colors
                float4 result = lerp(texColor, textColor, textMask);
                
                // Boost text colors without oversaturation
                result.rgb = lerp(result.rgb, 
                                 normalize(textColor.rgb + float3(0.1, 0.1, 0.1)) * _TextEnhance,
                                 textMask * 0.4);
                
                return result;
            }
            ENDCG
        }
    }
    FallBack "Standard"
}
