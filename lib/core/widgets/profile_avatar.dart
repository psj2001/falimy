import 'dart:io';

import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.photoPath,
    this.onTap,
    this.radius = 48,
  });

  /// Local file path or remote https URL.
  final String? photoPath;
  final VoidCallback? onTap;
  final double radius;

  bool get _isRemote {
    final path = photoPath;
    if (path == null || path.isEmpty) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  bool get _isLocalFile {
    final path = photoPath;
    if (path == null || path.isEmpty || _isRemote) return false;
    return File(path).existsSync();
  }

  Widget _placeholder() {
    return ColoredBox(
      color: FalimyTheme.seed.withValues(alpha: 0.15),
      child: Icon(
        Icons.person_rounded,
        size: radius,
        color: FalimyTheme.seed,
      ),
    );
  }

  Widget _image() {
    final size = radius * 2;
    if (_isRemote) {
      return Image.network(
        photoPath!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return ColoredBox(
            color: FalimyTheme.seed.withValues(alpha: 0.15),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }
    if (_isLocalFile) {
      return Image.file(
        File(photoPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: _image(),
            ),
          ),
          if (onTap != null)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: FalimyTheme.seed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
