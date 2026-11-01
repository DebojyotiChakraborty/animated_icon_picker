import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'picker_spec.dart';

/// Capsule button that reads "Activate App Icon" (blue) or, for the icon in
/// use, "Currently Active" (grey, disabled). The fill crossfades and the
/// label swaps with a blur, scale and fade.
class ActivateButton extends StatefulWidget {
  const ActivateButton({
    super.key,
    required this.isCurrent,
    required this.onPressed,
  });

  final bool isCurrent;
  final VoidCallback? onPressed;

  @override
  State<ActivateButton> createState() => _ActivateButtonState();
}

class _ActivateButtonState extends State<ActivateButton> {
  bool _pressed = false;

  bool get _enabled => !widget.isCurrent && widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.isCurrent
        ? PickerSpec.buttonDisabledFill
        : _pressed
        ? PickerSpec.buttonPressedFill
        : PickerSpec.buttonActiveFill;
    final label = widget.isCurrent ? 'Currently Active' : 'Activate App Icon';
    final textColor = widget.isCurrent
        ? PickerSpec.buttonDisabledText
        : const Color(0xFFFFFFFF);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _enabled ? (_) => _setPressed(true) : null,
      onTapUp: _enabled ? (_) => _setPressed(false) : null,
      onTapCancel: () => _setPressed(false),
      onTap: _enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? PickerSpec.buttonPressedScale : 1,
        duration: _pressed
            ? PickerSpec.buttonPressIn
            : PickerSpec.buttonPressOut,
        curve: Curves.easeOut,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: fill),
          duration: _pressed
              ? PickerSpec.buttonPressIn
              : PickerSpec.buttonColorDuration,
          curve: Curves.easeInOut,
          builder: (context, color, child) => DecoratedBox(
            decoration: ShapeDecoration(
              color: color,
              shape: const StadiumBorder(),
            ),
            child: child,
          ),
          child: SizedBox(
            height: PickerSpec.buttonHeight,
            width: double.infinity,
            child: Center(
              child: AnimatedSwitcher(
                duration: PickerSpec.buttonTextIn,
                reverseDuration: PickerSpec.buttonTextOut,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: _blurScaleFade,
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: PickerText.button.copyWith(color: textColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _blurScaleFade(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        final sigma = 4 * (1 - t);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: lerpDouble(0.82, 1, t),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
