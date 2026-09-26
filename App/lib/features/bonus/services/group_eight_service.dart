import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupEightServiceProvider = Provider<GroupEightService>(
  (ref) => const GroupEightService(),
);

/// On-device bridge for Group 08's optional features.
class GroupEightService {
  const GroupEightService();

  static const MethodChannel _channel = MethodChannel('tidy/group_eight');
  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<String> calendarStatus() async =>
      await _channel.invokeMethod<String>('calendar.status') ?? 'unknown';

  Future<Map<String, Object?>> requestCalendar() async =>
      _map(await _channel.invokeMethod<Object?>('calendar.request'));

  Future<bool> openCalendarSettings() async =>
      await _channel.invokeMethod<bool>('calendar.openSettings') ?? false;

  Future<List<Map<String, Object?>>> calendarEvents() async => _rows(
    (await _channel.invokeMapMethod<Object?, Object?>(
      'calendar.list',
    ))?['events'],
  );

  Future<Map<String, Object?>> deleteCalendarEvents(
    List<Map<String, Object?>> events,
  ) async => _map(
    await _channel.invokeMethod<Object?>('calendar.delete', {'events': events}),
  );

  Future<Map<String, Object?>> authenticateVault() async =>
      _map(await _channel.invokeMethod<Object?>('vault.authenticate'));

  Future<bool> vaultIsConfigured() async =>
      await _channel.invokeMethod<bool>('vault.status') ?? false;

  Future<void> lockVault() => _channel.invokeMethod<void>('vault.lock');

  Future<List<Map<String, Object?>>> vaultItems() async =>
      _rows(await _channel.invokeMethod<Object?>('vault.list'));

  Future<Uint8List?> vaultThumbnail(String id) async =>
      _channel.invokeMethod<Uint8List?>('vault.thumbnail', {'id': id});

  Future<Map<String, Object?>> addVaultItems(List<String> ids) async =>
      _map(await _channel.invokeMethod<Object?>('vault.add', {'ids': ids}));

  Future<Map<String, Object?>> removeVaultItems(List<String> ids) async =>
      _map(await _channel.invokeMethod<Object?>('vault.delete', {'ids': ids}));

  Future<String> startCompression({
    required String assetId,
    required String quality,
    required int temporaryBytes,
  }) async {
    final response = _map(
      await _channel.invokeMethod<Object?>('compression.start', {
        'assetId': assetId,
        'quality': quality,
        'temporaryBytes': temporaryBytes,
      }),
    );
    return response['jobId']! as String;
  }

  Future<Map<String, Object?>> compressionStatus(String jobId) async => _map(
    await _channel.invokeMethod<Object?>('compression.status', {
      'jobId': jobId,
    }),
  );

  Future<void> cancelCompression(String jobId) =>
      _channel.invokeMethod<void>('compression.cancel', {'jobId': jobId});

  Future<void> keepCompressedCopy(
    String jobId, {
    bool retainForRemoval = false,
  }) async {
    await _channel.invokeMethod<void>('compression.keep', {
      'jobId': jobId,
      'retainForRemoval': retainForRemoval,
    });
  }

  Future<Map<String, Object?>> removeCompressedOriginal(
    String jobId, {
    required int? originalBytes,
  }) async => _map(
    await _channel.invokeMethod<Object?>('compression.removeOriginal', {
      'jobId': jobId,
      'originalBytes': originalBytes,
    }),
  );

  Future<Uint8List?> compressionThumbnail({
    String? assetId,
    String? path,
  }) async => _channel.invokeMethod<Uint8List?>('compression.thumbnail', {
    'assetId': assetId,
    'path': path,
  });

  Future<void> playCompressionPreview({String? assetId, String? path}) =>
      _channel.invokeMethod<void>('compression.playPreview', {
        'assetId': assetId,
        'path': path,
      });

  Future<void> discardCompression(String jobId) =>
      _channel.invokeMethod<void>('compression.discard', {'jobId': jobId});

  Future<void> updateWidgetSummary(Map<String, Object?> summary) async {
    final propertyListValues = Map<String, Object?>.from(summary)
      ..removeWhere((key, value) => value == null);
    await _channel.invokeMethod<Object?>('widget.update', propertyListValues);
  }

  Future<List<Map<String, Object?>>> history() async =>
      _rows(await _channel.invokeMethod<Object?>('history.read'));

  Future<void> recordCleanupHistory(List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return;
    await _channel.invokeMethod<void>('history.recordCleanup', {'rows': rows});
  }

  static Map<String, Object?> _map(Object? value) => value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value))
      : <String, Object?>{};

  static List<Map<String, Object?>> _rows(Object? value) => value is List
      ? value.whereType<Map>().map(_map).toList(growable: false)
      : const [];
}
