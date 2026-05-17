import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps Supabase [AuthException] codes and raw messages to Bengali user-facing
/// strings. Call [AuthExceptionMapper.map] in catch blocks instead of surfacing
/// raw Supabase messages.
class AuthExceptionMapper {
  AuthExceptionMapper._();

  /// Returns a Bengali error message for the given [AuthException].
  static String map(AuthException e) {
    // Supabase v2 exposes a stable `code` field. Fall back to message matching
    // for older SDK versions that may not populate the code.
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();

    // ── By code ──────────────────────────────────────────────────────────────
    if (_byCode.containsKey(code)) return _byCode[code]!;

    // ── By message substring ─────────────────────────────────────────────────
    for (final entry in _byMessage.entries) {
      if (msg.contains(entry.key)) return entry.value;
    }

    // Fallback: show a generic message; never expose raw server text.
    return 'একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।';
  }

  // ── Code-based map ───────────────────────────────────────────────────────

  static const _byCode = <String, String>{
    // Sign-in errors
    'invalid_credentials': 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।',
    'email_not_confirmed': 'ইমেইল যাচাই করা হয়নি। আপনার ইনবক্স চেক করুন।',
    'user_not_found': 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই।',
    'user_banned': 'এই অ্যাকাউন্টটি নিষিদ্ধ করা হয়েছে।',
    'session_expired': 'সেশনের মেয়াদ শেষ। আবার সাইন ইন করুন।',

    // Sign-up errors
    'user_already_exists': 'এই ইমেইলে ইতিমধ্যে একটি অ্যাকাউন্ট আছে।',
    'email_exists': 'এই ইমেইলে ইতিমধ্যে একটি অ্যাকাউন্ট আছে।',
    'weak_password': 'পাসওয়ার্ড খুবই দুর্বল। শক্তিশালী পাসওয়ার্ড ব্যবহার করুন।',

    // Password reset errors
    'same_password': 'নতুন পাসওয়ার্ড পুরনো পাসওয়ার্ডের মতো হতে পারবে না।',

    // Rate limiting
    'over_request_rate_limit': 'অনেক বেশি চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।',
    'over_email_send_rate_limit':
    'ইমেইল পাঠানোর সীমা অতিক্রম হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।',

    // Token / OTP errors
    'otp_expired': 'কোডের মেয়াদ শেষ হয়ে গেছে। নতুন কোড অনুরোধ করুন।',
    'otp_disabled': 'OTP সুবিধা বন্ধ আছে।',
    'token_expired': 'লিংকের মেয়াদ শেষ। নতুন লিংক অনুরোধ করুন।',
    'bad_jwt': 'অবৈধ টোকেন। আবার সাইন ইন করুন।',
  };

  // ── Message-substring fallback map ──────────────────────────────────────

  static const _byMessage = <String, String>{
    'invalid login credentials': 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।',
    'invalid_credentials': 'ইমেইল বা পাসওয়ার্ড সঠিক নয়।',
    'email not confirmed': 'ইমেইল যাচাই করা হয়নি। আপনার ইনবক্স চেক করুন।',
    'user already registered': 'এই ইমেইলে ইতিমধ্যে একটি অ্যাকাউন্ট আছে।',
    'password should be': 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষর হতে হবে।',
    'rate limit': 'অনেক বেশি চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।',
    'network': 'নেটওয়ার্ক সংযোগ সমস্যা। ইন্টারনেট চেক করুন।',
  };
}