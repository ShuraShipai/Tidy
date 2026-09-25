import Flutter
import Foundation

final class SettingsNativeService {
  private let channelName = "tidy/settings"
  private let defaults = UserDefaults.standard

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(FlutterError(code: "unavailable", message: "Settings are unavailable.", details: nil)); return }
      switch call.method {
      case "readPreferences": result(self.preferences())
      case "savePreferences":
        guard let values = call.arguments as? [String: Any] else {
          result(FlutterError(code: "invalid_arguments", message: "Scan preferences are invalid.", details: nil)); return
        }
        if let includeScreenshots = values["includeScreenshots"] as? Bool {
          self.defaults.set(includeScreenshots, forKey: "tidy.includeScreenshots")
        }
        if let includeLargeVideos = values["includeLargeVideos"] as? Bool {
          self.defaults.set(includeLargeVideos, forKey: "tidy.includeLargeVideos")
        }
        if let sensitivity = values["sensitivity"] as? String,
          ["strict", "balanced", "broad"].contains(sensitivity) {
          self.defaults.set(sensitivity, forKey: "tidy.photoSensitivity")
        }
        result(self.preferences())
      case "appVersion":
        let info = Bundle.main.infoDictionary ?? [:]
        result(["version": info["CFBundleShortVersionString"] as? String ?? "",
                "build": info["CFBundleVersion"] as? String ?? ""])
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  private func preferences() -> [String: Any] {
    ["includeScreenshots": defaults.object(forKey: "tidy.includeScreenshots") as? Bool ?? true,
     "includeLargeVideos": defaults.object(forKey: "tidy.includeLargeVideos") as? Bool ?? true,
     "sensitivity": defaults.string(forKey: "tidy.photoSensitivity") ?? "balanced"]
  }
}
