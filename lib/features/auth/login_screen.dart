import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/firestore_service.dart';
import '../../shared/services/analytics_service.dart';
import '../../shared/services/storage_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await AuthService.signInWithGoogle();
      if (cred == null) { setState(() => _loading = false); return; }
      await AnalyticsService.logLogin('google');
      await _syncAndNavigate(cred.user?.displayName ?? '');
    } catch (e) {
      setState(() { _error = _friendlyError(e); _loading = false; });
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isSignUp) {
        await AuthService.signUpWithEmail(email, pass);
        await AnalyticsService.logSignUp('email');
      } else {
        await AuthService.signInWithEmail(email, pass);
        await AnalyticsService.logLogin('email');
      }
      await _syncAndNavigate('');
    } catch (e) {
      setState(() { _error = _friendlyError(e); _loading = false; });
    }
  }

  Future<void> _syncAndNavigate(String displayName) async {
    // Sync Firestore user data → local state
    final firestoreUser = await FirestoreService.loadUser();
    if (firestoreUser != null) {
      await ref.read(userProvider.notifier).setUser(firestoreUser);
    }
    if (mounted) context.go('/home');
  }

  Future<void> _skipLogin() async {
    await StorageService.setSkipLogin(true);
    if (mounted) context.go('/home');
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('user-not-found')) return 'No account found with this email';
    if (msg.contains('wrong-password')) return 'Incorrect password';
    if (msg.contains('email-already-in-use')) return 'Email already registered — sign in instead';
    if (msg.contains('weak-password')) return 'Password must be at least 6 characters';
    if (msg.contains('invalid-email')) return 'Invalid email address';
    if (msg.contains('network')) return 'No internet connection';
    return 'Something went wrong, please try again';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // Logo + name
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C3BCF), Color(0xFF9B6DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4C3BCF).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.timer_rounded,
                    color: Colors.white, size: 40),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 20),

              const Text(
                'FocusFlow',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 6),
              Text(
                _isSignUp ? 'Create your account' : 'Welcome back',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 40),

              // Google Sign-In
              _GoogleButton(
                onTap: _loading ? null : _signInWithGoogle,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ).animate().fadeIn(delay: 220.ms),

              const SizedBox(height: 20),

              // Email field
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
              ).animate().fadeIn(delay: 240.ms),

              const SizedBox(height: 12),

              // Password field
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitEmail(),
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon:
                      const Icon(Icons.lock_outline_rounded, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
              ).animate().fadeIn(delay: 260.ms),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.danger)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Primary CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submitEmail,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isSignUp ? 'Create account' : 'Sign in'),
                ),
              ).animate().fadeIn(delay: 280.ms),

              const SizedBox(height: 16),

              // Toggle sign-in / sign-up
              TextButton(
                onPressed: () =>
                    setState(() { _isSignUp = !_isSignUp; _error = null; }),
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign in'
                      : "Don't have an account? Sign up",
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.primary),
                ),
              ).animate().fadeIn(delay: 300.ms),

              // Forgot password
              if (!_isSignUp)
                TextButton(
                  onPressed: () => _showResetDialog(),
                  child: const Text('Forgot password?',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textMuted)),
                ).animate().fadeIn(delay: 320.ms),

              const SizedBox(height: 32),

              // Skip / continue without account
              GestureDetector(
                onTap: _loading ? null : _skipLogin,
                child: const Text(
                  'Continue without account →',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset password',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Your email address'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AuthService.resetPassword(ctrl.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Reset link sent — check your email')),
                  );
                }
              } catch (_) {}
            },
            child: const Text('Send'),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }
}

// ── Google Sign-In button ─────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // G icon using coloured text
            const Text(
              'G',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4285F4),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
