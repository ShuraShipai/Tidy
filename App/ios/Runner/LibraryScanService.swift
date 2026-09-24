import Flutter
import Photos
import Contacts
import Vision
import UIKit

/// Read-only adapter. No mutation APIs, file writes, cloud requests or persisted records.
final class LibraryScanService: NSObject, PHPhotoLibraryChangeObserver {
  private let queue = DispatchQueue(label: "tidy.scan", qos: .userInitiated)
  private let lock = NSLock()
  private var revision = 0
  private var serial = 0
  private var cancelled = false
  private var busy = false
  private var snapshot: [String: Any] = ["phase": "idle"]
  private var resourceRequest: PHAssetResourceDataRequestID?
  private var imageRequest: PHImageRequestID?
  private let contacts = CNContactStore()
  private var contactObserver: NSObjectProtocol?

  override init() {
    super.init()
    PHPhotoLibrary.shared().register(self)
    contactObserver = NotificationCenter.default.addObserver(forName: .CNContactStoreDidChange, object: nil, queue: nil) { [weak self] _ in self?.invalidate() }
  }
  deinit {
    PHPhotoLibrary.shared().unregisterChangeObserver(self)
    if let observer = contactObserver { NotificationCenter.default.removeObserver(observer) }
  }
  func photoLibraryDidChange(_ changeInstance: PHChange) { invalidate() }
  private func invalidate() {
    lock.lock(); revision += 1; cancelled = true
    let resource = resourceRequest; let image = imageRequest
    snapshot = ["phase": "stale"]; serial += 1
    lock.unlock()
    if let resource = resource { PHAssetResourceManager.default().cancelDataRequest(resource) }
    if let image = image { PHImageManager.default().cancelImageRequest(image) }
  }
  private func access(_ raw: Int) -> String {
    // Both native authorization enums use 0...4 for these states.
    return ["notDetermined", "restricted", "denied", "authorized", "limited"].indices.contains(raw)
      ? ["notDetermined", "restricted", "denied", "authorized", "limited"][raw] : "restricted"
  }
  func permissions() -> [String: String] {
    ["photos": access(PHPhotoLibrary.authorizationStatus(for: .readWrite).rawValue),
     "contacts": access(CNContactStore.authorizationStatus(for: .contacts).rawValue)]
  }
  private func readable(_ value: String?) -> Bool { value == "authorized" || value == "limited" }
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "permissions": result(permissions())
    case "status":
      let current = permissions()
      lock.lock()
      if let previous = snapshot["permissions"] as? [String: String], previous != current {
        revision += 1; snapshot = ["phase": "stale"]; serial += 1
      }
      if (call.arguments as? Int) == serial { lock.unlock(); result(["unchanged": true]); return }
      var value = snapshot; value["serial"] = serial
      lock.unlock(); result(value)
    case "cancel": stop(); result(nil)
    case "start":
      lock.lock()
      guard !busy else { lock.unlock(); result(FlutterError(code: "busy", message: "A scan is already running.", details: nil)); return }
      busy = true; cancelled = false; let version = revision
      snapshot = ["phase": "loading"]; serial += 1
      lock.unlock()
      queue.async { self.scan(version: version) }
      result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }
  private func stop() {
    lock.lock(); cancelled = true; let resource = resourceRequest; let image = imageRequest
    snapshot = ["phase": "cancelled"]; serial += 1; lock.unlock()
    if let resource = resource { PHAssetResourceManager.default().cancelDataRequest(resource) }
    if let image = image { PHImageManager.default().cancelImageRequest(image) }
  }
  private func valid(_ version: Int) -> Bool {
    lock.lock(); defer { lock.unlock() }; return !cancelled && revision == version
  }
  private func publish(_ value: [String: Any], version: Int) {
    lock.lock(); defer { lock.unlock() }
    if !cancelled && revision == version { snapshot = value; serial += 1 }
  }
  private func bytes(_ asset: PHAsset, version: Int) -> Int64? {
    let resources = PHAssetResource.assetResources(for: asset)
    guard !resources.isEmpty else { return nil }
    var total: Int64 = 0
    for resource in resources {
      guard valid(version) else { return nil }
      let signal = DispatchSemaphore(value: 0)
      let response = ResourceRead()
      let options = PHAssetResourceRequestOptions(); options.isNetworkAccessAllowed = false
      let request = PHAssetResourceManager.default().requestData(for: resource, options: options, dataReceivedHandler: { data in
        response.lock.lock(); response.size += Int64(data.count); response.lock.unlock()
      }, completionHandler: { error in
        response.lock.lock(); response.failed = error != nil; response.lock.unlock(); signal.signal()
      })
      lock.lock(); resourceRequest = request; let stopNow = cancelled || revision != version; lock.unlock()
      if stopNow { PHAssetResourceManager.default().cancelDataRequest(request) }
      // Bounded wait also handles providers that fail to finish after cancellation.
      if signal.wait(timeout: .now() + 30) == .timedOut {
        PHAssetResourceManager.default().cancelDataRequest(request)
        lock.lock(); resourceRequest = nil; lock.unlock()
        return nil
      }
      lock.lock(); resourceRequest = nil; lock.unlock()
      response.lock.lock(); let failed = response.failed; let size = response.size; response.lock.unlock()
      if failed || !valid(version) { return nil }
      total += size
    }
    return total
  }
  private func feature(_ asset: PHAsset, version: Int) -> VNFeaturePrintObservation? {
    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = false; options.deliveryMode = .highQualityFormat
    options.resizeMode = .fast
    let signal = DispatchSemaphore(value: 0)
    let response = ImageRead()
    let request = PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 256, height: 256), contentMode: .aspectFit, options: options) { image, info in
      if (info?[PHImageResultIsDegradedKey] as? Bool) == true { return }
      response.lock.lock(); response.image = image; response.lock.unlock(); signal.signal()
    }
    lock.lock(); imageRequest = request; let stopNow = cancelled || revision != version; lock.unlock()
    if stopNow { PHImageManager.default().cancelImageRequest(request) }
    let finished = signal.wait(timeout: .now() + 15) == .success
    lock.lock(); imageRequest = nil; lock.unlock()
    if !finished { PHImageManager.default().cancelImageRequest(request) }
    response.lock.lock(); let captured = response.image; response.lock.unlock()
    guard finished, valid(version), let cg = captured?.cgImage else { return nil }
    let analysis = VNGenerateImageFeaturePrintRequest()
    analysis.revision = VNGenerateImageFeaturePrintRequestRevision2
    do {
      try VNImageRequestHandler(cgImage: cg).perform([analysis])
      return analysis.results?.first
    } catch { return nil }
  }
  private func scan(version: Int) {
    defer { lock.lock(); busy = false; lock.unlock() }
    let permissions = permissions()
    var base: [String: Any] = ["permissions": permissions]
    do {
      let volume = try URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
      if let capacity = volume.volumeTotalCapacity, let free = volume.volumeAvailableCapacity {
        base["storage"] = ["capacity": capacity, "free": free, "used": max(0, capacity - free)]
      } else { base["storageError"] = "Storage capacity is unavailable." }
    } catch { base["storageError"] = "Storage capacity is unavailable: \(error.localizedDescription)" }
    guard readable(permissions["photos"]) || readable(permissions["contacts"]) else {
      base["phase"] = "permissionDenied"; publish(base, version: version); return
    }
    var media = [[String: Any]]()
    var pairs = [[String]]()
    var recent = [(String, Date, VNFeaturePrintObservation)]()
    var unavailableImages = 0
    if readable(permissions["photos"]) {
      let options = PHFetchOptions()
      options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
      options.predicate = NSPredicate(format: "mediaType == %d OR mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
      let assets = PHAsset.fetchAssets(with: options)
      for index in 0..<assets.count {
        guard valid(version) else { return }
        autoreleasepool {
          let asset = assets.object(at: index)
          var item: [String: Any] = ["id": asset.localIdentifier, "video": asset.mediaType == .video,
            "screenshot": asset.mediaSubtypes.contains(.photoScreenshot), "width": asset.pixelWidth,
            "height": asset.pixelHeight, "duration": asset.duration, "favorite": asset.isFavorite]
          if let date = asset.creationDate { item["createdAt"] = date.timeIntervalSince1970 * 1000 }
          if let date = asset.modificationDate { item["modifiedAt"] = date.timeIntervalSince1970 * 1000 }
          if let size = bytes(asset, version: version) { item["bytes"] = size }
          if asset.mediaType == .image && !asset.mediaSubtypes.contains(.photoScreenshot) {
            if let print = feature(asset, version: version), let date = asset.creationDate {
              recent.removeAll { date.timeIntervalSince($0.1) > 60 }
              for previous in recent {
                var distance: Float = 0
                if (try? print.computeDistance(&distance, to: previous.2)) != nil && distance < 0.3 {
                  pairs.append([previous.0, asset.localIdentifier])
                }
              }
              recent.append((asset.localIdentifier, date, print))
              if recent.count > 30 { recent.removeFirst() }
            } else { unavailableImages += 1 }
          }
          media.append(item)
          var progress = base
          progress.merge(["phase": "scanning", "stage": "media", "processed": index + 1, "total": assets.count]) { _, new in new }
          publish(progress, version: version)
        }
      }
    }
    guard valid(version) else { return }
    var contactMatches = [String: Set<String>]()
    var contactCount = 0
    if readable(permissions["contacts"]) {
      var progress = base; progress.merge(["phase": "scanning", "stage": "contacts"]) { _, new in new }
      publish(progress, version: version)
      let request = CNContactFetchRequest(keysToFetch: [CNContactIdentifierKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey].map { $0 as CNKeyDescriptor })
      // Preserve separate source cards so shared details can be surfaced for review.
      request.unifyResults = false
      do {
        try contacts.enumerateContacts(with: request) { contact, stop in
          guard self.valid(version) else { stop.pointee = true; return }
          contactCount += 1
          let phones = contact.phoneNumbers.map { "phone:" + $0.value.stringValue.filter { $0.isNumber } }.filter { $0.count > 6 }
          let emails = contact.emailAddresses.map { "email:" + ($0.value as String).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { $0.contains("@") }
          for key in Set(phones + emails) { contactMatches[key, default: []].insert(contact.identifier) }
        }
      } catch {
        base["phase"] = "error"; base["message"] = "Contacts could not be read. Check access and scan again."
        publish(base, version: version); return
      }
    }
    guard valid(version) else { return }
    guard self.permissions() == permissions else { invalidate(); return }
    base.merge(["phase": "success", "media": media, "similarPairs": pairs,
      "contactMatches": contactMatches.filter { $0.value.count > 1 }.map { ["evidence": $0.key.hasPrefix("phone:") ? "Shared phone number" : "Shared email address", "ids": Array($0.value).sorted()] },
      "contactCount": contactCount, "unavailableImages": unavailableImages,
      "completedAt": Date().timeIntervalSince1970 * 1000]) { _, new in new }
    publish(base, version: version)
  }
}

private final class ResourceRead {
  let lock = NSLock()
  var size: Int64 = 0
  var failed = false
}
private final class ImageRead {
  let lock = NSLock()
  var image: UIImage?
}
