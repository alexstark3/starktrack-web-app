// lib/company/widgets/login_form.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Login form with animated button.
/// • Idle → full‑width 30 px rounded‑rect button.
/// • Loading → morphs into a 50 × 50 blue circle with a 45 px white spinner.
class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.passwordFocus,
    required this.loading,
    required this.error,
    required this.onLogin,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final bool loading;
  final String? error;
  final VoidCallback onLogin;

  // Sizes
  static const double _idleH = 30;
  static const double _circle = 50;
  static const double _spinner = 45;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardW = w > 500 ? 400.0 : w - 32; // 16‑px margin each side

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /* ───── App title ───── */
          Text(
            'Stark Track',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          /* ───── Card ───── */
          Container(
            width: cardW,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).brightness == Brightness.dark 
                ? Theme.of(context).extension<AppColors>()!.cardColorDark
                : Colors.white,
              boxShadow: Theme.of(context).brightness == Brightness.light 
                ? [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 10, offset: Offset(0, 4))]
                : null,
              border: Theme.of(context).brightness == Brightness.dark 
                ? Border.all(color: const Color(0xFF404040), width: 1)
                : null,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildFields(),
                const SizedBox(height: 24),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(error!, style: const TextStyle(color: Colors.red)),
                  ),
                _AnimatedLoginButton(loading: loading, onTap: onLogin),
              ],
            ),
          ),

          const SizedBox(height: 16),
          TextButton(onPressed: () {}, child: const Text('Forgot my password')),
        ],
      ),
    );
  }

  Column _buildFields() {
    return Column(
      children: [
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => passwordFocus.requestFocus(),
          autofocus: true
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          focusNode: passwordFocus,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onLogin(),
        ),
      ],
    );
  }
}

/* ────────────────────────── Animated button ───────────────────────── */
class _AnimatedLoginButton extends StatelessWidget {
  const _AnimatedLoginButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  static const double _idleH = LoginForm._idleH;
  static const double _circle = LoginForm._circle;
  static const double _spinner = LoginForm._spinner;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: loading ? _circle : maxW,
        height: loading ? _circle : _idleH,
        alignment: Alignment.center,
        child: Material(
          color: Theme.of(context).colorScheme.primary,
          shape: loading
              ? const CircleBorder()
              : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: loading ? null : onTap,
            customBorder: loading ? const CircleBorder() : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: SizedBox(
              width: loading ? _circle : double.infinity,
              height: loading ? _circle : _idleH,
              child: Center(
                child: loading
                    ? const SizedBox(
                        height: _spinner,
                        width: _spinner,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Login', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      );
    });
  }
}
