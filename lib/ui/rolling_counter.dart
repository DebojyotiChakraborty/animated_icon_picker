import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'picker_spec.dart';

/// "01 / 06" counter. Only the digits that change roll: upwards when the
/// value increases, downwards when it decreases, blurring at the crossover.
class RollingCounter extends StatefulWidget {
  const RollingCounter({super.key, required this.value, required this.total});

  /// One-based value shown in the big digits.
  final int value;
  final int total;

  @override
  State<RollingCounter> createState() => _RollingCounterState();
}

class _RollingCounterState extends State<RollingCounter> {
  int _direction = 1;

  @override
  void didUpdateWidget(RollingCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _direction = widget.value > oldWidget.value ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = widget.value.toString().padLeft(2, '0');
    final total = widget.total.toString().padLeft(2, '0');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        for (var i = 0; i < digits.length; i++)
          _RollingDigit(digit: digits[i], direction: _direction),
        const SizedBox(width: PickerSpec.counterGap),
        Transform.translate(
          offset: const Offset(0, PickerSpec.counterSmallDrop),
          child: Text('/ $total', style: PickerText.counterSmall),
        ),
      ],
    );
  }
}

class _RollingDigit extends StatefulWidget {
  const _RollingDigit({required this.digit, required this.direction});

  final String digit;
  final int direction;

  @override
  State<_RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<_RollingDigit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PickerSpec.counterDuration,
    value: 1,
  );
  String? _previous;

  @override
  void didUpdateWidget(_RollingDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.digit != oldWidget.digit) {
      _previous = oldWidget.digit;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = PickerSpec.counterCurve.transform(_controller.value);
        final travel = PickerSpec.counterTravel * widget.direction;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (_previous != null && t < 1)
              Positioned.fill(child: _layer(_previous!, -travel * t, 1 - t)),
            _layer(widget.digit, travel * (1 - t), t),
          ],
        );
      },
    );
  }

  Widget _layer(String digit, double dy, double opacity) {
    final sigma = PickerSpec.counterBlurMax * (1 - opacity);
    Widget text = Text(digit, style: PickerText.counterBig);
    if (sigma > 0.01) {
      text = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: text,
      );
    }
    return Transform.translate(
      offset: Offset(0, dy),
      child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: text),
    );
  }
}
