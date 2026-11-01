import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/app_icon_service.dart';
import 'carousel_math.dart';
import 'icon_tile.dart';
import 'picker_spec.dart';

/// Paging physics with the measured settle: a critically damped spring that
/// matches UIScrollView's fast deceleration (about 0.4 s, no overshoot).
class PickerPagePhysics extends PageScrollPhysics {
  const PickerPagePhysics({super.parent});

  @override
  PickerPagePhysics applyTo(ScrollPhysics? ancestor) =>
      PickerPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => PickerSpec.pageSettleSpring;
}

/// Current fractional page of [controller], falling back to its initial page
/// before the first layout.
double pageOf(PageController controller) {
  if (controller.hasClients && controller.position.haveDimensions) {
    return controller.page ?? controller.initialPage.toDouble();
  }
  return controller.initialPage.toDouble();
}

/// The swipeable icon carousel. An invisible [PageView] owns the gesture and
/// scroll position; the icons are drawn on top as a pure function of it.
class IconCarousel extends StatelessWidget {
  const IconCarousel({
    super.key,
    required this.controller,
    required this.icons,
    required this.iconSize,
    required this.iconCenterY,
    this.onPageChanged,
  });

  final PageController controller;
  final List<AppIconOption> icons;
  final double iconSize;
  final double iconCenterY;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: controller,
          physics: const PickerPagePhysics(parent: BouncingScrollPhysics()),
          itemCount: icons.length,
          onPageChanged: onPageChanged,
          itemBuilder: (_, _) => const SizedBox.expand(),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => _buildIcons(pageOf(controller)),
          ),
        ),
      ],
    );
  }

  Widget _buildIcons(double page) {
    final visible = <int>[
      for (var i = 0; i < icons.length; i++)
        if ((i - page).abs() < 2) i,
    ]..sort((a, b) => (b - page).abs().compareTo((a - page).abs()));

    return LayoutBuilder(
      builder: (context, constraints) {
        final centre = Offset(constraints.maxWidth / 2, iconCenterY);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final i in visible) _positioned(i, i - page, centre),
          ],
        );
      },
    );
  }

  Widget _positioned(int index, double p, Offset centre) {
    final position = centre + carouselOffset(p);
    final sigma = carouselBlur(p);
    Widget child = Transform.rotate(
      angle: carouselRotation(p),
      child: Transform.scale(
        scale: carouselScale(p),
        child: IconTile(assetPath: icons[index].assetPath, size: iconSize),
      ),
    );
    if (sigma > 0.01) {
      child = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.decal,
        ),
        child: child,
      );
    }
    return Positioned(
      key: ValueKey(index),
      left: position.dx - iconSize / 2,
      top: position.dy - iconSize / 2,
      width: iconSize,
      height: iconSize,
      child: child,
    );
  }
}
