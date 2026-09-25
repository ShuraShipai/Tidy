import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/contact_record.dart';

class ContactsService {
  static const _channel = MethodChannel('tidy/contacts');
  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  Future<Map<String, Object?>> read() async {
    if (!supported) {
      return {'status': 'unsupported', 'contacts': <ContactRecord>[]};
    }
    final result =
        await _channel.invokeMapMethod<Object?, Object?>('read') ?? {};
    return {
      'status': result['status'] as String? ?? 'error',
      'contacts': ((result['contacts'] as List?) ?? const [])
          .map(
            (e) => ContactRecord.fromMap(Map<Object?, Object?>.from(e as Map)),
          )
          .toList(),
    };
  }

  Future<void> merge(
    ContactRecord keeper,
    ContactRecord other, {
    required String givenName,
    required String familyName,
    required String organization,
    required List<String> phones,
    required List<String> emails,
    required bool acknowledgeUnreadableNotes,
  }) async {
    await _channel.invokeMethod<void>('merge', {
      'keeper': keeper.id,
      'other': other.id,
      'versions': {keeper.id: keeper.version, other.id: other.version},
      'givenName': givenName,
      'familyName': familyName,
      'organization': organization,
      'phones': phones,
      'emails': emails,
      'acknowledgeUnreadableNotes': acknowledgeUnreadableNotes,
    });
  }

  Future<void> delete(List<ContactRecord> records) async =>
      _channel.invokeMethod<void>('delete', {
        'records': records
            .map((c) => {'id': c.id, 'version': c.version})
            .toList(),
      });
}
