import Flutter
import Photos
import Contacts
import Vision
import UIKit
import CryptoKit
import os

/// On-device scan and incremental snapshot reconciliation. Never changes library assets.
final class LibraryScanService: NSObject, PHPhotoLibraryChangeObserver {
  private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Tidy", category: "LibraryScan")
  private let queue = DispatchQueue(label: "tidy.scan", qos: .userInitiated)
  private let lock = NSLock()
  private var revision = 0
  private var serial = 0
  private var cancelled = false
  private var busy = false
  private var snapshot: [String: Any] = ["phase": "idle"]
  private var resourceRequest: PHAssetResourceDataRequestID?
  private var imageRequest: PHImageRequestID?
  private var photoObserverRegistered = false
  private var restored = false
  private var reconciling = false
  private var reconcileAgain = false
  private var needsPhotoCheck = false
  private var needsContactCheck = false
  private let contacts = CNContactStore()
  private var contactObserver: NSObjectProtocol?

  override init() {
    super.init()
    contactObserver = NotificationCenter.default.addObserver(forName: .CNContactStoreDidChange, object: nil, queue: nil) { [weak self] _ in
      self?.scheduleReconcile(photos: false, contacts: true)
    }
  }
  deinit {
    if photoObserverRegistered {
      PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    if let observer = contactObserver { NotificationCenter.default.removeObserver(observer) }
  }
  func photoLibraryDidChange(_ changeInstance: PHChange) {
    scheduleReconcile(photos: true, contacts: false)
  }
  private func scheduleReconcile(photos: Bool = true, contacts: Bool = true) {
    lock.lock()
    guard restored else { lock.unlock(); return }
    needsPhotoCheck = needsPhotoCheck || photos
    needsContactCheck = needsContactCheck || contacts
    if reconciling { reconcileAgain = true; lock.unlock(); return }
    reconciling = true
    lock.unlock()
    queue.async {
      repeat {
        self.lock.lock()
        self.reconcileAgain = false
        let scanning = self.busy
        let checkPhotos = self.needsPhotoCheck
        let checkContacts = self.needsContactCheck
        self.needsPhotoCheck = false
        self.needsContactCheck = false
        self.lock.unlock()
        if !scanning { self.reconcile(photos: checkPhotos, contacts: checkContacts) }
        self.lock.lock(); let again = self.reconcileAgain; if !again { self.reconciling = false }; self.lock.unlock()
        if !again { break }
      } while true
    }
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
  private func storedScanPreferences() -> [String: Any] {
    let defaults = UserDefaults.standard
    return [
      "includeScreenshots": defaults.object(forKey: "tidy.includeScreenshots") as? Bool ?? true,
      "includeLargeVideos": defaults.object(forKey: "tidy.includeLargeVideos") as? Bool ?? true,
      "sensitivity": defaults.string(forKey: "tidy.photoSensitivity") ?? "balanced",
    ]
  }
  private func similarityThreshold(_ preferences: [String: Any]) -> Float {
    switch preferences["sensitivity"] as? String ?? "balanced" {
    case "strict": return 0.2
    case "broad": return 0.4
    default: return 0.3
    }
  }
  private func includedInScan(_ asset: PHAsset, preferences: [String: Any]) -> Bool {
    if asset.mediaSubtypes.contains(.photoScreenshot),
      preferences["includeScreenshots"] as? Bool == false { return false }
    if asset.mediaType == .video,
      preferences["includeLargeVideos"] as? Bool == false { return false }
    return true
  }
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "permissions": result(permissions())
    case "status":
      lock.lock()
      let needsRestore = !restored
      restored = true
      let restoreVersion = revision
      lock.unlock()
      if needsRestore {
        queue.async {
          self.restore(version: restoreVersion)
          DispatchQueue.main.async { self.handle(call, result: result) }
        }
        return
      }
      let current = permissions()
      lock.lock()
      if let previous = snapshot["permissions"] as? [String: String], previous != current {
        snapshot["permissions"] = current; serial += 1
        if !readable(current["photos"]) {
          snapshot["media"] = [[String: Any]]()
          snapshot["similarPairs"] = [[String]]()
          snapshot["unavailableImages"] = 0
        }
        if !readable(current["contacts"]) {
          snapshot["contactMatches"] = [[String: Any]]()
          snapshot["contactCount"] = 0
        }
        lock.unlock()
        scheduleReconcile()
        lock.lock()
      }
      if (call.arguments as? Int) == serial { lock.unlock(); result(["unchanged": true]); return }
      var value = snapshot; value["serial"] = serial
      lock.unlock(); result(value)
    case "cancel": stop(); result(nil)
    case "applyDeleted":
      let ids = Set((call.arguments as? [String]) ?? [])
      guard !ids.isEmpty else { result(nil); return }
      lock.lock()
      revision += 1
      let resource = resourceRequest
      let image = imageRequest
      lock.unlock()
      if let resource = resource { PHAssetResourceManager.default().cancelDataRequest(resource) }
      if let image = image { PHImageManager.default().cancelImageRequest(image) }
      queue.async {
        self.applyDeleted(ids)
        self.scheduleReconcile(photos: true, contacts: false)
        DispatchQueue.main.async { result(nil) }
      }
    case "start":
      lock.lock()
      guard !busy else { lock.unlock(); result(FlutterError(code: "busy", message: "A scan is already running.", details: nil)); return }
      busy = true; cancelled = false; revision += 1; let version = revision
      let attemptID = UUID().uuidString
      restored = true
      snapshot = ["phase": "loading"]; serial += 1
      lock.unlock()
      markInterrupted(attemptID)
      queue.async { self.scan(version: version, attemptID: attemptID) }
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

  // The snapshot contains identifiers, hashes, measurements and timestamps only.
  // It never contains photo/video bytes or contact records.
  private var storageDirectory: URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("TidyScan", isDirectory: true)
  }
  private var snapshotURL: URL { storageDirectory.appendingPathComponent("completed-v1.json") }
  private var interruptedURL: URL { storageDirectory.appendingPathComponent("interrupted") }

  private func prepareStorage() throws {
    try FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true,
      attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    var directory = storageDirectory
    try directory.setResourceValues(values)
  }
  private func markInterrupted(_ attemptID: String) {
    do {
      try prepareStorage()
      try Data(attemptID.utf8).write(to: interruptedURL, options: .atomic)
      try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
        ofItemAtPath: interruptedURL.path)
    } catch {
      Self.logger.error("Could not record scan attempt: \(error.localizedDescription)")
    }
  }
  private func saveCompleted(_ value: [String: Any], photoSignature: String?, attemptID: String,
                             clearInterrupted: Bool = true) {
    do {
      try prepareStorage()
      var persisted = value
      let oldRecord = (try? Data(contentsOf: snapshotURL)).flatMap {
        try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
      }
      if let old = oldRecord?["snapshot"] as? [String: Any] {
        let access = value["permissions"] as? [String: String]
        if !readable(access?["photos"]) {
          persisted["media"] = old["media"]
          persisted["similarPairs"] = old["similarPairs"]
          persisted["unavailableImages"] = old["unavailableImages"]
        }
        if !readable(access?["contacts"]) {
          persisted["contactMatches"] = old["contactMatches"]
          persisted["contactCount"] = old["contactCount"]
        }
      }
      let record: [String: Any] = [
        "version": 1, "snapshot": persisted, "attemptID": attemptID,
        "photoSignature": photoSignature ?? "",
        "contactToken": readable((value["permissions"] as? [String: String])?["contacts"])
          ? (contacts.currentHistoryToken?.base64EncodedString() ?? "") : ""
      ]
      let data = try JSONSerialization.data(withJSONObject: record)
      try data.write(to: snapshotURL, options: .atomic)
      try FileManager.default.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
        ofItemAtPath: snapshotURL.path)
      if clearInterrupted { try? FileManager.default.removeItem(at: interruptedURL) }
    } catch {
      Self.logger.error("Could not save completed scan: \(error.localizedDescription)")
    }
  }
  private func photoOptions() -> PHFetchOptions {
    let options = PHFetchOptions()
    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    options.predicate = NSPredicate(format: "mediaType == %d OR mediaType == %d",
      PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
    return options
  }
  private func fingerprintEntry(_ asset: PHAsset) -> String {
    "\(asset.localIdentifier)|\(asset.modificationDate?.timeIntervalSince1970 ?? -1)|\(asset.creationDate?.timeIntervalSince1970 ?? -1)|\(asset.isFavorite)|\(asset.pixelWidth)|\(asset.pixelHeight)|\(asset.duration);"
  }
  private func signature(_ entries: [String]) -> String {
    var hasher = SHA256()
    for entry in entries.sorted() { hasher.update(data: Data(entry.utf8)) }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
  }
  private func photoSignature() -> String {
    var entries = [String]()
    let assets = PHAsset.fetchAssets(with: photoOptions())
    entries.reserveCapacity(assets.count)
    for index in 0..<assets.count { entries.append(fingerprintEntry(assets.object(at: index))) }
    return signature(entries)
  }
  private func storageValues() -> [String: Int]? {
    guard let volume = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(
      forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]),
      let capacity = volume.volumeTotalCapacity, let free = volume.volumeAvailableCapacity else { return nil }
    return ["capacity": capacity, "free": free, "used": max(0, capacity - free)]
  }
  private func applyDeleted(_ ids: Set<String>) {
    lock.lock()
    if snapshot["completedAt"] == nil,
      let data = try? Data(contentsOf: snapshotURL),
      let record = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let saved = record["snapshot"] as? [String: Any] {
      snapshot = saved
    }
    guard snapshot["completedAt"] != nil,
      let previous = snapshot["media"] as? [[String: Any]] else { lock.unlock(); return }
    let removed = previous.filter { ids.contains($0["id"] as? String ?? "") }
    guard !removed.isEmpty else { lock.unlock(); return }
    let remaining = previous.filter { !ids.contains($0["id"] as? String ?? "") }
    snapshot["media"] = remaining
    let pairs = (snapshot["similarPairs"] as? [[String]]) ?? []
    snapshot["similarPairs"] = pairs.filter { $0.allSatisfy { !ids.contains($0) } }
    snapshot["unavailableImages"] = remaining.filter {
      ($0["video"] as? Bool) == false && ($0["screenshot"] as? Bool) == false &&
      ($0["analysisAvailable"] as? Bool) != true
    }.count
    snapshot["phase"] = "success"
    if let storage = storageValues() { snapshot["storage"] = storage }
    serial += 1
    let updated = snapshot
    lock.unlock()
    saveCompleted(updated, photoSignature: nil, attemptID: UUID().uuidString,
      clearInterrupted: false)
  }
  private func mediaItem(_ asset: PHAsset, version: Int, profile: ScanProfile) ->
    ([String: Any], VNFeaturePrintObservation?) {
    var item: [String: Any] = ["id": asset.localIdentifier, "video": asset.mediaType == .video,
      "screenshot": asset.mediaSubtypes.contains(.photoScreenshot), "width": asset.pixelWidth,
      "height": asset.pixelHeight, "duration": asset.duration, "favorite": asset.isFavorite,
      "fingerprint": fingerprintEntry(asset)]
    if let date = asset.creationDate { item["createdAt"] = date.timeIntervalSince1970 * 1000 }
    if let date = asset.modificationDate { item["modifiedAt"] = date.timeIntervalSince1970 * 1000 }
    let shouldAnalyze = asset.mediaType == .image && !asset.mediaSubtypes.contains(.photoScreenshot)
    let summary: (Int64, String?)?
    let print: VNFeaturePrintObservation?
    let blur: Double?
    if shouldAnalyze {
      let value = feature(asset, version: version, profile: profile) {
        self.resourceSummary(asset, version: version, hashContent: true, profile: profile)
      }
      summary = value.0; print = value.1; blur = value.2
      item["analysisAvailable"] = print != nil && asset.creationDate != nil
    } else {
      let started = ProcessInfo.processInfo.systemUptime
      summary = resourceSummary(
        asset, version: version, hashContent: asset.mediaType == .image, profile: profile)
      profile.resourceSeconds += ProcessInfo.processInfo.systemUptime - started
      print = nil; blur = nil
    }
    if let summary = summary {
      item["bytes"] = summary.0
      if let hash = summary.1 { item["contentHash"] = hash }
    }
    if let blur = blur {
      item["blurScore"] = blur
      item["possiblyBlurry"] = blur < PhotoBlurDetector.possibleBlurThreshold
    }
    return (item, print)
  }
  private func contactFindings(version: Int) -> ([[String: Any]], Int)? {
    var matches = [String: Set<String>]()
    var count = 0
    let request = CNContactFetchRequest(keysToFetch:
      [CNContactIdentifierKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey]
        .map { $0 as CNKeyDescriptor })
    request.unifyResults = false
    do {
      try contacts.enumerateContacts(with: request) { contact, stop in
        guard self.valid(version) else { stop.pointee = true; return }
        count += 1
        let phones = contact.phoneNumbers.map { "phone:" + $0.value.stringValue.filter { $0.isNumber } }
          .filter { $0.count > 6 }
        let emails = contact.emailAddresses.map {
          "email:" + ($0.value as String).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }.filter { $0.contains("@") }
        for key in Set(phones + emails) { matches[key, default: []].insert(contact.identifier) }
      }
    } catch { return nil }
    guard valid(version) else { return nil }
    return (matches.filter { $0.value.count > 1 }.map {
      ["evidence": $0.key.hasPrefix("phone:") ? "Shared phone number" : "Shared email address",
       "ids": Array($0.value).sorted()] as [String: Any]
    }, count)
  }
  private func reconcile(photos checkPhotos: Bool, contacts checkContacts: Bool) {
    lock.lock()
    guard !busy else { lock.unlock(); return }
    cancelled = false
    let version = revision
    var updated = snapshot
    lock.unlock()
    let diskRecord = (try? Data(contentsOf: snapshotURL)).flatMap {
      try? JSONSerialization.jsonObject(with: $0) as? [String: Any]
    }
    if updated["completedAt"] == nil {
      guard let saved = diskRecord?["snapshot"] as? [String: Any] else { return }
      updated = saved
      updated["phase"] = "cancelled"
      updated["message"] = "The previous scan did not finish. Last completed findings are still available."
    }
    let preferences = updated["scanPreferences"] as? [String: Any] ?? storedScanPreferences()
    let similarityLimit = similarityThreshold(preferences)
    let current = permissions()
    updated["permissions"] = current
    if let previous = diskRecord?["snapshot"] as? [String: Any],
      (previous["completedAt"] as? Double) == (updated["completedAt"] as? Double) {
      if readable(current["photos"]),
        (updated["media"] as? [[String: Any]])?.isEmpty == true {
        updated["media"] = previous["media"]
        updated["similarPairs"] = previous["similarPairs"]
        updated["unavailableImages"] = previous["unavailableImages"]
      }
      if readable(current["contacts"]),
        (updated["contactMatches"] as? [[String: Any]])?.isEmpty == true {
        updated["contactMatches"] = previous["contactMatches"]
        updated["contactCount"] = previous["contactCount"]
      }
    }
    if checkPhotos && readable(current["photos"]) {
      if !photoObserverRegistered {
        PHPhotoLibrary.shared().register(self)
        photoObserverRegistered = true
      }
      let assets = PHAsset.fetchAssets(with: photoOptions())
      let prior = (updated["media"] as? [[String: Any]]) ?? []
      let oldByID = Dictionary(uniqueKeysWithValues: prior.compactMap { item -> (String, [String: Any])? in
        guard let id = item["id"] as? String else { return nil }; return (id, item)
      })
      var live = [PHAsset]()
      var entries = [String]()
      var changedDates = [TimeInterval]()
      var changed = Set<String>()
      var present = Set<String>()
      live.reserveCapacity(assets.count)
      for index in 0..<assets.count {
        let asset = assets.object(at: index)
        live.append(asset)
        let id = asset.localIdentifier
        present.insert(id)
        let fingerprint = fingerprintEntry(asset)
        entries.append(fingerprint)
        if let old = oldByID[id] {
          let oldFingerprint = old["fingerprint"] as? String
          let basicMatch = (old["modifiedAt"] as? Double) ==
            asset.modificationDate.map { $0.timeIntervalSince1970 * 1000 } &&
            (old["createdAt"] as? Double) ==
              asset.creationDate.map { $0.timeIntervalSince1970 * 1000 } &&
            (old["favorite"] as? Bool) == asset.isFavorite &&
            (old["width"] as? Int) == asset.pixelWidth &&
            (old["height"] as? Int) == asset.pixelHeight &&
            (old["duration"] as? Double) == asset.duration &&
            (old["screenshot"] as? Bool) == asset.mediaSubtypes.contains(.photoScreenshot)
          if oldFingerprint == fingerprint || (oldFingerprint == nil && basicMatch) { continue }
          if (old["video"] as? Bool) == false && (old["screenshot"] as? Bool) == false,
            let date = old["createdAt"] as? Double { changedDates.append(date / 1000) }
        }
        changed.insert(id)
        if asset.mediaType == .image && !asset.mediaSubtypes.contains(.photoScreenshot),
          let date = asset.creationDate { changedDates.append(date.timeIntervalSince1970) }
      }
      for old in prior where !present.contains(old["id"] as? String ?? "") {
        if (old["video"] as? Bool) == false && (old["screenshot"] as? Bool) == false,
          let date = old["createdAt"] as? Double { changedDates.append(date / 1000) }
      }
      let removed = Set(oldByID.keys).subtracting(present)
      if !changed.isEmpty || !removed.isEmpty {
        let profile = ScanProfile()
        var nextByID = oldByID
        var prints = [String: VNFeaturePrintObservation]()
        var checked = Set<String>()
        for id in removed { nextByID.removeValue(forKey: id) }
        // Exact resource reads and hashes are needed only for new/changed assets.
        for asset in live where changed.contains(asset.localIdentifier) {
          guard valid(version) else { return }
          guard includedInScan(asset, preferences: preferences) else {
            nextByID.removeValue(forKey: asset.localIdentifier)
            continue
          }
          let (item, print) = mediaItem(asset, version: version, profile: profile)
          nextByID[asset.localIdentifier] = item
          checked.insert(asset.localIdentifier)
          if let print = print { prints[asset.localIdentifier] = print }
        }
        guard valid(version) else { return }
        // Re-evaluate only similarity windows affected by changed membership/metadata.
        let eligible = live.filter { $0.mediaType == .image && !$0.mediaSubtypes.contains(.photoScreenshot) && $0.creationDate != nil }
        let affected = Set(eligible.filter { asset in
          guard let date = asset.creationDate?.timeIntervalSince1970 else { return false }
          return changedDates.contains { abs(date - $0) <= 60 }
        }.map(\.localIdentifier))
        var pairs = ((updated["similarPairs"] as? [[String]]) ?? []).filter {
          $0.count == 2 && !removed.contains($0[0]) && !removed.contains($0[1]) &&
          !affected.contains($0[1])
        }
        for (index, asset) in eligible.enumerated() where affected.contains(asset.localIdentifier) {
          guard valid(version) else { return }
          let date = asset.creationDate!
          var candidates = [PHAsset]()
          var cursor = index
          while cursor > 0 && candidates.count < 30 {
            cursor -= 1
            let previous = eligible[cursor]
            if date.timeIntervalSince(previous.creationDate!) > 60 { break }
            if !checked.contains(previous.localIdentifier) {
              let (_, print, _) = feature(previous, version: version, profile: profile) { nil }
              checked.insert(previous.localIdentifier)
              if let print = print { prints[previous.localIdentifier] = print }
            }
            if prints[previous.localIdentifier] != nil { candidates.append(previous) }
          }
          if !checked.contains(asset.localIdentifier) {
            let (_, print, _) = feature(asset, version: version, profile: profile) { nil }
            checked.insert(asset.localIdentifier)
            if let print = print { prints[asset.localIdentifier] = print }
          }
          guard let print = prints[asset.localIdentifier] else { continue }
          for previous in candidates {
            guard let other = prints[previous.localIdentifier] else { continue }
            var distance: Float = 0
            if (try? print.computeDistance(&distance, to: other)) != nil && distance < similarityLimit {
              pairs.append([previous.localIdentifier, asset.localIdentifier])
            }
          }
        }
        updated["media"] = live.compactMap { nextByID[$0.localIdentifier] }
        updated["similarPairs"] = pairs
        updated["unavailableImages"] = (updated["media"] as? [[String: Any]] ?? []).filter {
          ($0["video"] as? Bool) == false && ($0["screenshot"] as? Bool) == false &&
          ($0["analysisAvailable"] as? Bool) != true
        }.count
      } else if prior.contains(where: { $0["fingerprint"] == nil }) {
        // One-time migration of earlier lightweight snapshots, without rereading media bytes.
        updated["media"] = live.compactMap { asset -> [String: Any]? in
          guard var item = oldByID[asset.localIdentifier] else { return nil }
          item["fingerprint"] = fingerprintEntry(asset)
          return item
        }
      }
      updated["photoSignature"] = signature(entries)
    } else if !readable(current["photos"]) {
      updated["media"] = [[String: Any]]()
      updated["similarPairs"] = [[String]]()
      updated["unavailableImages"] = 0
    }
    if checkContacts && readable(current["contacts"]) {
      let savedToken = diskRecord?["contactToken"] as? String
      let currentToken = contacts.currentHistoryToken?.base64EncodedString()
      if savedToken == nil || savedToken != currentToken || updated["contactMatches"] == nil {
        guard let (matches, count) = contactFindings(version: version) else { return }
        updated["contactMatches"] = matches
        updated["contactCount"] = count
      }
    } else if !readable(current["contacts"]) {
      updated["contactMatches"] = [[String: Any]]()
      updated["contactCount"] = 0
    }
    guard valid(version), permissions() == current else { scheduleReconcile(); return }
    updated["phase"] = "success"
    updated.removeValue(forKey: "message")
    if let storage = storageValues() { updated["storage"] = storage }
    lock.lock()
    guard !busy, revision == version else { lock.unlock(); return }
    snapshot = updated; serial += 1
    lock.unlock()
    saveCompleted(updated, photoSignature: updated["photoSignature"] as? String,
      attemptID: UUID().uuidString, clearInterrupted: false)
  }
  private func restore(version: Int) {
    let pendingAttempt = (try? Data(contentsOf: interruptedURL)).flatMap { String(data: $0, encoding: .utf8) }
    guard let data = try? Data(contentsOf: snapshotURL),
      let record = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      record["version"] as? Int == 1,
      let saved = record["snapshot"] as? [String: Any],
      saved["phase"] as? String == "success",
      saved["permissions"] is [String: String] else {
      if pendingAttempt != nil { publish(["phase": "cancelled", "message": "The previous scan did not finish."], version: version) }
      return
    }
    let current = permissions()
    if readable(current["photos"]) {
      if !photoObserverRegistered {
        PHPhotoLibrary.shared().register(self)
        photoObserverRegistered = true
      }
    }
    var restoredSnapshot = saved
    restoredSnapshot["permissions"] = current
    if !readable(current["photos"]) {
      restoredSnapshot["media"] = [[String: Any]]()
      restoredSnapshot["similarPairs"] = [[String]]()
      restoredSnapshot["unavailableImages"] = 0
    }
    if !readable(current["contacts"]) {
      restoredSnapshot["contactMatches"] = [[String: Any]]()
      restoredSnapshot["contactCount"] = 0
    }
    if let pendingAttempt = pendingAttempt, pendingAttempt != record["attemptID"] as? String {
      restoredSnapshot["phase"] = "cancelled"
      restoredSnapshot["message"] = "The previous scan did not finish. Last completed findings are still available."
    } else if pendingAttempt != nil {
      try? FileManager.default.removeItem(at: interruptedURL)
    }
    publish(restoredSnapshot, version: version)
    scheduleReconcile()
  }
  private func resourceSummary(
    _ asset: PHAsset, version: Int, hashContent: Bool, profile: ScanProfile
  ) -> (Int64, String?)? {
    let resources = PHAssetResource.assetResources(for: asset)
    let preferred: [PHAssetResourceType] = asset.mediaType == .video
      ? [.video, .fullSizeVideo]
      : [.photo, .fullSizePhoto]
    for type in preferred {
      let matches = resources.filter { $0.type == type }
      // If iOS reports multiple candidates, don't invent a combined asset size.
      guard matches.count <= 1 else { return nil }
      guard let resource = matches.first else { continue }
      guard valid(version) else { return nil }
      let signal = DispatchSemaphore(value: 0)
      let response = ResourceRead()
      profile.resourceReads += 1
      let options = PHAssetResourceRequestOptions()
      options.isNetworkAccessAllowed = false
      let request = PHAssetResourceManager.default().requestData(
        for: resource,
        options: options,
        dataReceivedHandler: { data in
          response.lock.lock()
          response.size += Int64(data.count)
          if hashContent { response.hasher.update(data: data) }
          response.lock.unlock()
        },
        completionHandler: { error in
          response.lock.lock()
          response.failed = error != nil
          response.lock.unlock()
          signal.signal()
        }
      )
      lock.lock()
      resourceRequest = request
      let stopNow = cancelled || revision != version
      lock.unlock()
      if stopNow { PHAssetResourceManager.default().cancelDataRequest(request) }
      if signal.wait(timeout: .now() + 30) == .timedOut {
        profile.resourceTimeouts += 1
        PHAssetResourceManager.default().cancelDataRequest(request)
        lock.lock()
        resourceRequest = nil
        lock.unlock()
        return nil
      }
      lock.lock()
      resourceRequest = nil
      lock.unlock()
      response.lock.lock()
      let failed = response.failed
      let size = response.size
      response.lock.unlock()
      profile.resourceBytes += size
      guard !failed, valid(version) else { return nil }
      let digest = hashContent
        ? response.hasher.finalize().map { String(format: "%02x", $0) }.joined()
        : nil
      return (size, digest)
    }
    return nil
  }
  private func feature(
    _ asset: PHAsset,
    version: Int,
    profile: ScanProfile,
    measureResource: () -> (Int64, String?)?
  ) -> ((Int64, String?)?, VNFeaturePrintObservation?, Double?) {
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
    // The exact, offline resource read and image retrieval are independent.
    // Start both before waiting so large assets do not pay their latencies in
    // series. The same complete resource hash/byte count is still required.
    let resourceStarted = ProcessInfo.processInfo.systemUptime
    let summary = measureResource()
    profile.resourceSeconds += ProcessInfo.processInfo.systemUptime - resourceStarted
    let imageWaitStarted = ProcessInfo.processInfo.systemUptime
    let finished = signal.wait(timeout: .now() + 15) == .success
    profile.imageWaitSeconds += ProcessInfo.processInfo.systemUptime - imageWaitStarted
    lock.lock(); imageRequest = nil; lock.unlock()
    if !finished { PHImageManager.default().cancelImageRequest(request) }
    response.lock.lock(); let captured = response.image; response.lock.unlock()
    guard finished, valid(version), let cg = captured?.cgImage else { return (summary, nil, nil) }
    let blurStarted = ProcessInfo.processInfo.systemUptime
    let blurScore = PhotoBlurDetector.score(cg)
    profile.blurSeconds += ProcessInfo.processInfo.systemUptime - blurStarted
    let analysis = VNGenerateImageFeaturePrintRequest()
    analysis.revision = VNGenerateImageFeaturePrintRequestRevision2
    let visionStarted = ProcessInfo.processInfo.systemUptime
    do {
      try VNImageRequestHandler(cgImage: cg).perform([analysis])
      profile.visionSeconds += ProcessInfo.processInfo.systemUptime - visionStarted
      return (summary, analysis.results?.first, blurScore)
    } catch {
      profile.visionSeconds += ProcessInfo.processInfo.systemUptime - visionStarted
      return (summary, nil, blurScore)
    }
  }
  private func scan(version: Int, attemptID: String) {
    defer { lock.lock(); busy = false; lock.unlock() }
    let scanStarted = ProcessInfo.processInfo.systemUptime
    let profile = ScanProfile()
    let permissions = permissions()
    let preferences = storedScanPreferences()
    let similarityLimit = similarityThreshold(preferences)
    var base: [String: Any] = ["permissions": permissions, "scanPreferences": preferences]
    let storageStarted = ProcessInfo.processInfo.systemUptime
    do {
      let volume = try URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
      if let capacity = volume.volumeTotalCapacity, let free = volume.volumeAvailableCapacity {
        base["storage"] = ["capacity": capacity, "free": free, "used": max(0, capacity - free)]
      } else { base["storageError"] = "Storage capacity is unavailable." }
    } catch { base["storageError"] = "Storage capacity is unavailable: \(error.localizedDescription)" }
    profile.storageSeconds = ProcessInfo.processInfo.systemUptime - storageStarted
    guard readable(permissions["photos"]) || readable(permissions["contacts"]) else {
      base["phase"] = "permissionDenied"; publish(base, version: version); return
    }
    // Do not touch PhotoKit during app or scanner startup. Register only once a
    // user explicitly starts scanning and Photos authorization is already known.
    if readable(permissions["photos"]) && !photoObserverRegistered {
      PHPhotoLibrary.shared().register(self)
      photoObserverRegistered = true
    }
    var media = [[String: Any]]()
    var pairs = [[String]]()
    var recent = [(String, Date, VNFeaturePrintObservation)]()
    var unavailableImages = 0
    var photoEntries = [String]()
    var photoSeconds = 0.0
    var contactSeconds = 0.0
    var matchingSeconds = 0.0
    var analyzedImages = 0
    var comparisons = 0
    if readable(permissions["photos"]) {
      let assets = PHAsset.fetchAssets(with: photoOptions())
      photoEntries.reserveCapacity(assets.count)
      var initialProgress = base
      initialProgress.merge(["phase": "scanning", "stage": "media", "processed": 0, "total": assets.count]) { _, new in new }
      publish(initialProgress, version: version)
      let photoStageStarted = ProcessInfo.processInfo.systemUptime
      for index in 0..<assets.count {
        guard valid(version) else { return }
        autoreleasepool {
          let asset = assets.object(at: index)
          photoEntries.append(self.fingerprintEntry(asset))
          let isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
          let isVideo = asset.mediaType == .video
          let include = (isScreenshot ? (preferences["includeScreenshots"] as? Bool ?? true) : true) &&
            (isVideo ? (preferences["includeLargeVideos"] as? Bool ?? true) : true)
          if !include {
            var progress = base
            progress.merge(["phase": "scanning", "stage": "media", "processed": index + 1, "total": assets.count]) { _, new in new }
            publish(progress, version: version)
            return
          }
          var item: [String: Any] = ["id": asset.localIdentifier, "video": asset.mediaType == .video,
            "screenshot": asset.mediaSubtypes.contains(.photoScreenshot), "width": asset.pixelWidth,
            "height": asset.pixelHeight, "duration": asset.duration, "favorite": asset.isFavorite,
            "fingerprint": self.fingerprintEntry(asset)]
          if let date = asset.creationDate { item["createdAt"] = date.timeIntervalSince1970 * 1000 }
          if let date = asset.modificationDate { item["modifiedAt"] = date.timeIntervalSince1970 * 1000 }
          let shouldAnalyze = asset.mediaType == .image && !asset.mediaSubtypes.contains(.photoScreenshot)
          let summary: (Int64, String?)?
          let featurePrint: VNFeaturePrintObservation?
          let blurScore: Double?
          if shouldAnalyze {
            let result = self.feature(asset, version: version, profile: profile) {
              self.resourceSummary(asset, version: version, hashContent: true, profile: profile)
            }
            summary = result.0
            featurePrint = result.1
            blurScore = result.2
          } else {
            let resourceStarted = ProcessInfo.processInfo.systemUptime
            summary = self.resourceSummary(
              asset, version: version, hashContent: asset.mediaType == .image, profile: profile)
            profile.resourceSeconds += ProcessInfo.processInfo.systemUptime - resourceStarted
            featurePrint = nil
            blurScore = nil
          }
          if let summary = summary {
            item["bytes"] = summary.0
            if let hash = summary.1 { item["contentHash"] = hash }
          }
          if let blurScore = blurScore {
            item["blurScore"] = blurScore
            item["possiblyBlurry"] = blurScore < PhotoBlurDetector.possibleBlurThreshold
          }
          if shouldAnalyze {
            item["analysisAvailable"] = featurePrint != nil && asset.creationDate != nil
            if let print = featurePrint, let date = asset.creationDate {
              analyzedImages += 1
              let matchingStarted = ProcessInfo.processInfo.systemUptime
              recent.removeAll { date.timeIntervalSince($0.1) > 60 }
              for previous in recent {
                comparisons += 1
                var distance: Float = 0
                if (try? print.computeDistance(&distance, to: previous.2)) != nil && distance < similarityLimit {
                  pairs.append([previous.0, asset.localIdentifier])
                }
              }
              recent.append((asset.localIdentifier, date, print))
              if recent.count > 30 { recent.removeFirst() }
              matchingSeconds += ProcessInfo.processInfo.systemUptime - matchingStarted
            } else { unavailableImages += 1 }
          }
          media.append(item)
          var progress = base
          progress.merge(["phase": "scanning", "stage": "media", "processed": index + 1, "total": assets.count]) { _, new in new }
          publish(progress, version: version)
        }
      }
      photoSeconds = ProcessInfo.processInfo.systemUptime - photoStageStarted
    }
    guard valid(version) else { return }
    var contactMatches = [String: Set<String>]()
    var contactCount = 0
    if readable(permissions["contacts"]) {
      let contactStageStarted = ProcessInfo.processInfo.systemUptime
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
      contactSeconds = ProcessInfo.processInfo.systemUptime - contactStageStarted
    }
    guard valid(version) else { return }
    guard self.permissions() == permissions else { return }
    base.merge(["phase": "success", "media": media, "similarPairs": pairs,
      "contactMatches": contactMatches.filter { $0.value.count > 1 }.map { ["evidence": $0.key.hasPrefix("phone:") ? "Shared phone number" : "Shared email address", "ids": Array($0.value).sorted()] },
      "contactCount": contactCount, "unavailableImages": unavailableImages,
      "completedAt": Date().timeIntervalSince1970 * 1000]) { _, new in new }
    publish(base, version: version)
    if valid(version) {
      let signature = readable(permissions["photos"])
        ? self.signature(photoEntries) : nil
      saveCompleted(base, photoSignature: signature, attemptID: attemptID)
    }
    let totalSeconds = ProcessInfo.processInfo.systemUptime - scanStarted
    Self.logger.info("scan_profile total_ms=\(Int(totalSeconds * 1000)) storage_ms=\(Int(profile.storageSeconds * 1000)) photos_ms=\(Int(photoSeconds * 1000)) resource_read_ms=\(Int(profile.resourceSeconds * 1000)) resource_reads=\(profile.resourceReads) resource_bytes=\(profile.resourceBytes) resource_timeouts=\(profile.resourceTimeouts) thumbnail_wait_ms=\(Int(profile.imageWaitSeconds * 1000)) vision_ms=\(Int(profile.visionSeconds * 1000)) blur_ms=\(Int(profile.blurSeconds * 1000)) matching_ms=\(Int(matchingSeconds * 1000)) contacts_ms=\(Int(contactSeconds * 1000)) assets=\(media.count) analyzed_images=\(analyzedImages) feature_comparisons=\(comparisons) contacts=\(contactCount) matches=\(pairs.count + contactMatches.filter { $0.value.count > 1 }.count) unavailable_images=\(unavailableImages)")
  }
}

private final class ScanProfile {
  var storageSeconds = 0.0
  var resourceSeconds = 0.0
  var imageWaitSeconds = 0.0
  var visionSeconds = 0.0
  var blurSeconds = 0.0
  var resourceReads = 0
  var resourceBytes: Int64 = 0
  var resourceTimeouts = 0
}

private final class ResourceRead {
  let lock = NSLock()
  var size: Int64 = 0
  var failed = false
  var hasher = SHA256()
}
private final class ImageRead {
  let lock = NSLock()
  var image: UIImage?
}
