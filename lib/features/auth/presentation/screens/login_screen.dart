import 'package:bondhu/features/auth/domain/auth_exception_mapper.dart';
import 'package:bondhu/features/auth/presentation/components/auth_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bondhu/core/utils/logger.dart';
import 'package:bondhu/services/supabase_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _submitted = false; // enables real-time validation after first attempt

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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Validators ─────────────────────────────────────────────────────────────

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
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Guard against double-submit while a request is in-flight.
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.session != null) {
        context.go('/home');
      } else {
        // Should not happen in normal flow, but guard anyway.
        _showError('সাইন ইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।');
      }
    } on AuthException catch (e) {
      AppLogger.error('Login failed', error: e);
      if (mounted) _showError(AuthExceptionMapper.map(e));
    } catch (e, s) {
      AppLogger.error('Unexpected login error', error: e, stackTrace: s);
      if (mounted) _showError('নেটওয়ার্ক সমস্যা হয়েছে। ইন্টারনেট চেক করুন।');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Feedback ───────────────────────────────────────────────────────────────

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

  // ── Build ──────────────────────────────────────────────────────────────────

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
                  // Validate on every change once the user has submitted once.
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ──
                      const AuthHeader(
                        title: 'স্বাগতম',
                        subtitle: 'আপনার অ্যাকাউন্টে সাইন ইন করুন',
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
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            validator: _validatePassword,
                            onFieldSubmitted: (_) => _signIn(),
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

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                padding:
                                const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'পাসওয়ার্ড ভুলে গেছেন?',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color:
                                  Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Submit
                          AuthSubmitButton(
                            label: 'সাইন ইন',
                            isLoading: _isLoading,
                            onPressed: _signIn,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Switch to Register ──
                      AuthSwitchRow(
                        question: 'অ্যাকাউন্ট নেই? ',
                        actionLabel: 'সাইন আপ করুন',
                        onTap: () => context.push('/register'),
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