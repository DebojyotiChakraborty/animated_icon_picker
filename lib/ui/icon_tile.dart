import 'package:flutter/widgets.dart';

import 'picker_spec.dart';

/// A full-bleed icon image clipped to a continuous-corner (squircle) shape,
/// matching how the home screen masks app icons.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.assetPath, required this.size});

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * PickerSpec.iconCornerRadius / PickerSpec.iconSize;
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
      ),
    );
  }
}
