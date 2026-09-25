import Flutter
import Photos
import UIKit

/// PhotoKit operations owned by the Photos review feature.
final class PhotoLibraryNativeService {
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "permissions":
      let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
      let value: String
      switch status {
      case .authorized: value = "authorized"
      case .limited: value = "limited"
      case .denied: value = "denied"
      case .restricted: value = "restricted"
      case .notDetermined: value = "notDetermined"
      @unknown default: value = "restricted"
      }
      result(value)
    case "thumbnail":
      guard
        let args = call.arguments as? [String: Any],
        let identifier = args["id"] as? String
      else {
        result(FlutterError(code: "invalid_arguments", message: "A photo identifier is required.", details: nil))
        return
      }
      guard canReadPhotos else {
        result(FlutterError(code: "photos_unavailable", message: "Photo access is unavailable.", details: nil))
        return
      }
      let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
      guard let asset = assets.firstObject, asset.mediaType == .image else {
        result(FlutterError(code: "photo_unavailable", message: "This photo is no longer available.", details: nil))
        return
      }
      let width = max(96, min((args["width"] as? NSNumber)?.doubleValue ?? 360, 1200))
      let height = max(96, min((args["height"] as? NSNumber)?.doubleValue ?? 360, 1800))
      let options = PHImageRequestOptions()
      options.isNetworkAccessAllowed = false
      options.deliveryMode = .highQualityFormat
      options.resizeMode = .fast
      options.version = .current
      PHImageManager.default().requestImage(
        for: asset,
        targetSize: CGSize(width: width, height: height),
        contentMode: .aspectFit,
        options: options
      ) { image, info in
        if (info?[PHImageResultIsDegradedKey] as? Bool) == true { return }
        guard let image, let data = image.jpegData(compressionQuality: 0.86) else {
          DispatchQueue.main.async {
            result(FlutterError(code: "thumbnail_unavailable", message: "This photo could not be read from the device.", details: nil))
          }
          return
        }
        DispatchQueue.main.async {
          result(FlutterStandardTypedData(bytes: data))
        }
      }
    case "delete":
      guard
        let args = call.arguments as? [String: Any],
        let rawIdentifiers = args["ids"] as? [String]
      else {
        result(FlutterError(code: "invalid_arguments", message: "Photo identifiers are required.", details: nil))
        return
      }
      let identifiers = Set(rawIdentifiers)
      guard !identifiers.isEmpty else {
        result(FlutterError(code: "empty_selection", message: "Select at least one photo to continue.", details: nil))
        return
      }
      guard canReadPhotos else {
        result(FlutterError(code: "photos_unavailable", message: "Photo access changed. Review your selection again.", details: nil))
        return
      }
      let assets = PHAsset.fetchAssets(withLocalIdentifiers: Array(identifiers), options: nil)
      var fetchedIdentifiers = Set<String>()
      assets.enumerateObjects { asset, _, _ in fetchedIdentifiers.insert(asset.localIdentifier) }
      guard fetchedIdentifiers == identifiers else {
        result(FlutterError(code: "selection_changed", message: "Some selected photos are no longer available. Review the updated selection.", details: Array(identifiers.subtracting(fetchedIdentifiers))))
        return
      }
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.deleteAssets(assets)
      }) { success, error in
        let remainingAssets = PHAsset.fetchAssets(withLocalIdentifiers: Array(identifiers), options: nil)
        var remaining = Set<String>()
        remainingAssets.enumerateObjects { asset, _, _ in remaining.insert(asset.localIdentifier) }
        let operationSucceeded = success && error == nil
        // Report observed library state even if PhotoKit's operation-level
        // flag is false; partial completion must not leave removed IDs in UI.
        let deleted = identifiers.subtracting(remaining)
        DispatchQueue.main.async {
          result([
            "succeeded": operationSucceeded,
            "deleted": Array(deleted),
            "remaining": Array(remaining),
            "error": error?.localizedDescription as Any? ?? NSNull()
          ])
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private var canReadPhotos: Bool {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    return status == .authorized || status == .limited
  }
}
