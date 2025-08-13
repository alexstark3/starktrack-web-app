// lib/company/widgets/login_form.dart
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../utils/browser_persistence.dart';

/// Login form with animated button and browser data persistence.
/// • Idle → full‑width 30 px rounded‑rect button.
/// • Loading → morphs into a 50 × 50 blue circle with a 45 px white spinner.
/// • Browser persistence → remembers email and supports password managers.
class LoginForm extends StatefulWidget {
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

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    try {
      final savedEmail = await BrowserPersistence.loadUserEmail();
      if (mounted && savedEmail != null && savedEmail.isNotEmpty) {
        widget.emailController.text = savedEmail;
      }
    } catch (e) {}
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colors?.backgroundDark : Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              color: isDark ? colors?.cardColorDark : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Stark Track',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colors?.primaryBlue ??
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildFields(),
                      const SizedBox(height: 8),
                      if (widget.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(widget.error!,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      _AnimatedLoginButton(
                        loading: widget.loading,
                        onTap: _submit,
                        isSubmit: true,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot my password',
                            style: TextStyle(
                              color: colors?.primaryBlue ??
                                  Theme.of(context).colorScheme.primary,
                              fontSize: 14,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column _buildFields() {
    final colors = Theme.of(context).extension<AppColors>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        TextFormField(
          controller: widget.emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.username],
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => widget.passwordFocus.requestFocus(),
          autofocus: true,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Please enter your email'
              : null,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.email,
            hintText: AppLocalizations.of(context)!.enterYourEmail,
            prefixIcon: Icon(Icons.email,
                color: colors?.primaryBlue ??
                    Theme.of(context).colorScheme.primary),
            filled: true,
            fillColor: isDark
                ? colors?.lightGray ?? Colors.grey[800]
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: colors?.primaryBlue ??
                      Theme.of(context).colorScheme.primary,
                  width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.passwordController,
          focusNode: widget.passwordFocus,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          validator: (value) => (value == null || value.isEmpty)
              ? 'Please enter your password'
              : null,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.password,
            hintText: AppLocalizations.of(context)!.enterYourPassword,
            prefixIcon: Icon(Icons.lock,
                color: colors?.primaryBlue ??
                    Theme.of(context).colorScheme.primary),
            filled: true,
            fillColor: isDark
                ? colors?.lightGray ?? Colors.grey[800]
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: colors?.primaryBlue ??
                      Theme.of(context).colorScheme.primary,
                  width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedLoginButton extends StatelessWidget {
  const _AnimatedLoginButton(
      {required this.loading, required this.onTap, this.isSubmit = false});

  final bool loading;
  final VoidCallback onTap;
  final bool isSubmit;

  static const double _idleH = 48;
  static const double _circle = 48;
  static const double _spinner = 45;

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
            customBorder: loading
                ? const CircleBorder()
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
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
                    : isSubmit
                        ? Text(AppLocalizations.of(context)!.login,
                            style: const TextStyle(color: Colors.white))
                        : Text(AppLocalizations.of(context)!.login,
                            style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      );
    });
  }
}
