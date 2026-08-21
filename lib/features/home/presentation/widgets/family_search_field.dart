import 'package:flutter/material.dart';

import 'package:falimy/app/theme.dart';

class FamilySearchField extends StatelessWidget {
  const FamilySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: FalimyTheme.ink.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              color: FalimyTheme.ink,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search a family',
              hintStyle: const TextStyle(
                color: FalimyTheme.muted,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: FalimyTheme.ink,
              ),
              suffixIcon: hasText
                  ? IconButton(
                      tooltip: 'Clear',
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: FalimyTheme.muted,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE8E9EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE8E9EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: FalimyTheme.seed,
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
