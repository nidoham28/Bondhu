import 'package:flutter/material.dart';

/// Shared input field used across Login & Register screens.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: tt.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: tt.bodyMedium?.copyWith(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.35)),
            prefixIcon: Icon(
              prefixIcon,
              size: 20,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: cs.surface,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared submit button used across Login & Register screens.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      child: isLoading
          ? SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: cs.onPrimary,
        ),
      )
          : Text(label),
    );
  }
}

/// Shared card wrapper for the form fields.
class AuthCard extends StatelessWidget {
  final List<Widget> children;

  const AuthCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Shared header: logo + title + subtitle.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          title,
          style: tt.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Shared bottom navigation row (e.g. "Already have an account? Sign in").
class AuthSwitchRow extends StatelessWidget {
  final String question;
  final String actionLabel;
  final VoidCallback onTap;

  const AuthSwitchRow({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: tt.bodyMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}