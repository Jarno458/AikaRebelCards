Shader "VRChat/TextParallaxDetector"
{
    Properties
    {
        _MainTex ("Image Texture", 2D) = "white" {}
        _TextColor ("Text Color", Color) = (1, 1, 1, 1)
        _BackgroundColor ("Background Color", Color) = (0.5, 0.5, 0.5, 1)
        _EdgeThreshold ("Edge Detection Threshold", Range(0.0, 1.0)) = 0.3
        _ParallaxStrength ("Parallax Strength", Range(0.0, 1.0)) = 0.5
        _ParallaxDistance ("Parallax Distance", Range(-0.1, 0.1)) = 0.05
        _SmoothingRadius ("Text Smoothing Radius", Range(1, 10)) = 3.0
        _ContrastBoost ("Contrast Boost", Range(1.0, 3.0)) = 1.5
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
                float3 worldPos : TEXCOORD1;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _TextColor;
            float4 _BackgroundColor;
            float _EdgeThreshold;
            float _ParallaxStrength;
            float _ParallaxDistance;
            float _SmoothingRadius;
            float _ContrastBoost;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }
            
            // Edge detection using Sobel operator
            float EdgeDetection(float2 uv, float pixelSize)
            {
                float sobelX = 0.0;
                float sobelY = 0.0;
                
                // Sobel kernel for edge detection
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
            
            // Detect text likelihood based on local contrast and edges
            float DetectText(float2 uv, float pixelSize)
            {
                float edge = EdgeDetection(uv, pixelSize);
                edge = smoothstep(_EdgeThreshold - 0.1, _EdgeThreshold + 0.1, edge);
                
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
                
                return max(edge, contrast * 0.5);
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
                
                // Simple sort for median (simplified for shader)
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
                float pixelSize = 1.0 / 512.0; // Adjust based on texture resolution
                
                // Detect text regions
                float textMask = MedianFilter(i.uv, pixelSize * _SmoothingRadius);
                textMask = smoothstep(0.3, 0.7, textMask);
                
                // Apply parallax to background
                float2 parallaxUV = ApplyParallax(i.uv, textMask);
                float4 texColor = tex2D(_MainTex, parallaxUV);
                
                // Separate text and background
                float4 textLayer = texColor;
                float4 backgroundLayer = texColor;
                
                // Enhance text visibility
                textLayer.rgb = lerp(texColor.rgb, _TextColor.rgb, textMask * 0.3);
                textLayer.rgb = normalize(textLayer.rgb) * lerp(1.0, 1.2, textMask);
                
                // Darken background slightly for depth
                backgroundLayer.rgb = lerp(backgroundLayer.rgb, _BackgroundColor.rgb, (1.0 - textMask) * 0.2);
                
                // Composite layers
                fixed4 finalColor = lerp(backgroundLayer, textLayer, textMask);
                
                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Standard"
}
