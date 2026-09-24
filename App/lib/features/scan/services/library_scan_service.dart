import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryScanService {
  const LibraryScanService();
  static const channel = MethodChannel('tidy/device_library');
  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  Future<void> start() {
    if (!supported) {
      throw UnsupportedError(
        'Scanning requires iOS Photos and Contacts access.',
      );
    }
    return channel.invokeMethod<void>('start');
  }

  Future<void> cancel() => channel.invokeMethod<void>('cancel');
  Future<Map<Object?, Object?>> status([int? serial]) async =>
      (await channel.invokeMapMethod<Object?, Object?>('status', serial))!;
}

final libraryScanServiceProvider = Provider(
  (ref) => const LibraryScanService(),
);
