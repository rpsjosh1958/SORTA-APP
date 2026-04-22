import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dot_grid_background.dart';
import '../../../core/widgets/password_warning_modal.dart';
import '../view_model/auth_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSignUp = false;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = ref.read(authViewModelProvider.notifier);
    final emailOrUsername = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (_isSignUp) {
      final confirmed = await PasswordWarningModal.show(context);
      if (!confirmed) return;
      vm.signUpWithEmail(emailOrUsername, password, _nameCtrl.text.trim());
    } else {
      vm.signInWithEmailOrUsername(emailOrUsername, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final auth = ref.watch(authViewModelProvider);

    ref.listen(authViewModelProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.error!,
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: colors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authViewModelProvider.notifier).clearError();
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DotGridBackground(
        child: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  _Logo(colors: colors),
                  const SizedBox(height: 10),
                  _ToggleBar(
                    isSignUp: _isSignUp,
                    colors: colors,
                    onToggle: (v) {
                      setState(() => _isSignUp = v);
                      ref.read(authViewModelProvider.notifier).clearError();
                    },
                  ),
                  const SizedBox(height: 28),
                  if (_isSignUp) ...[
                    _NeoField(
                      controller: _nameCtrl,
                      hint: 'Username',
                      icon: Icons.person_outline,
                      colors: colors,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _NeoField(
                    controller: _emailCtrl,
                    hint: _isSignUp ? 'Email' : 'Email or Username',
                    icon: Icons.mail_outline,
                    keyboardType: _isSignUp ? TextInputType.emailAddress : TextInputType.text,
                    colors: colors,
                  ),
                  const SizedBox(height: 16),
                  _NeoField(
                    controller: _passwordCtrl,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    colors: colors,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: colors.border,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _NeoButton(
                    label: _isSignUp ? 'SIGN UP' : 'SIGN IN',
                    onTap: auth.isLoading ? null : _submit,
                    background: colors.primary!,
                    isLoading: auth.isLoading,
                    colors: colors,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
    );
  }
}


// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo({required this.colors});
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/sort_word_logo.png',
      width: 50,
      errorBuilder: (_, __, ___) => Text(
        'SORTA',
        style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ToggleBar extends StatelessWidget {
  const _ToggleBar({
    required this.isSignUp,
    required this.colors,
    required this.onToggle,
  });
  final bool isSignUp;
  final dynamic colors;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: colors.border, width: 2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: colors.shadow, offset: const Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: isSignUp ? tabWidth : 0,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              Row(
                children: [
                  _Tab(label: 'SIGN IN', onTap: () => onToggle(false)),
                  _Tab(label: 'SIGN UP', onTap: () => onToggle(true)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _NeoField extends StatelessWidget {
  const _NeoField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.colors,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final dynamic colors;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: colors.border, width: 2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: colors.shadow, offset: const Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            color: Colors.black38,
            fontSize: 16,
          ),
          prefixIcon: Icon(icon, color: colors.border, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _NeoButton extends StatelessWidget {
  const _NeoButton({
    required this.label,
    required this.onTap,
    required this.background,
    required this.colors,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback? onTap;
  final Color background;
  final dynamic colors;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: enabled ? background : Colors.grey.shade300,
          border: Border.all(color: colors.border, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: enabled
              ? [BoxShadow(color: colors.shadow, offset: const Offset(4, 4), blurRadius: 0)]
              : [],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: enabled ? Colors.black : Colors.black38,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

