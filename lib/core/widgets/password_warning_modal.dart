import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PasswordWarningModal extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PasswordWarningModal({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  /// Shows the modal and returns true if the user confirmed, false if cancelled.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PasswordWarningModal(
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.appColors.surface,
          border: Border.all(color: theme.appColors.border!, width: 3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.appColors.shadow!,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🚨', style: GoogleFonts.spaceGrotesk(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              'You sure?',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: theme.appColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You want to keep THAT password?\n\nThere\'s no "forgot password" here. Forget it and you\'re completely, utterly, forever f*ckd.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.appColors.onSurface?.withOpacity(0.65),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _ModalButton(
                    label: 'CANCEL',
                    onTap: onCancel,
                    filled: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModalButton(
                    label: "I'M SURE 💯",
                    onTap: onConfirm,
                    filled: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _ModalButton({required this.label, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? theme.appColors.primary : Colors.transparent,
          border: Border.all(color: theme.appColors.border!, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: filled
              ? [BoxShadow(color: theme.appColors.shadow!, offset: const Offset(3, 3))]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: theme.appColors.onSurface,
          ),
        ),
      ),
    );
  }
}
