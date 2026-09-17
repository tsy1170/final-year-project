import 'package:flutter/material.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

class MeshBackground extends StatelessWidget {
  const MeshBackground({super.key});

  @override
  Widget build(BuildContext context) {
    const Color color1 = Color(0xFFF2EBE4); // Warm Linen (Dominant Body)
    const Color color2 = Color(0xFFE8CFBF); // Muted Terracotta Tint (Bottom-Right)
    const Color color3 = Color(0xFFD3DFE2);

    return MeshGradient(
      points: [
        // 1. Top-Left Origin (pushed tighter into the corner)
        MeshGradientPoint(
          position: const Offset(0.0, 0.0),
          color: color3,
        ),
        // 2. Expanded Color 1 Area (occupies upper-middle)
        MeshGradientPoint(
          position: const Offset(0.25, 0.25),
          color: color1,
        ),
        // 3. Core Center (dominated by Color 1)
        MeshGradientPoint(
          position: const Offset(0.5, 0.5),
          color: color1,
        ),
        // 4. Upper-Right Extension (dominated by Color 1)
        MeshGradientPoint(
          position: const Offset(0.85, 0.2),
          color: color1,
        ),
        // 5. Lower-Left Extension (dominated by Color 1)
        MeshGradientPoint(
          position: const Offset(0.2, 0.85),
          color: color1,
        ),
        // 6. Bottom-Right Destination (pushed tighter into the corner)
        MeshGradientPoint(
          position: const Offset(1.0, 1.0),
          color: color2,
        ),
      ],
      options: MeshGradientOptions(
        blend: 4,
        noiseIntensity: 0,
      ),
    );
  }
}
