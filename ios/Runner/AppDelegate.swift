import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    AppIconChannel.register(with: engineBridge.applicationRegistrar.messenger())
  }
}

/// Handles "animated_icon_picker/app_icon": switches between the icon sets
/// declared in ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES.
enum AppIconChannel {
  static let name = "animated_icon_picker/app_icon"

  /// Dart icon id -> alternate icon set name. "default" maps to nil (AppIcon).
  private static let alternateNames: [String: String] = [
    "blush": "AppIcon-Blush",
    "grape": "AppIcon-Grape",
    "midnight": "AppIcon-Midnight",
    "mono": "AppIcon-Mono",
    "ocean": "AppIcon-Ocean",
  ]

  private static var channel: FlutterMethodChannel?

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler(handle)
    self.channel = channel
  }

  private static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let app = UIApplication.shared
    switch call.method {
    case "isSupported":
      result(app.supportsAlternateIcons)
    case "getCurrent":
      result(id(forAlternateName: app.alternateIconName))
    case "setIcon":
      guard let id = call.arguments as? String
        ?? (call.arguments as? [String: Any])?["id"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "Expected an icon id", details: nil))
        return
      }
      setIcon(id, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func setIcon(_ id: String, result: @escaping FlutterResult) {
    let app = UIApplication.shared
    guard app.supportsAlternateIcons else {
      result(FlutterError(
        code: "unsupported", message: "Alternate icons are not supported", details: nil))
      return
    }
    let target: String?
    if id == "default" {
      target = nil
    } else if let name = alternateNames[id] {
      target = name
    } else {
      result(FlutterError(code: "unknown_icon", message: "Unknown icon id: \(id)", details: nil))
      return
    }
    if app.alternateIconName == target {
      result(nil)
      return
    }
    // iOS shows its own "You have changed the icon" alert after this call.
    app.setAlternateIconName(target) { error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(
            code: "set_icon_failed", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    }
  }

  private static func id(forAlternateName name: String?) -> String {
    guard let name = name else { return "default" }
    return alternateNames.first { $0.value == name }?.key ?? "default"
  }
}
