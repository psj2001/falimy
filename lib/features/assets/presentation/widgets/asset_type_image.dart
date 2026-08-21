import 'package:flutter/material.dart';

class AssetTypeImage extends StatelessWidget {
  const AssetTypeImage({
    super.key,
    required this.path,
    this.fallbackEmoji,
    this.size = 42,
  });

  final String? path;
  final String? fallbackEmoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (path != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          path!,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              fallbackEmoji ?? '🚗',
              style: TextStyle(fontSize: size * 0.7),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          fallbackEmoji ?? '🚗',
          style: TextStyle(fontSize: size * 0.7),
        ),
      ),
    );
  }
}

class AssetTypeIconBox extends StatelessWidget {
  const AssetTypeIconBox({
    super.key,
    required this.path,
    this.fallbackEmoji,
    this.size = 48,
  });

  final String? path;
  final String? fallbackEmoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ColoredBox(
        color: const Color(0xFF111827),
        child: SizedBox(
          width: size,
          height: size,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: AssetTypeImage(
              path: path,
              fallbackEmoji: fallbackEmoji,
              size: size - 12,
            ),
          ),
        ),
      ),
    );
  }
}
