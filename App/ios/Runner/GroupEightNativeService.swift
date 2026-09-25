import AVFoundation
import AVKit
import CryptoKit
import EventKit
import Flutter
import ImageIO
import LocalAuthentication
import Photos
import Security
import UIKit
import WidgetKit

/// Native, on-device services for the optional Group 08 flows.
final class GroupEightNativeService {
  // EventKit truncates predicates longer than four years to their first four
  // years. Keep the rolling range just under that limit so recent events are
  // never lost to a predicate starting at Date.distantPast.
  static let calendarLookback: TimeInterval = 4 * 365 * 24 * 60 * 60

  static func calendarSearchStart(now: Date) -> Date {
    now.addingTimeInterval(-calendarLookback)
  }

  private let eventStore = EKEventStore()
  private let lock = NSLock()
  private let vaultQueue = DispatchQueue(label: "com.example.tidy.private-vault", qos: .userInitiated)
  private var exports: [String: CompressionJob] = [:]
  private var vaultKey: SymmetricKey?
  private var vaultUnlocked = false
  private var vaultEntriesCache: [[String: Any]]?
  private let vaultFolder: URL
  private let vaultIndexURL: URL
  private let historyURL: URL
  private let groupID = "group.com.example.tidy"

  init() {
    let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let root = support.appendingPathComponent("Tidy", isDirectory: true)
    vaultFolder = root.appendingPathComponent("PrivateVault", isDirectory: true)
    vaultIndexURL = root.appendingPathComponent("vault-index.json")
    historyURL = root.appendingPathComponent("bonus-history.json")
    vaultQueue.async {
      try? FileManager.default.createDirectory(at: self.vaultFolder, withIntermediateDirectories: true)
      try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: self.vaultFolder.path)
      var rootValues = URLResourceValues(); rootValues.isExcludedFromBackup = true
      var rootURL = root; try? rootURL.setResourceValues(rootValues)
      var vaultValues = URLResourceValues(); vaultValues.isExcludedFromBackup = true
      var vaultURL = self.vaultFolder; try? vaultURL.setResourceValues(vaultValues)
      self.recoverPendingVaultRemovals()
    }
    cleanOrphanedCompressionFiles()
  }

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "tidy/group_eight", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      self.handle(call, result: result)
    }
  }

  func lockVault() {
    lock.lock(); vaultKey = nil; vaultUnlocked = false; lock.unlock()
    vaultQueue.async { self.vaultEntriesCache = nil }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "calendar.status": calendarStatus(result)
    case "calendar.request": requestCalendar(result)
    case "calendar.openSettings":
      guard let settings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settings) else { result(false); break }
      UIApplication.shared.open(settings, options: [:]) { result($0) }
    case "calendar.list": listEvents(call.arguments, result)
    case "calendar.delete": deleteEvents(call.arguments, result)
    case "vault.authenticate": authenticateVault(result)
    case "vault.status": vaultStatus(result)
    case "vault.lock": lockVault(); result(nil)
    case "vault.list": vaultList(result)
    case "vault.thumbnail": vaultThumbnail(call.arguments, result)
    case "vault.add": vaultAdd(call.arguments, result)
    case "vault.delete": vaultDelete(call.arguments, result)
    case "compression.start": startCompression(call.arguments, result)
    case "compression.status": compressionStatus(call.arguments, result)
    case "compression.cancel": cancelCompression(call.arguments, result)
    case "compression.thumbnail": compressionThumbnail(call.arguments, result)
    case "compression.playPreview": playCompressionPreview(call.arguments, result)
    case "compression.keep": keepCompressedCopy(call.arguments, result)
    case "compression.removeOriginal": removeCompressionOriginal(call.arguments, result)
    case "compression.discard": discardCompression(call.arguments, result)
    case "widget.update": updateWidget(call.arguments, result)
    case "history.read": result(readHistory())
    default: result(FlutterMethodNotImplemented)
    }
  }

  // MARK: Calendar

  private func calendarStatus(_ result: @escaping FlutterResult) {
    let status = EKEventStore.authorizationStatus(for: .event)
    DispatchQueue.main.async { result(self.calendarName(status)) }
  }

  private func requestCalendar(_ result: @escaping FlutterResult) {
    if #available(iOS 17.0, *) {
      eventStore.requestFullAccessToEvents { granted, error in
        DispatchQueue.main.async {
          result(["status": self.calendarName(EKEventStore.authorizationStatus(for: .event)),
                  "granted": granted, "error": error?.localizedDescription as Any? ?? NSNull()])
        }
      }
    } else {
      eventStore.requestAccess(to: .event) { granted, error in
        DispatchQueue.main.async {
          result(["status": self.calendarName(EKEventStore.authorizationStatus(for: .event)),
                  "granted": granted, "error": error?.localizedDescription as Any? ?? NSNull()])
        }
      }
    }
  }

  private func listEvents(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard calendarReadable else { result(FlutterError(code: "calendar_access", message: "Calendar access is unavailable. Allow full access in Settings to review events.", details: nil)); return }
    DispatchQueue.global(qos: .userInitiated).async {
      let now = Date()
      let start = Calendar.current.startOfDay(for: now)
      let predicate = self.eventStore.predicateForEvents(
        withStart: Self.calendarSearchStart(now: now), end: now, calendars: nil)
      let events = self.eventStore.events(matching: predicate).filter { $0.endDate < start }
      var rows = [[String: Any]]()
      for event in events {
        rows.append(self.eventRecord(event, kind: event.hasRecurrenceRules ? "repeated" : "old"))
      }
      DispatchQueue.main.async {
        guard self.calendarReadable else {
          result(FlutterError(code: "calendar_access", message: "Calendar access changed while loading events. Review access in Settings.", details: nil))
          return
        }
        result(["events": rows, "status": self.calendarName(EKEventStore.authorizationStatus(for: .event))])
      }
    }
  }

  private func eventRecord(_ event: EKEvent, kind: String) -> [String: Any] {
    ["id": event.eventIdentifier ?? "", "title": event.title ?? "Untitled event",
     "start": event.startDate.timeIntervalSince1970 * 1000,
     "end": event.endDate.timeIntervalSince1970 * 1000,
     "calendar": event.calendar.title, "calendarId": event.calendar.calendarIdentifier,
     "recurring": event.hasRecurrenceRules, "kind": kind]
  }

  private func deleteEvents(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard calendarReadable,
          let args = arguments as? [String: Any],
          let rows = args["events"] as? [[String: Any]], !rows.isEmpty else {
      result(FlutterError(code: "calendar_review_required", message: "Review at least one event before removing it.", details: nil)); return
    }
    var deleted = 0
    var failed = [[String: Any]]()
    for row in rows {
      guard let identifier = row["id"] as? String, !identifier.isEmpty,
            let milliseconds = row["start"] as? NSNumber,
            let title = row["title"] as? String,
            let calendarID = row["calendarId"] as? String else { continue }
      let occurrence = Date(timeIntervalSince1970: milliseconds.doubleValue / 1000)
      let fetchEnd = occurrence.addingTimeInterval(60)
      let predicate = eventStore.predicateForEvents(withStart: occurrence.addingTimeInterval(-60), end: fetchEnd, calendars: nil)
      let event = eventStore.events(matching: predicate).first {
        $0.eventIdentifier == identifier && abs($0.startDate.timeIntervalSince(occurrence)) < 1 &&
          $0.title == title && $0.calendar.calendarIdentifier == calendarID
      }
      guard let event else { failed.append(row); continue }
      do { try eventStore.remove(event, span: .thisEvent, commit: false); deleted += 1 }
      catch { failed.append(row) }
    }
    do { try eventStore.commit() }
    catch { result(FlutterError(code: "calendar_delete_failed", message: error.localizedDescription, details: nil)); return }
    appendHistory(category: "Calendar", count: deleted, bytes: 0, description: "Calendar occurrences removed")
    DispatchQueue.main.async { result(["deleted": deleted, "failed": failed]) }
  }

  private var calendarReadable: Bool {
    let status = EKEventStore.authorizationStatus(for: .event)
    if #available(iOS 17.0, *) { return status == .fullAccess }
    return status == .authorized
  }

  private func calendarName(_ status: EKAuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .restricted: return "restricted"
    case .denied: return "denied"
    case .authorized: return "authorized"
    case .fullAccess: return "authorized"
    case .writeOnly: return "writeOnly"
    @unknown default: return "unknown"
    }
  }

  // MARK: Private Vault

  private func authenticateVault(_ result: @escaping FlutterResult) {
    let context = LAContext()
    context.localizedCancelTitle = "Not Now"
    var policyError: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &policyError) else {
      result(FlutterError(code: "vault_auth_unavailable", message: policyError?.localizedDescription ?? "Set a device passcode to use Private Vault.", details: nil)); return
    }
    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your private Tidy Vault") { [weak self] success, error in
      guard let self, success else { DispatchQueue.main.async { result(FlutterError(code: "vault_auth_failed", message: error?.localizedDescription ?? "Authentication was cancelled.", details: nil)) }; return }
      self.vaultQueue.async {
        do {
          let key = try self.loadOrCreateVaultKey(context: context)
          UserDefaults.standard.set(true, forKey: Self.vaultConfiguredDefaultsKey)
          self.lock.lock(); self.vaultKey = key; self.vaultUnlocked = true; self.lock.unlock()
          let count = self.readVaultIndex().count
          DispatchQueue.main.async { result(["unlocked": true, "items": count]) }
        } catch { DispatchQueue.main.async { result(FlutterError(code: "vault_key", message: error.localizedDescription, details: nil)) } }
      }
    }
  }

  private static let vaultConfiguredDefaultsKey = "tidy.private-vault.configured.v1"

  private func vaultStatus(_ result: @escaping FlutterResult) {
    vaultQueue.async {
      let defaults = UserDefaults.standard
      var configured = defaults.bool(forKey: Self.vaultConfiguredDefaultsKey)
      if !configured {
        // Migrate Vaults created before the setup marker existed. Request only
        // Keychain attributes, never key material or an authentication prompt.
        let query: [String: Any] = [
          kSecClass as String: kSecClassGenericPassword,
          kSecAttrService as String: "com.example.tidy.private-vault",
          kSecAttrAccount as String: "vault-key",
          kSecReturnAttributes as String: true,
          kSecMatchLimit as String: kSecMatchLimitOne,
          kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        configured = status == errSecSuccess || status == errSecInteractionNotAllowed
        if configured { defaults.set(true, forKey: Self.vaultConfiguredDefaultsKey) }
      }
      DispatchQueue.main.async { result(configured) }
    }
  }

  private func loadOrCreateVaultKey(context: LAContext) throws -> SymmetricKey {
    let tag = Data("com.example.tidy.private-vault-key".utf8)
    let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "com.example.tidy.private-vault",
      kSecAttrAccount as String: "vault-key", kSecReturnData as String: true,
      kSecUseAuthenticationContext as String: context, kSecUseOperationPrompt as String: "Unlock your private Tidy Vault"]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess, let data = item as? Data { return SymmetricKey(data: data) }
    guard status == errSecItemNotFound else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    var bytes = Data(count: 32); let randomStatus = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
    guard randomStatus == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(randomStatus)) }
    var accessError: Unmanaged<CFError>?
    guard let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.userPresence], &accessError) else {
      throw accessError!.takeRetainedValue() as Error
    }
    let add: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "com.example.tidy.private-vault",
      kSecAttrAccount as String: "vault-key", kSecValueData as String: bytes,
      kSecAttrAccessControl as String: access]
    let addStatus = SecItemAdd(add as CFDictionary, nil)
    guard addStatus == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus)) }
    return SymmetricKey(data: bytes)
  }

  private func vaultList(_ result: @escaping FlutterResult) {
    vaultQueue.async {
      guard self.isVaultUnlocked else {
        DispatchQueue.main.async { result(FlutterError(code: "vault_locked", message: "Unlock the Vault to view private copies.", details: nil)) }
        return
      }
      let rows = self.readVaultIndex()
      DispatchQueue.main.async { result(rows) }
    }
  }

  private func vaultThumbnail(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let id = (arguments as? [String: Any])?["id"] as? String else {
      result(FlutterError(code: "invalid_arguments", message: "A Vault item identifier is required.", details: nil)); return
    }
    vaultQueue.async {
      do {
        guard self.isVaultUnlocked,
              let entry = self.readVaultIndex().first(where: { $0["id"] as? String == id }),
              let file = entry["file"] as? String,
              let key = self.currentVaultKey else {
          DispatchQueue.main.async { result(FlutterError(code: "vault_locked", message: "Unlock the Vault to view private copies.", details: nil)) }
          return
        }
        let sealed = try Data(contentsOf: self.vaultFolder.appendingPathComponent(file), options: .mappedIfSafe)
        let box = try AES.GCM.SealedBox(combined: sealed)
        let plain = try AES.GCM.open(box, using: key)
        guard let source = CGImageSourceCreateWithData(plain as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 512,
              ] as CFDictionary) else { throw NSError(domain: "TidyVault", code: 1) }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, "public.jpeg" as CFString, 1, nil) else {
          throw NSError(domain: "TidyVault", code: 2)
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.78] as CFDictionary)
        guard CGImageDestinationFinalize(destination), self.isVaultUnlocked else { throw NSError(domain: "TidyVault", code: 3) }
        let bytes = output as Data
        DispatchQueue.main.async { result(FlutterStandardTypedData(bytes: bytes)) }
      } catch {
        DispatchQueue.main.async { result(FlutterError(code: "vault_read", message: "This encrypted Vault copy could not be opened.", details: nil)) }
      }
    }
  }

  private func vaultAdd(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard isVaultUnlocked, let ids = (arguments as? [String: Any])?["ids"] as? [String], !ids.isEmpty,
          currentVaultKey != nil else { result(FlutterError(code: "vault_locked", message: "Unlock the Vault and select photos to add.", details: nil)); return }
    vaultQueue.async { [weak self] in
      guard let self else { return }
      let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
      var fetched = Set<String>(); assets.enumerateObjects { a, _, _ in if a.mediaType == .image { fetched.insert(a.localIdentifier) } }
      guard fetched == Set(ids) else {
        DispatchQueue.main.async { result(FlutterError(code: "vault_selection_changed", message: "Some selected photos are no longer accessible. Refresh your selection.", details: Array(Set(ids).subtracting(fetched)))) }
        return
      }
      guard self.isVaultUnlocked, let key = self.currentVaultKey else {
        DispatchQueue.main.async { result(FlutterError(code: "vault_locked", message: "Unlock the Vault and select photos to add.", details: nil)) }
        return
      }
      var entries = self.readVaultIndex()
      var added = 0
      do {
       for identifier in ids where !entries.contains(where: { $0["source"] as? String == identifier }) {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else { continue }
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first(where: { $0.type == .photo || $0.type == .fullSizePhoto }) else { continue }
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let options = PHAssetResourceRequestOptions(); options.isNetworkAccessAllowed = false
        let semaphore = DispatchSemaphore(value: 0); var transferError: Error?
        PHAssetResourceManager.default().writeData(for: resource, toFile: temp, options: options) { transferError = $0; semaphore.signal() }
        semaphore.wait()
        defer { try? FileManager.default.removeItem(at: temp) }
        if let transferError { throw transferError }
        let plain = try Data(contentsOf: temp)
        let sealed = try AES.GCM.seal(plain, using: key).combined!
        let id = UUID().uuidString
        let file = "\(id).sealed"
        try sealed.write(to: self.vaultFolder.appendingPathComponent(file), options: .atomic)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: self.vaultFolder.appendingPathComponent(file).path)
        let cipherBytes = (try? FileManager.default.attributesOfItem(atPath: self.vaultFolder.appendingPathComponent(file).path)[.size] as? NSNumber)?.intValue ?? 0
        entries.append(["id": id, "source": identifier, "file": file, "name": resource.originalFilename,
                        "created": (asset.creationDate ?? Date()).timeIntervalSince1970 * 1000,
                        "bytes": cipherBytes])
        added += 1
      }
       try self.writeVaultIndex(entries)
       DispatchQueue.main.async { result(["added": added, "items": entries.count]) }
      } catch { DispatchQueue.main.async { result(FlutterError(code: "vault_import_failed", message: error.localizedDescription, details: nil)) } }
    }
  }

  private func vaultDelete(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let ids = (arguments as? [String: Any])?["ids"] as? [String], !ids.isEmpty else {
      result(FlutterError(code: "vault_review_required", message: "Select private copies to review before removal.", details: nil)); return
    }
    vaultQueue.async {
      guard self.isVaultUnlocked else {
        DispatchQueue.main.async { result(FlutterError(code: "vault_locked", message: "Unlock the Vault before removing private copies.", details: nil)) }
        return
      }
      let idSet = Set(ids); var entries = self.readVaultIndex(); let targets = entries.filter { idSet.contains($0["id"] as? String ?? "") }
      guard targets.count == idSet.count else {
        DispatchQueue.main.async { result(FlutterError(code: "vault_selection_changed", message: "Some Vault copies changed. Review your selection again.", details: nil)) }
        return
      }
      var staged: [(entry: [String: Any], url: URL, bytes: Int64)] = []
      do {
        for entry in targets {
          guard let file = entry["file"] as? String else { throw NSError(domain: "TidyVault", code: 2) }
          let source = self.vaultFolder.appendingPathComponent(file)
          let size = (try FileManager.default.attributesOfItem(atPath: source.path)[.size] as? NSNumber)?.int64Value ?? 0
          let tombstone = self.vaultFolder.appendingPathComponent("\(file).pending-delete")
          try FileManager.default.moveItem(at: source, to: tombstone)
          staged.append((entry, tombstone, size))
        }
        entries.removeAll { idSet.contains($0["id"] as? String ?? "") }
        do { try self.writeVaultIndex(entries) }
        catch {
          for item in staged { try? FileManager.default.moveItem(at: item.url, to: self.vaultFolder.appendingPathComponent(item.entry["file"] as? String ?? "")) }
          throw error
        }
        var removedIDs = [String](); var freed: Int64 = 0; var failedEntries = [[String: Any]]()
        for item in staged {
          do {
            try FileManager.default.removeItem(at: item.url)
            if let id = item.entry["id"] as? String { removedIDs.append(id); freed += item.bytes }
            else { failedEntries.append(item.entry) }
          } catch {
            let original = self.vaultFolder.appendingPathComponent(item.entry["file"] as? String ?? "")
            if (try? FileManager.default.moveItem(at: item.url, to: original)) != nil { failedEntries.append(item.entry) }
          }
        }
        if !failedEntries.isEmpty { entries.append(contentsOf: failedEntries); try self.writeVaultIndex(entries) }
        self.appendHistory(category: "Vault Copies", count: removedIDs.count, bytes: freed, description: "Private Vault copies removed")
        DispatchQueue.main.async { result(["removed": removedIDs, "failed": failedEntries.count, "remaining": entries.count]) }
      } catch {
        DispatchQueue.main.async { result(FlutterError(code: "vault_remove_failed", message: error.localizedDescription, details: nil)) }
      }
    }
  }

  private var isVaultUnlocked: Bool { lock.lock(); defer { lock.unlock() }; return vaultUnlocked && vaultKey != nil }
  private var currentVaultKey: SymmetricKey? { lock.lock(); defer { lock.unlock() }; return vaultKey }

  private func readVaultIndex() -> [[String: Any]] {
    if let vaultEntriesCache { return vaultEntriesCache }
    guard let data = try? Data(contentsOf: vaultIndexURL, options: .mappedIfSafe), let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
      vaultEntriesCache = []
      return []
    }
    vaultEntriesCache = rows
    return rows
  }

  private func writeVaultIndex(_ rows: [[String: Any]]) throws {
    let data = try JSONSerialization.data(withJSONObject: rows)
    try data.write(to: vaultIndexURL, options: .atomic)
    try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: vaultIndexURL.path)
    var values = URLResourceValues(); values.isExcludedFromBackup = true
    var url = vaultIndexURL; try url.setResourceValues(values)
    vaultEntriesCache = rows
  }

  // MARK: Compression

  private func startCompression(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any], let id = args["assetId"] as? String,
          let quality = args["quality"] as? String, ["smaller", "balanced", "higher"].contains(quality),
          let asset = videoAsset(id) else { result(FlutterError(code: "compression_video_unavailable", message: "This video is no longer available in Photos.", details: nil)); return }
    let requiredSpace = max(0, (args["temporaryBytes"] as? NSNumber)?.int64Value ?? 0)
    let supportPath = FileManager.default.temporaryDirectory.path
    let availableSpace = (try? URL(fileURLWithPath: supportPath).resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage) ?? nil
    if let availableSpace, availableSpace < requiredSpace {
      result(FlutterError(code: "compression_low_storage", message: "There may not be enough temporary space for this estimated video copy. Your original is unchanged.", details: ["availableBytes": availableSpace, "requiredBytes": requiredSpace]))
      return
    }
    let options = PHVideoRequestOptions(); options.isNetworkAccessAllowed = false; options.deliveryMode = .highQualityFormat
    PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [weak self] avAsset, _, info in
      guard let self, let avAsset else {
        DispatchQueue.main.async { result(FlutterError(code: "compression_local_copy_required", message: (info?[PHImageResultIsInCloudKey] as? Bool) == true ? "This video is stored in iCloud and is not available locally for compression." : "The video could not be opened for compression.", details: nil)) }
        return
      }
      let preset = quality == "smaller" ? AVAssetExportPreset1280x720 : quality == "balanced" ? AVAssetExportPresetMediumQuality : AVAssetExportPresetHighestQuality
      guard let session = AVAssetExportSession(asset: avAsset, presetName: preset) else { DispatchQueue.main.async { result(FlutterError(code: "compression_unsupported", message: "iOS cannot export this video in the selected quality.", details: nil)) }; return }
      let supported = session.supportedFileTypes
      guard let fileType = supported.contains(.mov) ? AVFileType.mov as AVFileType? : supported.first else { DispatchQueue.main.async { result(FlutterError(code: "compression_unsupported", message: "iOS cannot create a playable video copy from this format.", details: nil)) }; return }
      let output = FileManager.default.temporaryDirectory.appendingPathComponent("tidy-compressed-\(UUID().uuidString).\(fileType == .mov ? "mov" : "mp4")")
      session.outputURL = output; session.outputFileType = fileType; session.shouldOptimizeForNetworkUse = false
      let jobID = UUID().uuidString
      let job = CompressionJob(id: jobID, session: session, fileURL: output, source: asset,
                               quality: quality, sourceCreated: asset.creationDate, sourceModified: asset.modificationDate)
      self.lock.lock(); self.exports[jobID] = job; self.lock.unlock()
      session.exportAsynchronously { [weak self] in
        guard let self else { return }
        if session.status == .completed {
          try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: output.path)
        }
        self.lock.lock(); job.finished = true; job.error = session.error?.localizedDescription; self.lock.unlock()
      }
      DispatchQueue.main.async { result(["jobId": jobID]) }
    }
  }

  private func compressionStatus(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let id = (arguments as? [String: Any])?["jobId"] as? String else { result(FlutterError(code: "compression_job", message: "Compression job is unavailable.", details: nil)); return }
    lock.lock(); let job = exports[id]; lock.unlock()
    guard let job else { result(FlutterError(code: "compression_job", message: "Compression job is no longer available.", details: nil)); return }
    let size = (try? FileManager.default.attributesOfItem(atPath: job.fileURL.path)[.size] as? NSNumber)?.int64Value
    result(["progress": Double(job.session.progress), "status": job.session.status == .completed ? "completed" : job.session.status == .cancelled ? "cancelled" : job.session.status == .failed ? "failed" : "running",
            "finished": job.finished, "error": job.error as Any? ?? NSNull(), "path": job.session.status == .completed ? job.fileURL.path as Any : NSNull(), "bytes": size as Any? ?? NSNull(),
            "quality": job.quality, "sourceId": job.source.localIdentifier])
  }

  private func cancelCompression(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let id = (arguments as? [String: Any])?["jobId"] as? String else { result(nil); return }
    lock.lock(); let job = exports[id]; lock.unlock(); job?.session.cancelExport()
    result(nil)
  }

  private func compressionThumbnail(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any] else { result(FlutterError(code: "compression_preview", message: "Preview is unavailable.", details: nil)); return }
    let generator: AVAssetImageGenerator
    if let path = args["path"] as? String { generator = AVAssetImageGenerator(asset: AVURLAsset(url: URL(fileURLWithPath: path))) }
    else if let id = args["assetId"] as? String, let asset = videoAsset(id) {
      let options = PHVideoRequestOptions(); options.isNetworkAccessAllowed = false
      PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { asset, _, _ in
        guard let asset, let image = self.previewImage(asset) else { DispatchQueue.main.async { result(NSNull()) }; return }
        DispatchQueue.main.async { result(FlutterStandardTypedData(bytes: image)) }
      }
      return
    } else { result(NSNull()); return }
    guard let image = previewImage(generator.asset) else { result(NSNull()); return }
    DispatchQueue.main.async { result(FlutterStandardTypedData(bytes: image)) }
  }

  private func previewImage(_ asset: AVAsset) -> Data? {
    let generator = AVAssetImageGenerator(asset: asset); generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: 720, height: 720)
    guard let cg = try? generator.copyCGImage(at: .zero, actualTime: nil) else { return nil }
    return UIImage(cgImage: cg).jpegData(compressionQuality: 0.82)
  }

  private func playCompressionPreview(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any] else { result(FlutterError(code: "compression_preview", message: "Video preview is unavailable.", details: nil)); return }
    if let path = args["path"] as? String {
      guard FileManager.default.fileExists(atPath: path) else { result(FlutterError(code: "compression_preview", message: "The compressed preview is no longer available.", details: nil)); return }
      DispatchQueue.main.async { self.presentPreview(AVPlayer(url: URL(fileURLWithPath: path)), result: result) }
      return
    }
    guard let id = args["assetId"] as? String, let asset = videoAsset(id) else { result(FlutterError(code: "compression_preview", message: "The original is no longer available in Photos.", details: nil)); return }
    let options = PHVideoRequestOptions(); options.isNetworkAccessAllowed = false
    PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [weak self] asset, _, _ in
      guard let self, let asset else { DispatchQueue.main.async { result(FlutterError(code: "compression_preview", message: "The original is not available locally for preview.", details: nil)) }; return }
      DispatchQueue.main.async { self.presentPreview(AVPlayer(playerItem: AVPlayerItem(asset: asset)), result: result) }
    }
  }

  private func presentPreview(_ player: AVPlayer, result: @escaping FlutterResult) {
    guard var presenter = UIApplication.shared.connectedScenes
      .compactMap({ ($0 as? UIWindowScene)?.windows.first(where: \.isKeyWindow)?.rootViewController }).first else {
      result(FlutterError(code: "compression_preview", message: "Video preview could not be opened.", details: nil)); return
    }
    while let presented = presenter.presentedViewController { presenter = presented }
    let controller = AVPlayerViewController(); controller.player = player
    presenter.present(controller, animated: true) { player.play(); result(nil) }
  }

  private func keepCompressedCopy(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any], let id = args["jobId"] as? String else { result(FlutterError(code: "compression_job", message: "Compressed copy is unavailable.", details: nil)); return }
    lock.lock(); let job = exports[id]; lock.unlock()
    guard let job, job.session.status == .completed,
          job.copySaved || FileManager.default.fileExists(atPath: job.fileURL.path) else { result(FlutterError(code: "compression_not_ready", message: "Wait for a verified compressed copy before saving it.", details: nil)); return }
    if job.copySaved { result(["saved": true]); return }
    PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: job.fileURL) }) { [weak self] success, error in
      guard let self, success, error == nil else { DispatchQueue.main.async { result(FlutterError(code: "compression_save_failed", message: error?.localizedDescription ?? "The compressed copy was not saved to Photos.", details: nil)) }; return }
      let retain = (args["retainForRemoval"] as? Bool) == true
      try? FileManager.default.removeItem(at: job.fileURL)
      self.lock.lock()
      job.copySaved = true
      if !retain { self.exports.removeValue(forKey: id) }
      self.lock.unlock()
      DispatchQueue.main.async { result(["saved": true]) }
    }
  }

  private func removeCompressionOriginal(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any], let id = args["jobId"] as? String else { result(FlutterError(code: "compression_job", message: "Reviewed original video is unavailable.", details: nil)); return }
    lock.lock(); let job = exports[id]; lock.unlock()
    guard let job, job.copySaved,
          let current = videoAsset(job.source.localIdentifier),
          current.creationDate == job.sourceCreated, current.modificationDate == job.sourceModified,
          current.pixelWidth == job.source.pixelWidth, current.pixelHeight == job.source.pixelHeight,
          abs(current.duration - job.source.duration) < 0.05 else {
      result(FlutterError(code: "compression_source_changed", message: "The original changed or is no longer accessible. Review it again before removal.", details: nil)); return
    }
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [current.localIdentifier], options: nil)
    PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.deleteAssets(assets) }) { [weak self] success, error in
      guard let self else { return }
      let remaining = PHAsset.fetchAssets(withLocalIdentifiers: [current.localIdentifier], options: nil).count
      let removed = success && error == nil && remaining == 0
      if removed {
        let bytes = (args["originalBytes"] as? NSNumber)?.int64Value
        self.appendHistory(category: "Videos", count: 1, bytes: bytes, description: "Original video removed after compression")
        self.lock.lock(); self.exports.removeValue(forKey: id); self.lock.unlock()
      }
      DispatchQueue.main.async { result(["removed": removed, "error": error?.localizedDescription as Any? ?? NSNull()]) }
    }
  }

  private func discardCompression(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let id = (arguments as? [String: Any])?["jobId"] as? String else { result(nil); return }
    lock.lock(); let job = exports.removeValue(forKey: id); lock.unlock()
    job?.session.cancelExport(); try? FileManager.default.removeItem(at: job?.fileURL ?? URL(fileURLWithPath: "/nonexistent")); result(nil)
  }

  private func videoAsset(_ id: String) -> PHAsset? {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    guard status == .authorized || status == .limited else { return nil }
    let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
    guard let asset = result.firstObject, asset.mediaType == .video else { return nil }
    return asset
  }

  private func cleanOrphanedCompressionFiles() {
    guard let files = try? FileManager.default.contentsOfDirectory(at: FileManager.default.temporaryDirectory, includingPropertiesForKeys: nil) else { return }
    for file in files where file.lastPathComponent.hasPrefix("tidy-compressed-") { try? FileManager.default.removeItem(at: file) }
  }

  private func recoverPendingVaultRemovals() {
    let indexedFiles = Set(readVaultIndex().compactMap { $0["file"] as? String })
    guard let files = try? FileManager.default.contentsOfDirectory(at: vaultFolder, includingPropertiesForKeys: nil) else { return }
    let suffix = ".pending-delete"
    for tombstone in files where tombstone.lastPathComponent.hasSuffix(suffix) {
      let originalName = String(tombstone.lastPathComponent.dropLast(suffix.count))
      let original = vaultFolder.appendingPathComponent(originalName)
      if indexedFiles.contains(originalName) {
        if !FileManager.default.fileExists(atPath: original.path) {
          try? FileManager.default.moveItem(at: tombstone, to: original)
        }
      } else {
        try? FileManager.default.removeItem(at: tombstone)
      }
    }
  }

  // MARK: Widgets and local history

  private func updateWidget(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard let values = arguments as? [String: Any],
          let defaults = UserDefaults(suiteName: groupID) else { result(FlutterError(code: "widget_unavailable", message: "Tidy’s Home Screen widget storage is unavailable.", details: nil)); return }
    defaults.set(values, forKey: "tidy.widget.summary")
    if #available(iOS 14.0, *) { WidgetCenter.shared.reloadAllTimelines() }
    result(["updated": true])
  }

  private func readHistory() -> [[String: Any]] {
    guard let data = try? Data(contentsOf: historyURL), let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
    return rows.sorted { (($0["date"] as? NSNumber)?.doubleValue ?? 0) > (($1["date"] as? NSNumber)?.doubleValue ?? 0) }
  }

  private func appendHistory(category: String, count: Int, bytes: Int64?, description: String) {
    guard count > 0 else { return }
    var rows = readHistory()
    rows.insert(["id": UUID().uuidString, "category": category, "count": count, "bytes": bytes as Any? ?? NSNull(),
                 "description": description, "date": Date().timeIntervalSince1970 * 1000], at: 0)
    rows = Array(rows.prefix(100))
    if let data = try? JSONSerialization.data(withJSONObject: rows) {
      try? data.write(to: historyURL, options: .atomic)
      try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: historyURL.path)
      var values = URLResourceValues(); values.isExcludedFromBackup = true
      var url = historyURL; try? url.setResourceValues(values)
    }
  }
}

private final class CompressionJob {
  let id: String
  let session: AVAssetExportSession
  let fileURL: URL
  let source: PHAsset
  let quality: String
  let sourceCreated: Date?
  let sourceModified: Date?
  var finished = false
  var error: String?
  var copySaved = false
  init(id: String, session: AVAssetExportSession, fileURL: URL, source: PHAsset, quality: String, sourceCreated: Date?, sourceModified: Date?) {
    self.id = id; self.session = session; self.fileURL = fileURL; self.source = source
    self.quality = quality; self.sourceCreated = sourceCreated; self.sourceModified = sourceModified
  }
}
