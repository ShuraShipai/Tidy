import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let onboardingService = OnboardingNativeService()
  private let libraryScan = LibraryScanService()
  private let photoLibraryService = PhotoLibraryNativeService()
  private let contactsService = ContactsNativeService()
  private let videoLibraryService = VideoLibraryNativeService()
  private let settingsService = SettingsNativeService()
  private let groupEightService = GroupEightNativeService()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TidyLibraryScan")!
    let channel = FlutterMethodChannel(name: "tidy/device_library", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { [libraryScan] call, result in libraryScan.handle(call, result: result) }
    let photosRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "TidyPhotos")!
    let photosChannel = FlutterMethodChannel(name: "tidy/photos", binaryMessenger: photosRegistrar.messenger())
    photosChannel.setMethodCallHandler { [photoLibraryService] call, result in photoLibraryService.handle(call, result: result) }
    let videosRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "TidyVideos")!
    videoLibraryService.register(with: videosRegistrar)
    let contactsRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "TidyContacts")!
    let contactsChannel = FlutterMethodChannel(name: "tidy/contacts", binaryMessenger: contactsRegistrar.messenger())
    contactsChannel.setMethodCallHandler { [contactsService] call, result in contactsService.handle(call, result: result) }
    onboardingService.register(messenger: engineBridge.applicationRegistrar.messenger())
    settingsService.register(messenger: engineBridge.applicationRegistrar.messenger())
    groupEightService.register(messenger: engineBridge.applicationRegistrar.messenger())
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    groupEightService.lockVault()
    super.applicationDidEnterBackground(application)
  }
}
