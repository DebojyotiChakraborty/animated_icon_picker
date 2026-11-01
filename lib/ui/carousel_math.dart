import 'dart:math' as math;
import 'dart:ui';

import 'picker_spec.dart';

/// Pure mapping from an item's page delta `p = itemIndex - page` to how it is
/// drawn. Icons have no time-based animation: they only follow the scroll.

double _t(double p) => p.abs().clamp(0.0, 1.0);

/// Offset of the icon centre from the resting centre. Items travel on an arc
/// between pages and continue in a straight line beyond the neighbours.
Offset carouselOffset(double p) {
  final a = p.abs();
  if (a >= 1) return PickerSpec.neighbourOffset * p;
  return PickerSpec.neighbourOffset * p + PickerSpec.arcBulge * (p * (1 - a));
}

double carouselScale(double p) => 1 - (1 - PickerSpec.neighbourScale) * _t(p);

/// Rotation in radians. Both sides turn counter-clockwise.
double carouselRotation(double p) =>
    PickerSpec.neighbourRotationDeg * _t(p) * math.pi / 180;

double carouselBlur(double p) => PickerSpec.neighbourBlurSigma * _t(p);

/// Signed distance of the nearest item from the centre, in [-0.5, 0.5].
double nearestDelta(double page, int count) {
  final index = page.round().clamp(0, count - 1);
  return (index - page).clamp(-0.5, 0.5);
}

/// Name label fade as the nearest item moves away from the centre.
double labelOpacity(double pc) =>
    1 - math.pow((2 * pc.abs()).clamp(0.0, 1.0), 1.3).toDouble();
