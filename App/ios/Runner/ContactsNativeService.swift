import Contacts
import CryptoKit
import Flutter
import Foundation

final class ContactsNativeService {
  private let store = CNContactStore()

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "read": read(result)
    case "merge": merge(call.arguments as? [String: Any] ?? [:], result)
    case "delete": delete(call.arguments as? [String: Any] ?? [:], result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func status() -> String {
    let authorization = CNContactStore.authorizationStatus(for: .contacts)
    if #available(iOS 18.0, *), authorization == .limited { return "limited" }
    switch authorization {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    default: return "unsupported"
    }
  }

  private let keys: [CNKeyDescriptor] = [CNContactIdentifierKey as CNKeyDescriptor,
    CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor,
    CNContactOrganizationNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor,
    CNContactEmailAddressesKey as CNKeyDescriptor, CNContactPostalAddressesKey as CNKeyDescriptor,
    CNContactUrlAddressesKey as CNKeyDescriptor, CNContactSocialProfilesKey as CNKeyDescriptor,
    CNContactInstantMessageAddressesKey as CNKeyDescriptor, CNContactRelationsKey as CNKeyDescriptor,
    CNContactDatesKey as CNKeyDescriptor, CNContactBirthdayKey as CNKeyDescriptor,
    CNContactNoteKey as CNKeyDescriptor, CNContactImageDataKey as CNKeyDescriptor]

  private func read(_ result: @escaping FlutterResult) {
    let access = status()
    guard access == "authorized" || access == "limited" else {
      DispatchQueue.main.async { result(["status": access, "contacts": []]) }; return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let request = CNContactFetchRequest(keysToFetch: self.keys); request.unifyResults = false
        var records = [[String: Any]]()
        try self.store.enumerateContacts(with: request) { c, _ in records.append(self.map(c)) }
        DispatchQueue.main.async { result(["status": access, "contacts": records]) }
      } catch { DispatchQueue.main.async { result(FlutterError(code: "read_failed", message: error.localizedDescription, details: nil)) } }
    }
  }

  private func map(_ c: CNContact) -> [String: Any] {
    let data: [String: Any] = ["id": c.identifier, "givenName": c.givenName, "familyName": c.familyName,
      "organization": c.organizationName, "phones": c.phoneNumbers.map { $0.value.stringValue },
      "emails": c.emailAddresses.map { $0.value as String }]
    return data.merging(["version": fingerprint(c)]) { _, new in new }
  }

  private func fingerprint(_ c: CNContact) -> String {
    let details: [String: Any] = ["given": c.givenName, "family": c.familyName, "org": c.organizationName,
      "phones": c.phoneNumbers.map { "\($0.label ?? ""):\($0.value.stringValue)" },
      "emails": c.emailAddresses.map { "\($0.label ?? ""):\($0.value as String)" },
      "addresses": c.postalAddresses.map { "\($0.value)" }, "urls": c.urlAddresses.map { $0.value as String },
      "social": c.socialProfiles.map { "\($0.value)" }, "im": c.instantMessageAddresses.map { "\($0.value)" },
      "relations": c.contactRelations.map { "\($0.value)" }, "dates": c.dates.map { "\($0.value)" },
      "birthday": c.birthday.map { "\($0)" } ?? "", "note": c.note,
      "image": c.imageData?.base64EncodedString() ?? ""]
    let bytes = (try? JSONSerialization.data(withJSONObject: details, options: [.sortedKeys])) ?? Data()
    return SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
  }

  private func fetch(_ id: String) throws -> CNContact {
    try store.unifiedContact(withIdentifier: id, keysToFetch: keys)
  }

  private func merge(_ args: [String: Any], _ result: @escaping FlutterResult) {
    guard status() == "authorized" || status() == "limited" else { result(FlutterError(code: "access_changed", message: "Contacts access is no longer available.", details: nil)); return }
    guard let keeperID = args["keeper"] as? String, let otherID = args["other"] as? String,
      let versions = args["versions"] as? [String: String] else { result(FlutterError(code: "invalid_request", message: "The reviewed contacts are incomplete.", details: nil)); return }
    do {
      let original = try fetch(keeperID), source = try fetch(otherID)
      guard fingerprint(original) == versions[keeperID], fingerprint(source) == versions[otherID] else {
        result(FlutterError(code: "changed", message: "A contact changed since review. Compare the current records again.", details: nil)); return
      }
      // Preserve every unique supported multi-value field. Singular notes or birthdays
      // that conflict cannot be represented without loss, so require renewed review.
      if !original.note.isEmpty && !source.note.isEmpty && original.note != source.note {
        result(FlutterError(code: "conflict", message: "These contacts have different notes. Keep them separate to avoid losing either note.", details: nil)); return
      }
      if let a = original.birthday, let b = source.birthday, a != b {
        result(FlutterError(code: "conflict", message: "These contacts have different birthdays. Keep them separate to avoid losing either date.", details: nil)); return
      }
      let mutable = original.mutableCopy() as! CNMutableContact
      mutable.givenName = args["givenName"] as? String ?? original.givenName
      mutable.familyName = args["familyName"] as? String ?? original.familyName
      mutable.organizationName = args["organization"] as? String ?? original.organizationName
      mutable.phoneNumbers = self.unique(original.phoneNumbers + source.phoneNumbers) { "\($0.value.stringValue.filter(\.isNumber))" }
      mutable.emailAddresses = self.unique(original.emailAddresses + source.emailAddresses) { String($0.value).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
      mutable.postalAddresses = self.unique(original.postalAddresses + source.postalAddresses) { "\($0.value)" }
      mutable.urlAddresses = self.unique(original.urlAddresses + source.urlAddresses) { String($0.value).lowercased() }
      mutable.socialProfiles = self.unique(original.socialProfiles + source.socialProfiles) { "\($0.value)" }
      mutable.instantMessageAddresses = self.unique(original.instantMessageAddresses + source.instantMessageAddresses) { "\($0.value)" }
      mutable.contactRelations = self.unique(original.contactRelations + source.contactRelations) { "\($0.value)" }
      mutable.dates = self.unique(original.dates + source.dates) { "\($0.value)" }
      if mutable.note.isEmpty { mutable.note = source.note }
      if mutable.birthday == nil { mutable.birthday = source.birthday }
      if mutable.imageData == nil { mutable.imageData = source.imageData }
      let request = CNSaveRequest(); request.update(mutable); request.delete(source)
      try store.execute(request)
      DispatchQueue.main.async { result(nil) }
    } catch { DispatchQueue.main.async { result(FlutterError(code: "merge_failed", message: error.localizedDescription, details: nil)) } }
  }

  private func unique<T>(_ items: [T], key: (T) -> String) -> [T] {
    var seen = Set<String>(); return items.filter { seen.insert(key($0)).inserted }
  }

  private func delete(_ args: [String: Any], _ result: @escaping FlutterResult) {
    guard status() == "authorized" || status() == "limited" else { result(FlutterError(code: "access_changed", message: "Contacts access is no longer available.", details: nil)); return }
    guard let records = args["records"] as? [[String: String]], !records.isEmpty else { result(FlutterError(code: "invalid_request", message: "Select at least one contact to delete.", details: nil)); return }
    do {
      let request = CNSaveRequest()
      for item in records {
        guard let id = item["id"], let version = item["version"] else { throw NSError(domain: "TidyContacts", code: 1, userInfo: [NSLocalizedDescriptionKey: "A selected contact is incomplete."]) }
        let c = try fetch(id)
        guard fingerprint(c) == version else { throw NSError(domain: "TidyContacts", code: 2, userInfo: [NSLocalizedDescriptionKey: "A selected contact changed since review. Review it again before deleting."]) }
        request.delete(c.mutableCopy() as! CNMutableContact)
      }
      try store.execute(request); DispatchQueue.main.async { result(nil) }
    } catch { DispatchQueue.main.async { result(FlutterError(code: "delete_failed", message: error.localizedDescription, details: nil)) } }
  }
}
