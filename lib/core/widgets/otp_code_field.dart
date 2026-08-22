import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.enabled = true,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool enabled;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final _focusNode = FocusNode();
  late int _lastLength;

  @override
  void initState() {
    super.initState();
    _lastLength = widget.controller.text.length;
    widget.controller.addListener(_onCodeChanged);
    _focusNode.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCodeChanged);
    _focusNode.removeListener(_rebuild);
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onCodeChanged() {
    final code = widget.controller.text;
    final previous = _lastLength;
    _lastLength = code.length;
    if (!mounted) return;
    setState(() {});
    if (previous != widget.length && code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) {
        final value = widget.controller.text.trim();
        if (!RegExp('^\\d{${widget.length}}\$').hasMatch(value)) {
          return 'Enter the ${widget.length}-digit code';
        }
        return null;
      },
      builder: (field) {
        final code = widget.controller.text;
        final hasError = field.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    children: List.generate(widget.length, (index) {
                      final digit = index < code.length ? code[index] : '';
                      final isCurrent =
                          _focusNode.hasFocus &&
                          index ==
                              (code.length == widget.length
                                  ? widget.length - 1
                                  : code.length);
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == widget.length - 1 ? 0 : 8,
                          ),
                          child: _OtpBox(
                            digit: digit,
                            focused: isCurrent,
                            hasError: hasError,
                          ),
                        ),
                      );
                    }),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        showCursor: false,
                        enableInteractiveSelection: false,
                        style: const TextStyle(color: Colors.transparent),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(widget.length),
                        ],
                        onChanged: field.didChange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 10),
              Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.digit,
    required this.focused,
    required this.hasError,
  });

  final String digit;
  final bool focused;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? Theme.of(context).colorScheme.error
        : focused
        ? FalimyTheme.seed
        : digit.isNotEmpty
        ? FalimyTheme.seed.withValues(alpha: 0.45)
        : FalimyTheme.muted.withValues(alpha: 0.35);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: focused || hasError ? 1.8 : 1.2,
        ),
      ),
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: FalimyTheme.ink,
          height: 1,
        ),
      ),
    );
  }
}
