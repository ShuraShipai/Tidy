import AVFoundation
import Flutter
import Photos
import UIKit

/// PhotoKit and AVFoundation bridge for the read and reviewed-delete video flow.
final class VideoLibraryNativeService {
  func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "tidy/videos",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    registrar.register(
      VideoPlayerPlatformViewFactory(messenger: registrar.messenger()),
      withId: "tidy/videos/player"
    )
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "preview":
      preview(call.arguments, result: result)
    case "details":
      details(call.arguments, result: result)
    case "delete":
      delete(call.arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func preview(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any], let identifier = args["id"] as? String else {
      result(FlutterError(code: "invalid_arguments", message: "A video identifier is required.", details: nil))
      return
    }
    guard canReadVideos else {
      result(FlutterError(code: "videos_unavailable", message: "Video access is unavailable or has changed.", details: nil))
      return
    }
    guard let asset = video(identifier) else {
      result(FlutterError(code: "video_unavailable", message: "This video is no longer accessible.", details: nil))
      return
    }
    let width = max(96, min((args["width"] as? NSNumber)?.doubleValue ?? 480, 1200))
    let height = max(96, min((args["height"] as? NSNumber)?.doubleValue ?? 480, 1800))
    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = false
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .fast
    options.version = .current
    PHImageManager.default().requestImage(
      for: asset,
      targetSize: CGSize(width: width, height: height),
      contentMode: .aspectFill,
      options: options
    ) { image, info in
      if (info?[PHImageResultIsDegradedKey] as? Bool) == true { return }
      let thumbnail = image?.jpegData(compressionQuality: 0.84)
      let fileName = Self.fileName(for: asset)
      DispatchQueue.main.async {
        result(["thumbnail": thumbnail.map(FlutterStandardTypedData.init(bytes:)) as Any? ?? NSNull(),
                "fileName": fileName as Any? ?? NSNull()])
      }
    }
  }

  private func details(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any], let identifier = args["id"] as? String else {
      result(FlutterError(code: "invalid_arguments", message: "A video identifier is required.", details: nil))
      return
    }
    guard canReadVideos, let asset = video(identifier) else {
      result(FlutterError(code: "video_unavailable", message: "This video is no longer accessible.", details: nil))
      return
    }
    let fileName = Self.fileName(for: asset)
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = false
    options.deliveryMode = .highQualityFormat
    PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
      guard let avAsset else {
        DispatchQueue.main.async {
          result(["fileName": fileName as Any? ?? NSNull(), "frameRate": NSNull()])
        }
        return
      }
      Task {
        var frameRate: Float?
        if let tracks = try? await avAsset.loadTracks(withMediaType: .video),
           let track = tracks.first {
          frameRate = try? await track.load(.nominalFrameRate)
        }
        DispatchQueue.main.async {
          result(["fileName": fileName as Any? ?? NSNull(),
                  "frameRate": frameRate.map(NSNumber.init(value:)) as Any? ?? NSNull(),
                  "local": (info?[PHImageResultIsInCloudKey] as? Bool) != true])
        }
      }
    }
  }

  private func delete(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let args = arguments as? [String: Any], let records = args["records"] as? [[String: Any]] else {
      result(FlutterError(code: "invalid_arguments", message: "Reviewed video records are required.", details: nil))
      return
    }
    let identifiers = Set(records.compactMap { $0["id"] as? String })
    guard !identifiers.isEmpty, identifiers.count == records.count else {
      result(FlutterError(code: "empty_selection", message: "Select videos to review before deleting.", details: nil))
      return
    }
    guard canReadVideos else {
      result(FlutterError(code: "videos_unavailable", message: "Video access changed. Review your selection again.", details: nil))
      return
    }
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: Array(identifiers), options: nil)
    var fetchedIDs = Set<String>()
    var allVideos = true
    var changedIDs = Set<String>()
    let expected = Dictionary(uniqueKeysWithValues: records.compactMap { record in
      (record["id"] as? String).map { ($0, record) }
    })
    assets.enumerateObjects { asset, _, _ in
      fetchedIDs.insert(asset.localIdentifier)
      if asset.mediaType != .video { allVideos = false }
      guard let version = expected[asset.localIdentifier] else { return }
      if !Self.dateMatches(version["createdAt"], asset.creationDate) ||
          !Self.dateMatches(version["modifiedAt"], asset.modificationDate) ||
          (version["width"] as? NSNumber)?.intValue != asset.pixelWidth ||
          (version["height"] as? NSNumber)?.intValue != asset.pixelHeight ||
          abs(((version["duration"] as? NSNumber)?.doubleValue ?? -1) - asset.duration) > 0.05 {
        changedIDs.insert(asset.localIdentifier)
      }
    }
    guard fetchedIDs == identifiers, allVideos, changedIDs.isEmpty else {
      result(FlutterError(
        code: "selection_changed",
        message: "A selected video changed or is no longer available. Review the current library before continuing.",
        details: Array(identifiers.subtracting(fetchedIDs).union(changedIDs))
      ))
      return
    }

    PHPhotoLibrary.shared().performChanges({
      PHAssetChangeRequest.deleteAssets(assets)
    }) { success, error in
      let remainingAssets = PHAsset.fetchAssets(withLocalIdentifiers: Array(identifiers), options: nil)
      var remaining = Set<String>()
      remainingAssets.enumerateObjects { asset, _, _ in remaining.insert(asset.localIdentifier) }
      let deleted = identifiers.subtracting(remaining)
      DispatchQueue.main.async {
        result([
          "succeeded": success && error == nil,
          "deleted": Array(deleted),
          "remaining": Array(remaining),
          "error": error?.localizedDescription as Any? ?? NSNull()
        ])
      }
    }
  }

  fileprivate func video(_ identifier: String) -> PHAsset? {
    guard canReadVideos else { return nil }
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
    guard let asset = assets.firstObject, asset.mediaType == .video else { return nil }
    return asset
  }

  fileprivate var canReadVideos: Bool {
    let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    return status == .authorized || status == .limited
  }

  private static func fileName(for asset: PHAsset) -> String? {
    PHAssetResource.assetResources(for: asset)
      .first(where: { $0.type == .video || $0.type == .fullSizeVideo })?
      .originalFilename
  }

  private static func dateMatches(_ expected: Any?, _ actual: Date?) -> Bool {
    guard let expected = expected as? NSNumber else { return actual == nil }
    guard let actual else { return false }
    return Int64((actual.timeIntervalSince1970 * 1000).rounded()) == expected.int64Value
  }
}

private final class VideoPlayerPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  private let service = VideoLibraryNativeService()

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    let identifier = (args as? [String: Any])?["id"] as? String ?? ""
    return VideoPlayerPlatformView(
      frame: frame,
      viewId: viewId,
      identifier: identifier,
      messenger: messenger,
      service: service
    )
  }
}

private final class PlayerLayerView: UIView {
  override class var layerClass: AnyClass { AVPlayerLayer.self }
  var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

private final class VideoPlayerPlatformView: NSObject, FlutterPlatformView, FlutterStreamHandler {
  private let container: PlayerLayerView
  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private let identifier: String
  private let service: VideoLibraryNativeService
  private var player: AVPlayer?
  private var itemObservation: NSKeyValueObservation?
  private var periodicObserver: Any?
  private var eventSink: FlutterEventSink?
  private var lastEvent: [String: Any] = ["ready": false, "position": 0.0, "duration": 0.0]

  init(
    frame: CGRect,
    viewId: Int64,
    identifier: String,
    messenger: FlutterBinaryMessenger,
    service: VideoLibraryNativeService
  ) {
    container = PlayerLayerView(frame: frame)
    self.identifier = identifier
    self.service = service
    methodChannel = FlutterMethodChannel(name: "tidy/videos/player/\(viewId)", binaryMessenger: messenger)
    eventChannel = FlutterEventChannel(name: "tidy/videos/events/\(viewId)", binaryMessenger: messenger)
    super.init()
    container.backgroundColor = UIColor(red: 0.12, green: 0.11, blue: 0.15, alpha: 1)
    container.playerLayer.videoGravity = .resizeAspect
    methodChannel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result: result) }
    eventChannel.setStreamHandler(self)
    loadAsset()
  }

  func view() -> UIView { container }

  private func loadAsset() {
    guard let asset = service.video(identifier) else {
      publish(["ready": false, "error": "This video is no longer accessible."])
      return
    }
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = false
    options.deliveryMode = .highQualityFormat
    PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [weak self] avAsset, _, _ in
      guard let self else { return }
      DispatchQueue.main.async {
        guard let avAsset else {
          self.publish(["ready": false, "error": "This video is not available locally for playback."])
          return
        }
        let item = AVPlayerItem(asset: avAsset)
        let player = AVPlayer(playerItem: item)
        self.player = player
        self.container.playerLayer.player = player
        self.itemObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
          DispatchQueue.main.async {
            guard let self else { return }
            if item.status == .readyToPlay {
              self.publish(["ready": true, "duration": item.duration.seconds.isFinite ? item.duration.seconds : 0.0])
            } else if item.status == .failed {
              self.publish(["ready": false, "error": item.error?.localizedDescription ?? "Video playback failed."])
            }
          }
        }
        self.periodicObserver = player.addPeriodicTimeObserver(
          forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
          queue: .main
        ) { [weak self] time in
          guard let self else { return }
          self.publish([
            "ready": item.status == .readyToPlay,
            "playing": player.timeControlStatus == .playing,
            "position": time.seconds.isFinite ? time.seconds : 0.0,
            "duration": item.duration.seconds.isFinite ? item.duration.seconds : 0.0
          ])
        }
      }
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let player else {
      result(FlutterError(code: "player_not_ready", message: "Video playback is not ready.", details: nil))
      return
    }
    switch call.method {
    case "play":
      player.play()
      publish(["playing": true])
      result(nil)
    case "pause":
      player.pause()
      publish(["playing": false])
      result(nil)
    case "seek":
      let seconds = (call.arguments as? NSNumber)?.doubleValue ?? 0
      let duration = player.currentItem?.duration.seconds ?? 0
      let target = min(max(0, seconds), duration.isFinite ? duration : 0)
      player.seek(to: CMTime(seconds: target, preferredTimescale: 600)) { [weak self] _ in
        self?.publish(["position": target])
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func publish(_ event: [String: Any]) {
    lastEvent.merge(event) { _, next in next }
    if Thread.isMainThread {
      eventSink?(lastEvent)
    } else {
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        self.eventSink?(self.lastEvent)
      }
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    events(lastEvent)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  deinit {
    if let periodicObserver, let player { player.removeTimeObserver(periodicObserver) }
    player?.pause()
    container.playerLayer.player = nil
    methodChannel.setMethodCallHandler(nil)
    eventChannel.setStreamHandler(nil)
  }
}
