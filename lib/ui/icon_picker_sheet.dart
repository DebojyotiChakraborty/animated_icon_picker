import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_icon_service.dart';
import 'activate_button.dart';
import 'carousel_math.dart';
import 'icon_carousel.dart';
import 'picker_spec.dart';
import 'rolling_counter.dart';

/// Contents of the floating picker sheet: close button, counter, carousel,
/// name, caption and the activate button.
class IconPickerSheet extends StatefulWidget {
  const IconPickerSheet({
    super.key,
    required this.currentId,
    required this.stretch,
    required this.onClose,
    required this.onActivated,
  });

  /// Id of the icon in use on the home screen.
  final String currentId;

  /// Extra height from an upward over-drag; the icon grows with it.
  final double stretch;
  final VoidCallback onClose;
  final ValueChanged<String> onActivated;

  @override
  State<IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<IconPickerSheet> {
  late final PageController _controller;
  late int _index;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final current = kAppIcons.indexWhere((i) => i.id == widget.currentId);
    _index = current < 0 ? 0 : current;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  Future<void> _activate() async {
    final icon = kAppIcons[_index];
    setState(() => _busy = true);
    try {
      await AppIconService.setIcon(icon.id);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(e.message ?? 'The icon could not be changed.');
      return;
    }
    if (!mounted) return;
    widget.onActivated(icon.id);
    setState(() => _busy = false);
    await _waitForSystemAlert();
    await Future<void>.delayed(PickerSpec.autoDismissDelay);
    if (mounted) widget.onClose();
  }

  /// iOS confirms the change with its own alert, which makes the app inactive
  /// until it is dismissed. The sheet closes only after that.
  Future<void> _waitForSystemAlert() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return;
    }
    final resumed = Completer<void>();
    final listener = AppLifecycleListener(
      onResume: () {
        if (!resumed.isCompleted) resumed.complete();
      },
    );
    await resumed.future.timeout(const Duration(seconds: 30), onTimeout: () {});
    listener.dispose();
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Couldn’t Change Icon'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stretch = widget.stretch;
    const radius = BorderRadius.vertical(
      top: Radius.circular(PickerSpec.sheetTopRadius),
      bottom: Radius.circular(PickerSpec.sheetBottomRadius),
    );
    final isCurrent = kAppIcons[_index].id == widget.currentId;

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: PickerSpec.sheetColor,
        shape: const RoundedSuperellipseBorder(
          borderRadius: radius,
          side: BorderSide(color: PickerSpec.sheetHairline, width: 0.5),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 30,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRSuperellipse(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            IconCarousel(
              controller: _controller,
              icons: kAppIcons,
              iconSize:
                  PickerSpec.iconSize +
                  PickerSpec.iconGrowthPerStretch * stretch,
              iconCenterY: PickerSpec.iconCenterY + stretch / 2,
              onPageChanged: _onPageChanged,
            ),
            IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Baseline(
                  baseline: PickerSpec.counterBaseline,
                  baselineType: TextBaseline.alphabetic,
                  child: RollingCounter(
                    value: _index + 1,
                    total: kAppIcons.length,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Baseline(
                  baseline: PickerSpec.nameBaseline + stretch,
                  baselineType: TextBaseline.alphabetic,
                  child: _NameLabel(controller: _controller),
                ),
              ),
            ),
            IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Baseline(
                    baseline: PickerSpec.captionFirstBaseline + stretch,
                    baselineType: TextBaseline.alphabetic,
                    child: const Text(
                      PickerSpec.caption,
                      textAlign: TextAlign.center,
                      style: PickerText.caption,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: PickerSpec.buttonSideInset,
              right: PickerSpec.buttonSideInset,
              bottom: PickerSpec.buttonBottomGap,
              height: PickerSpec.buttonHeight,
              child: ActivateButton(
                isCurrent: isCurrent,
                onPressed: _busy ? null : _activate,
              ),
            ),
            Positioned(
              left: PickerSpec.closeInset,
              top: PickerSpec.closeInset,
              width: PickerSpec.closeSize,
              height: PickerSpec.closeSize,
              child: _CloseButton(onTap: widget.onClose),
            ),
          ],
        ),
      ),
    );
  }
}

/// Name of the nearest icon, sliding and fading with the scroll position.
class _NameLabel extends StatelessWidget {
  const _NameLabel({required this.controller});

  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = pageOf(controller);
        final index = page.round().clamp(0, kAppIcons.length - 1);
        final pc = nearestDelta(page, kAppIcons.length);
        return Transform.translate(
          offset: Offset(PickerSpec.labelTravel * pc, 0),
          child: Opacity(
            opacity: labelOpacity(pc),
            child: Text(kAppIcons[index].name, style: PickerText.name),
          ),
        );
      },
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: PickerSpec.closeFill,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 21,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
