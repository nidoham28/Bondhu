import 'package:bondhu/features/auth/presentation/components/auth_components.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bondhu/core/utils/logger.dart';
import 'package:bondhu/services/supabase_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;

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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showError('সব ফিল্ড পূরণ করুন');
      return;
    }
    if (!_agreedToTerms) {
      _showError('শর্তাবলী এবং গোপনীয়তা নীতিতে সম্মতি দিন');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (response.user != null && mounted) {
        _showSuccess('ইমেইল যাচাই করুন এবং লগইন করুন');
        context.go('/login');
      }
    } on AuthException catch (e) {
      AppLogger.error('Register failed', error: e);
      _showError(e.message);
    } catch (e, s) {
      AppLogger.error('Unexpected register error', error: e, stackTrace: s);
      _showError('একটি অপ্রত্যাশিত ত্রুটি হয়েছে');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
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
            side: BorderSide(color: cs.outline),
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
                    ..onTap = () {
                      // TODO: navigate to terms
                    },
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
                    ..onTap = () {
                      // TODO: navigate to privacy policy
                    },
                ),
                const TextSpan(text: '-তে সম্মত আছি'),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
                          label: 'ইমেইল',
                          hint: 'example@email.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        // Password
                        AuthTextField(
                          controller: _passwordController,
                          label: 'পাসওয়ার্ড',
                          hint: 'কমপক্ষে ৮ অক্ষর',
                          prefixIcon: Icons.lock_outline,
                          obscureText: !_isPasswordVisible,
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
                                  () => _isPasswordVisible = !_isPasswordVisible,
                            ),
                          ),
                        ),

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
    );
  }
}