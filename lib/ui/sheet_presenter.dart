import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'picker_spec.dart';

typedef SheetBuilder = Widget Function(
  BuildContext context,
  double stretch,
  VoidCallback close,
);

/// Presents a floating bottom sheet over [child] with the measured springs:
/// it rises from just below the screen, can be dragged down to dismiss, and
/// rubber-bands taller when pulled up. The scrim tracks the sheet position.
class SheetPresenter extends StatefulWidget {
  const SheetPresenter({
    super.key,
    required this.child,
    required this.sheetBuilder,
  });

  final Widget child;
  final SheetBuilder sheetBuilder;

  @override
  State<SheetPresenter> createState() => SheetPresenterState();
}

class SheetPresenterState extends State<SheetPresenter>
    with SingleTickerProviderStateMixin {
  static const double _hidden = PickerSpec.sheetHeight + PickerSpec.sheetInset;

  /// Sheet offset below its resting place. Negative values are an upward
  /// over-drag, shown as extra sheet height.
  late final AnimationController _y = AnimationController.unbounded(
    vsync: this,
    value: _hidden,
  );
  bool _visible = false;
  bool _closing = false;
  double _dragRaw = 0;

  bool get isOpen => _visible && !_closing;

  void open() {
    if (isOpen) return;
    setState(() {
      _visible = true;
      _closing = false;
    });
    _y.animateWith(SpringSimulation(PickerSpec.openSpring, _y.value, 0, 0));
  }

  Future<void> close({double velocity = 0}) async {
    if (!_visible || _closing) return;
    _closing = true;
    await _y.animateWith(
      SpringSimulation(
        PickerSpec.closeSpring,
        _y.value,
        _hidden + 10,
        velocity,
      ),
    );
    if (mounted && _closing) {
      setState(() {
        _visible = false;
        _closing = false;
      });
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (_closing) return;
    _y.stop();
    _dragRaw = _y.value;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_closing) return;
    _dragRaw += details.delta.dy;
    _y.value = _dragRaw >= 0 ? _dragRaw : -_rubberBand(-_dragRaw);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_closing) return;
    final velocity = details.primaryVelocity ?? 0;
    final y = _y.value;
    if (y > 0 && (velocity > 800 || (y > 120 && velocity > -200))) {
      close(velocity: velocity);
    } else {
      _y.animateWith(SpringSimulation(PickerSpec.openSpring, y, 0, velocity));
    }
  }

  /// UIScrollView-style rubber band, capped at the measured maximum stretch.
  static double _rubberBand(double distance) {
    const d = PickerSpec.maxStretch;
    return (1 - 1 / (distance * 0.55 / d + 1)) * d;
  }

  @override
  void dispose() {
    _y.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: Stack(
        children: [
          widget.child,
          if (_visible) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: close,
                child: AnimatedBuilder(
                  animation: _y,
                  builder: (context, _) {
                    final shown = 1 - (_y.value / _hidden).clamp(0.0, 1.0);
                    return ColoredBox(
                      color: Colors.black.withValues(
                        alpha: PickerSpec.scrimOpacity * shown,
                      ),
                    );
                  },
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _y,
              builder: (context, _) {
                final y = _y.value;
                final stretch = y < 0 ? -y : 0.0;
                return Positioned(
                  left: PickerSpec.sheetInset,
                  right: PickerSpec.sheetInset,
                  bottom: PickerSpec.sheetInset - (y > 0 ? y : 0),
                  height: PickerSpec.sheetHeight + stretch,
                  child: GestureDetector(
                    onVerticalDragStart: _onDragStart,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: widget.sheetBuilder(context, stretch, close),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
