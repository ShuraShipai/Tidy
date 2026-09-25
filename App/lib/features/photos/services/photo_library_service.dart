import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PhotoDeletionOutcome {
  const PhotoDeletionOutcome({
    required this.succeeded,
    required this.deletedIds,
    required this.remainingIds,
    this.message,
  });

  final Set<String> deletedIds;
  final Set<String> remainingIds;
  final String? message;
  final bool succeeded;

  bool get complete => succeeded && remainingIds.isEmpty;
}

class PhotoLibraryService {
  const PhotoLibraryService();

  static const MethodChannel _channel = MethodChannel('tidy/photos');

  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<String> permissions() async {
    if (!supported) return 'unsupported';
    return await _channel.invokeMethod<String>('permissions') ?? 'restricted';
  }

  Future<Uint8List?> thumbnail(
    String identifier, {
    int width = 360,
    int height = 360,
  }) async {
    if (!supported) return null;
    return _channel.invokeMethod<Uint8List>('thumbnail', {
      'id': identifier,
      'width': width,
      'height': height,
    });
  }

  Future<PhotoDeletionOutcome> delete(Set<String> identifiers) async {
    if (!supported) {
      throw UnsupportedError('Photo cleanup requires iPhone Photos access.');
    }
    if (identifiers.isEmpty) {
      throw ArgumentError.value(
        identifiers,
        'identifiers',
        'Must not be empty',
      );
    }
    final response = await _channel.invokeMapMethod<Object?, Object?>(
      'delete',
      {'ids': identifiers.toList(growable: false)},
    );
    if (response == null) {
      throw PlatformException(
        code: 'empty_response',
        message: 'Photos did not confirm the selected change.',
      );
    }
    final deleted = Set<String>.from(response['deleted'] as List? ?? const []);
    final remaining = Set<String>.from(
      response['remaining'] as List? ?? const [],
    );
    return PhotoDeletionOutcome(
      succeeded: response['succeeded'] == true,
      deletedIds: deleted,
      remainingIds: remaining,
      message: response['error'] as String?,
    );
  }
}

final photoLibraryServiceProvider = Provider<PhotoLibraryService>(
  (ref) => const PhotoLibraryService(),
);

final photoPermissionProvider = FutureProvider<String>(
  (ref) => ref.watch(photoLibraryServiceProvider).permissions(),
);

final photoThumbnailProvider = FutureProvider.family<Uint8List?, String>((
  ref,
  identifier,
) {
  return ref.watch(photoLibraryServiceProvider).thumbnail(identifier);
});

final photoViewerImageProvider = FutureProvider.family<Uint8List?, String>((
  ref,
  identifier,
) {
  return ref
      .watch(photoLibraryServiceProvider)
      .thumbnail(identifier, width: 1200, height: 1800);
});
