import 'package:flutter/services.dart';

/// One selectable app icon.
class AppIconOption {
  /// Stable id shared with the native side ("default", "blush", ...).
  final String id;

  /// Display name shown in the picker.
  final String name;

  /// 1024x1024 full-bleed square artwork (no rounded corners, no alpha).
  final String assetPath;

  const AppIconOption({
    required this.id,
    required this.name,
    required this.assetPath,
  });

  /// Transparent glyph-only artwork, same canvas size as [assetPath].
  String get glyphAssetPath => 'assets/icons/${id}_glyph.png';
}

/// All icons, in picker order. The first one is the default icon.
const List<AppIconOption> kAppIcons = [
  AppIconOption(
    id: 'default',
    name: 'Default',
    assetPath: 'assets/icons/default.png',
  ),
  AppIconOption(
    id: 'blush',
    name: 'Blush',
    assetPath: 'assets/icons/blush.png',
  ),
  AppIconOption(
    id: 'grape',
    name: 'Grape',
    assetPath: 'assets/icons/grape.png',
  ),
  AppIconOption(
    id: 'midnight',
    name: 'Midnight',
    assetPath: 'assets/icons/midnight.png',
  ),
  AppIconOption(id: 'mono', name: 'Mono', assetPath: 'assets/icons/mono.png'),
  AppIconOption(
    id: 'ocean',
    name: 'Ocean',
    assetPath: 'assets/icons/ocean.png',
  ),
];

/// Switches the home screen icon through the native
/// "animated_icon_picker/app_icon" method channel.
///
/// iOS uses alternate app icons (the system shows its own confirmation
/// alert). Android toggles one launcher `<activity-alias>` per icon; some
/// launchers only refresh the icon after a short delay.
class AppIconService {
  AppIconService._();

  static const MethodChannel _channel = MethodChannel(
    'animated_icon_picker/app_icon',
  );

  /// Whether this platform can change the app icon. False where the native
  /// channel is missing (tests, web, desktop).
  static Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The id of the active icon, or 'default' if it cannot be determined.
  static Future<String> getCurrent() async {
    try {
      return await _channel.invokeMethod<String>('getCurrent') ?? 'default';
    } on MissingPluginException {
      return 'default';
    }
  }

  /// Switches to the icon with [id]. Completes once the platform has applied
  /// the change; throws a [PlatformException] if it fails. Does nothing where
  /// the native channel is missing.
  static Future<void> setIcon(String id) async {
    try {
      await _channel.invokeMethod<void>('setIcon', id);
    } on MissingPluginException {
      return;
    }
  }
}
