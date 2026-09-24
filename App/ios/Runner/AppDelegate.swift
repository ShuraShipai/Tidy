import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let onboardingService = OnboardingNativeService()
  private let libraryScan = LibraryScanService()

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
    onboardingService.register(messenger: engineBridge.applicationRegistrar.messenger())
  }
}
