import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:falimy/core/config/cloudinary_config.dart';

class CloudinaryException implements Exception {
  CloudinaryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Uploads a local image and returns the secure HTTPS URL.
  Future<String> uploadProfilePhoto({
    required String userId,
    required String localPath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw CloudinaryException('Photo file not found');
    }

    // Unsigned presets disallow `overwrite`. Keep only allowed fields.
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(CloudinaryConfig.uploadUrl),
    )
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = 'falimy/users/$userId'
      ..fields['public_id'] = 'avatar'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          localPath,
          filename: 'avatar.jpg',
        ),
      );

    final streamed = await _client.send(request);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw CloudinaryException(
        'Cloudinary upload failed (${streamed.statusCode}): $body',
      );
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw CloudinaryException('Cloudinary response missing secure_url');
    }
    return url;
  }
}
