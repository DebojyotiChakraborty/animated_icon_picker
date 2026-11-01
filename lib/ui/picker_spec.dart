import 'package:flutter/widgets.dart';

/// Measured constants for the icon picker, in logical pixels.
///
/// Every value comes from docs/animation_analysis.md (402 x 874 pt reference).
abstract final class PickerSpec {
  // Sheet
  static const double sheetInset = 8;
  static const double sheetHeight = 417;
  static const double sheetTopRadius = 35;
  static const double sheetBottomRadius = 52;
  static const Color sheetColor = Color(0xFFDEDDE2);
  static const Color sheetTopHighlight = Color(0xFFEAE9EE);
  static const Color sheetHairline = Color(0x2E000000);
  static const double scrimOpacity = 0.22;
  static final SpringDescription openSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 272, ratio: 0.97);
  static final SpringDescription closeSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 335, ratio: 1);
  static const double maxStretch = 77;
  static const double iconGrowthPerStretch = 0.46;
  static const Duration autoDismissDelay = Duration(milliseconds: 300);

  // Close button
  static const double closeSize = 44;
  static const double closeInset = 13;
  static const Color closeFill = Color(0xFFEEEDF1);

  // Counter
  static const double counterBaseline = 38.8;
  static const double counterGap = 3;
  static const double counterSmallDrop = 2.6;
  static const Color accent = Color(0xFF007AFF);
  static const Color counterSmallColor = Color(0xFF737277);
  static const Duration counterDuration = Duration(milliseconds: 260);
  static const Curve counterCurve = Curves.easeOutCubic;
  static const double counterTravel = 11;
  static const double counterBlurMax = 3;

  // Centre icon
  static const double iconSize = 135;
  static const double iconCenterY = 148.6;
  static const double iconCornerRadius = 30;

  // Name label and caption
  static const double nameBaseline = 252.1;
  static const double labelTravel = 148;
  static const double captionFirstBaseline = 300.2;
  static const Color captionColor = Color(0xFF646267);
  static const String caption =
      'Choose a look for your home screen. You can switch back to any icon at any time.';

  // Button
  static const double buttonHeight = 46;
  static const double buttonSideInset = 28;
  static const double buttonBottomGap = 22.4;
  static const Color buttonActiveFill = accent;
  static const Color buttonPressedFill = Color(0xFF008DFE);
  static const Color buttonDisabledFill = Color(0xFFCFCED3);
  static const Color buttonDisabledText = Color(0xFF77767B);
  static const double buttonPressedScale = 1.055;
  static const Duration buttonPressIn = Duration(milliseconds: 120);
  static const Duration buttonPressOut = Duration(milliseconds: 90);
  static const Duration buttonColorDuration = Duration(milliseconds: 220);
  static const Duration buttonTextOut = Duration(milliseconds: 120);
  static const Duration buttonTextIn = Duration(milliseconds: 250);

  // Carousel
  static const Offset neighbourOffset = Offset(157.7, -63.4);
  static const Offset arcBulge = Offset(68.2, 49.3);
  static const double neighbourScale = 0.705;
  static const double neighbourRotationDeg = -69.3;
  static const double neighbourBlurSigma = 3.5;
  static final SpringDescription pageSettleSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 225, ratio: 1);
}

/// Shared text styles. The reference uses SF Pro / SF Mono; on iOS the
/// default family is already SF Pro, and Menlo stands in for SF Mono.
abstract final class PickerText {
  static const List<String> mono = ['Menlo', 'RobotoMono', 'monospace'];

  static const TextStyle counterBig = TextStyle(
    fontFamily: 'Menlo',
    fontFamilyFallback: mono,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: PickerSpec.accent,
    height: 1,
  );

  static const TextStyle counterSmall = TextStyle(
    fontFamily: 'Menlo',
    fontFamilyFallback: mono,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: PickerSpec.counterSmallColor,
    height: 1,
  );

  static const TextStyle name = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
    height: 1,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 23.8 / 15,
    color: PickerSpec.captionColor,
  );

  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
  );
}
