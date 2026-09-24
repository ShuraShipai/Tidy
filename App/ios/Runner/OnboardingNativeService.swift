import Contacts
import Flutter
import Photos
import PhotosUI
import UIKit

/// No enumeration, cloud retrieval, or mutation of Photos/Contacts occurs here.
final class OnboardingNativeService {
  private var channel: FlutterMethodChannel?
  private let contactStore = CNContactStore()
  private var requesting = false
  private let storageDirectory: URL?

  init(storageDirectory: URL? = nil) {
    self.storageDirectory = storageDirectory
  }

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "tidy/onboarding", binaryMessenger: messenger)
    self.channel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      self.handle(call, result: result)
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "status", "request":
      guard let subject = call.arguments as? String,
            subject == "photos" || subject == "contacts" else {
        result(FlutterError(code: "invalid_subject", message: "Unknown permission", details: nil))
        return
      }
      if call.method == "status" { result(status(subject)); return }
      guard !requesting else {
        result(FlutterError(code: "busy", message: "A permission request is active", details: nil))
        return
      }
      guard status(subject) == "notDetermined" else { result(status(subject)); return }
      requesting = true
      if subject == "photos" {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
          DispatchQueue.main.async {
            self.requesting = false
            result(self.status(subject))
          }
        }
      } else {
        contactStore.requestAccess(for: .contacts) { _, error in
          DispatchQueue.main.async {
            self.requesting = false
            if error != nil && self.status(subject) == "notDetermined" {
              result(FlutterError(code: "request_failed", message: "Contacts authorization failed", details: nil))
            } else { result(self.status(subject)) }
          }
        }
      }
    case "managePhotos":
      guard status("photos") == "limited" else { result(nil); return }
      guard !requesting, let presenter = presenter(), presenter.presentedViewController == nil else {
        result(FlutterError(code: "unavailable", message: "Cannot present Photos picker", details: nil))
        return
      }
      requesting = true
      PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: presenter) { _ in
        DispatchQueue.main.async {
          self.requesting = false
          result(nil)
        }
      }
    case "openSettings":
      guard let url = URL(string: UIApplication.openSettingsURLString) else { result(false); return }
      UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
    case "readCompleted":
      do {
        let url = try completionURL(create: false)
        do { result(try Data(contentsOf: url) == Data([1])) }
        catch CocoaError.fileReadNoSuchFile { result(false) }
      } catch {
        result(FlutterError(code: "storage_read", message: "Cannot read onboarding completion", details: nil))
      }
    case "saveCompleted":
      do {
        let url = try completionURL(create: true)
        try Data([1]).write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        result(nil)
      } catch {
        result(FlutterError(code: "storage_write", message: "Cannot save onboarding completion", details: nil))
      }
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func status(_ subject: String) -> String {
    if subject == "photos" {
      switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
      case .notDetermined: return "notDetermined"
      case .authorized: return "granted"
      case .limited: return "limited"
      case .denied: return "denied"
      case .restricted: return "restricted"
      @unknown default: return "unsupported"
      }
    }
    let value = CNContactStore.authorizationStatus(for: .contacts)
    if #available(iOS 18.0, *), value == .limited { return "limited" }
    switch value {
    case .notDetermined: return "notDetermined"
    case .authorized: return "granted"
    case .denied: return "denied"
    case .restricted: return "restricted"
    default: return "unsupported"
    }
  }

  private func presenter() -> UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }?
      .windows.first { $0.isKeyWindow }?.rootViewController
  }

  private func completionURL(create: Bool) throws -> URL {
    let manager = FileManager.default
    let support = try manager.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                  appropriateFor: nil, create: create)
    var directory = storageDirectory ?? support.appendingPathComponent("TidyOnboarding", isDirectory: true)
    if create {
      try manager.createDirectory(at: directory, withIntermediateDirectories: true)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try directory.setResourceValues(values)
    }
    return directory.appendingPathComponent("completed-v1")
  }
}
