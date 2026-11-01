import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:animated_icon_picker/ui/carousel_math.dart';
import 'package:animated_icon_picker/ui/picker_spec.dart';

void main() {
  test('centre item is untransformed', () {
    expect(carouselOffset(0), Offset.zero);
    expect(carouselScale(0), 1);
    expect(carouselRotation(0), 0);
    expect(carouselBlur(0), 0);
  });

  test('neighbours rest at the measured pose', () {
    expect(carouselOffset(1), PickerSpec.neighbourOffset);
    expect(carouselOffset(-1), -PickerSpec.neighbourOffset);
    expect(carouselScale(-1), closeTo(0.705, 1e-9));
    expect(carouselRotation(1), closeTo(-69.3 * math.pi / 180, 1e-9));
    expect(carouselRotation(-1), carouselRotation(1));
    expect(carouselBlur(1), 3.5);
  });

  test('items travel on an arc between pages', () {
    final half = carouselOffset(0.5);
    final straight = PickerSpec.neighbourOffset * 0.5;
    expect((half - straight).distance, greaterThan(10));
  });

  test('effects hold beyond the neighbours', () {
    expect(carouselScale(2), carouselScale(1));
    expect(carouselOffset(2), PickerSpec.neighbourOffset * 2);
  });

  test('label fades out at the half-page crossover', () {
    expect(labelOpacity(0), 1);
    expect(labelOpacity(0.5), 0);
    expect(nearestDelta(2.3, 6), closeTo(-0.3, 1e-9));
    expect(nearestDelta(-0.4, 6), closeTo(0.4, 1e-9));
  });
}
