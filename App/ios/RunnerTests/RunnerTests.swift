import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  func testOnboardingCompletionPersistsAndIsExcludedFromBackup() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("TidyOnboardingTest-" + UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let service = OnboardingNativeService(storageDirectory: directory)
    var read: Any?
    service.handle(FlutterMethodCall(methodName: "readCompleted", arguments: nil)) { read = $0 }
    XCTAssertEqual(read as? Bool, false)
    var saved = false
    service.handle(FlutterMethodCall(methodName: "saveCompleted", arguments: nil)) {
      XCTAssertNil($0)
      saved = true
    }
    XCTAssertTrue(saved)
    let relaunched = OnboardingNativeService(storageDirectory: directory)
    relaunched.handle(FlutterMethodCall(methodName: "readCompleted", arguments: nil)) { read = $0 }
    XCTAssertEqual(read as? Bool, true)
    let values = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
    XCTAssertEqual(values.isExcludedFromBackup, true)
  }

  func testUnknownPermissionDoesNotRequestAuthorization() {
    let service = OnboardingNativeService()
    var error: FlutterError?
    service.handle(FlutterMethodCall(methodName: "request", arguments: "unsupported")) {
      error = $0 as? FlutterError
    }
    XCTAssertEqual(error?.code, "invalid_subject")
  }

  func testCalendarSearchWindowIncludesRecentEventsWithoutExceedingEventKitLimit() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let start = GroupEightNativeService.calendarSearchStart(now: now)
    XCTAssertLessThan(start, now.addingTimeInterval(-24 * 60 * 60))
    XCTAssertEqual(now.timeIntervalSince(start), GroupEightNativeService.calendarLookback)
    XCTAssertLessThan(now.timeIntervalSince(start), 4 * 366 * 24 * 60 * 60)
  }

}
