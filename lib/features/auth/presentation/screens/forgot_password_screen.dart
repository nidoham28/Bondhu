import 'package:bondhu/features/auth/domain/auth_exception_mapper.dart';
import 'package:bondhu/features/auth/presentation/components/auth_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bondhu/core/utils/logger.dart';
import 'package:bondhu/services/supabase_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _submitted = false;
  bool _emailSent = false;

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
    _animController.dispose();
    super.dispose();
  }

  // ── Validator ─────────────────────────────────────────────────────────────

  String? _validateEmail(String? v) {
    if (!_submitted) return null;
    if (v == null || v.trim().isEmpty) return 'ইমেইল প্রয়োজন';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(v.trim())) return 'সঠিক ইমেইল ঠিকানা দিন';
    return null;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _sendResetEmail() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.auth.sendPasswordResetEmail(_emailController.text);
      if (!mounted) return;
      setState(() => _emailSent = true);
    } on AuthException catch (e) {
      AppLogger.error('Password reset failed', error: e);
      if (mounted) _showError(AuthExceptionMapper.map(e));
    } catch (e, s) {
      AppLogger.error('Unexpected reset error', error: e, stackTrace: s);
      if (mounted) _showError('নেটওয়ার্ক সমস্যা হয়েছে। ইন্টারনেট চেক করুন।');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  // ── Success state ─────────────────────────────────────────────────────────

  Widget _buildSuccessState() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_outlined, size: 72, color: cs.primary),
        const SizedBox(height: 24),
        Text(
          'ইমেইল পাঠানো হয়েছে',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${_emailController.text.trim()}-এ পাসওয়ার্ড রিসেট লিংক পাঠানো হয়েছে। '
              'ইনবক্স এবং স্প্যাম ফোল্ডার চেক করুন।',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.65),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.go('/login'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('লগইন পেজে ফিরুন'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _emailSent = false;
            _submitted = false;
          }),
          child: Text(
            'আবার পাঠান',
            style: TextStyle(color: cs.primary),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _emailSent
                      ? _buildSuccessState()
                      : _buildFormState(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'পাসওয়ার্ড ভুলে গেছেন?',
            subtitle: 'আপনার ইমেইলে রিসেট লিংক পাঠানো হবে',
          ),

          const SizedBox(height: 36),

          AuthCard(
            children: [
              AuthTextField(
                controller: _emailController,
                label: 'ইমেইল',
                hint: 'example@email.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: _validateEmail,
                onFieldSubmitted: (_) => _sendResetEmail(),
              ),

              const SizedBox(height: 24),

              AuthSubmitButton(
                label: 'রিসেট লিংক পাঠান',
                isLoading: _isLoading,
                onPressed: _sendResetEmail,
              ),
            ],
          ),

          const SizedBox(height: 24),

          AuthSwitchRow(
            question: 'পাসওয়ার্ড মনে আছে? ',
            actionLabel: 'সাইন ইন করুন',
            onTap: () => context.pop(),
          ),
        ],
      ),
    );
  }
}