import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/services/photo_picker_service.dart';

/// Shows camera/gallery sheet, then picks and saves a photo.
/// Returns a local file path, or null if cancelled.
/// Throws [PhotoPickException] on failure.
Future<String?> showPhotoSourceSheet(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FalimyTheme.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add photo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (source == null) return null;

  // Let the sheet finish dismissing before presenting the iOS picker.
  await Future<void>.delayed(const Duration(milliseconds: 350));

  return PhotoPickerService().pickAndSave(source: source);
}
