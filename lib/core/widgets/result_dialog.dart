import 'package:flutter/material.dart';

enum ResultDialogKind { success, failure }

Future<void> showResultDialog(
  BuildContext context, {
  required ResultDialogKind kind,
  required String message,
  String? title,
  String? actionLabel,
}) {
  final isSuccess = kind == ResultDialogKind.success;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _ResultDialog(
      isSuccess: isSuccess,
      title: title ?? (isSuccess ? 'Successful!' : 'Oops!'),
      message: message,
      actionLabel: actionLabel ?? (isSuccess ? 'CONTINUE' : 'GO BACK'),
    ),
  );
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.isSuccess,
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  final bool isSuccess;
  final String title;
  final String message;
  final String actionLabel;

  static const _success = Color(0xFF22C55E);
  static const _successSoft = Color(0xFFD1FAE5);
  static const _error = Color(0xFFEF4444);
  static const _errorSoft = Color(0xFFFECACA);

  @override
  Widget build(BuildContext context) {
    final accent = isSuccess ? _success : _error;
    final soft = isSuccess ? _successSoft : _errorSoft;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Material(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 128,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _TopWavePainter(soft)),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isSuccess
                          ? Icons.check_rounded
                          : Icons.priority_high_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopWavePainter extends CustomPainter {
  const _TopWavePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..lineTo(0, size.height * 0.62)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 1.08,
        size.width,
        size.height * 0.62,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TopWavePainter oldDelegate) =>
      oldDelegate.color != color;
}
