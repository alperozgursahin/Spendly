import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService(Supabase.instance.client);
});

class MediaUploadService {
  MediaUploadService(this._client);

  final SupabaseClient _client;

  Future<String> uploadProfileAvatar({
    required String userId,
    required XFile image,
  }) {
    return _uploadPublicImage(
      bucket: 'avatars',
      image: image,
      storagePath: '$userId/avatar',
    );
  }

  Future<String> uploadGroupAvatar({
    required String groupId,
    required XFile image,
  }) {
    return _uploadPublicImage(
      bucket: 'group_avatars',
      image: image,
      storagePath: '$groupId/avatar',
    );
  }

  Future<String> _uploadPublicImage({
    required String bucket,
    required XFile image,
    required String storagePath,
  }) async {
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) throw Exception('The selected image is empty.');

    const maxBytes = 8 * 1024 * 1024;
    if (bytes.length > maxBytes) {
      throw Exception('Please choose an image smaller than 8 MB.');
    }

    final extension = _safeExtension(image.name);
    final path =
        '${storagePath}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            contentType: image.mimeType ?? _contentType(extension),
            upsert: true,
          ),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  String _safeExtension(String fileName) {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    return const {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(extension)
        ? extension
        : 'jpg';
  }

  String _contentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }
}
