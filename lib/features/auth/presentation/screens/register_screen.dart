import 'package:bondhu/features/auth/domain/auth_exception_mapper.dart';
import 'package:bondhu/features/auth/presentation/components/auth_components.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bondhu/core/utils/logger.dart';
import 'package:bondhu/services/supabase_service.dart';

// ── Password strength helpers ─────────────────────────────────────────────────

enum _PasswordStrength { weak, fair, strong, veryStrong }

_PasswordStrength _evaluate(String p) {
  if (p.length < 6) return _PasswordStrength.weak;
  int score = 0;
  if (p.length >= 8) score++;
  if (p.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(p)) score++;
  if (RegExp(r'[0-9]').hasMatch(p)) score++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) score++;
  if (score <= 1) return _PasswordStrength.fair;
  if (score <= 3) return _PasswordStrength.strong;
  return _PasswordStrength.veryStrong;
}

extension _StrengthUI on _PasswordStrength {
  Color color(ColorScheme cs) => switch (this) {
    _PasswordStrength.weak => cs.error,
    _PasswordStrength.fair => Colors.orange,
    _PasswordStrength.strong => Colors.lightGreen,
    _PasswordStrength.veryStrong => Colors.green,
  };

  String get label => switch (this) {
    _PasswordStrength.weak => 'দুর্বল',
    _PasswordStrength.fair => 'মোটামুটি',
    _PasswordStrength.strong => 'শক্তিশালী',
    _PasswordStrength.veryStrong => 'খুব শক্তিশালী',
  };

  int get barCount => index + 1; // 1-4
}

// ── Screen ────────────────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;
  bool _submitted = false;
  _PasswordStrength? _strength;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final p = _passwordController.text;
    setState(() => _strength = p.isEmpty ? null : _evaluate(p));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Validators ────────────────────────────────────────────────────────────

  String? _validateEmail(String? v) {
    if (!_submitted) return null;
    if (v == null || v.trim().isEmpty) return 'ইমেইল প্রয়োজন';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(v.trim())) return 'সঠিক ইমেইল ঠিকানা দিন';
    return null;
  }

  String? _validatePassword(String? v) {
    if (!_submitted) return null;
    if (v == null || v.isEmpty) return 'পাসওয়ার্ড প্রয়োজন';
    if (v.length < 8) return 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষর হতে হবে';
    return null;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _signUp() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreedToTerms) {
      _showError('শর্তাবলী এবং গোপনীয়তা নীতিতে সম্মতি দিন');
      return;
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.user != null) {
        // If email-confirm is disabled the session is immediately available.
        if (response.session != null) {
          context.go('/home');
        } else {
          // Email-confirm is enabled: prompt user to check their inbox.
          _showSuccess('যাচাইকরণ ইমেইল পাঠানো হয়েছে। ইনবক্স চেক করুন।');
          context.go('/login');
        }
      } else {
        _showError('সাইন আপ ব্যর্থ হয়েছে। আবার চেষ্টা করুন।');
      }
    } on AuthException catch (e) {
      AppLogger.error('Register failed', error: e);
      if (mounted) _showError(AuthExceptionMapper.map(e));
    } catch (e, s) {
      AppLogger.error('Unexpected register error', error: e, stackTrace: s);
      if (mounted) _showError('নেটওয়ার্ক সমস্যা হয়েছে। ইন্টারনেট চেক করুন।');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildPasswordStrengthBar() {
    if (_strength == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final color = _strength!.color(cs);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              final filled = i < _strength!.barCount;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled
                        ? color
                        : cs.onSurface.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            _strength!.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            side: BorderSide(
              color: (_submitted && !_agreedToTerms)
                  ? cs.error
                  : cs.outline,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'আমি '),
                TextSpan(
                  text: 'শর্তাবলী',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: cs.primary,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.push('/terms'),
                ),
                const TextSpan(text: ' এবং '),
                TextSpan(
                  text: 'গোপনীয়তা নীতি',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: cs.primary,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.push('/privacy'),
                ),
                const TextSpan(text: '-তে সম্মত আছি'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ──
                      const AuthHeader(
                        title: 'অ্যাকাউন্ট তৈরি করুন',
                        subtitle: 'বিনামূল্যে শুরু করুন',
                      ),

                      const SizedBox(height: 36),

                      // ── Form Card ──
                      AuthCard(
                        children: [
                          // Email
                          AuthTextField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            label: 'ইমেইল',
                            hint: 'example@email.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: _validateEmail,
                            onFieldSubmitted: (_) =>
                                _passwordFocus.requestFocus(),
                          ),

                          const SizedBox(height: 20),

                          // Password
                          AuthTextField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            label: 'পাসওয়ার্ড',
                            hint: 'কমপক্ষে ৮ অক্ষর',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            validator: _validatePassword,
                            onFieldSubmitted: (_) => _signUp(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              onPressed: () => setState(
                                    () =>
                                _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                          ),

                          // Password strength bar
                          _buildPasswordStrengthBar(),

                          const SizedBox(height: 20),

                          // Terms & Conditions
                          _buildTermsCheckbox(),

                          const SizedBox(height: 24),

                          // Submit
                          AuthSubmitButton(
                            label: 'অ্যাকাউন্ট তৈরি করুন',
                            isLoading: _isLoading,
                            onPressed: _signUp,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Switch to Login ──
                      AuthSwitchRow(
                        question: 'ইতিমধ্যে অ্যাকাউন্ট আছে? ',
                        actionLabel: 'সাইন ইন করুন',
                        onTap: () => context.pop(),
                      ),
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
}