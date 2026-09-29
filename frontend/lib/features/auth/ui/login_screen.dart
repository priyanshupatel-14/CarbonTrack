import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _autofillDemo(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      final state = ref.read(authStateProvider);
      if (state.hasError && mounted) {
        setState(() {
          _errorMessage = _cleanError(state.error.toString());
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _cleanError(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  String _cleanError(String raw) {
    if (raw.contains('Invalid credentials') || raw.contains('401') || raw.contains('Invalid email or password')) {
      return 'Invalid email or password. Please check your credentials.';
    }
    if (raw.contains('SocketException') || raw.contains('connectTimeout') || raw.contains('Connection refused')) {
      return 'Unable to connect to campus backend (port 8080). Please ensure server is running.';
    }
    return raw.replaceAll('Exception: ', '');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Header
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.mintSurface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.mintBorder, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          size: 42,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'CarbonTrack',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Campus Sustainability & Green Points',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        letterSpacing: 0.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.statusErrorBg,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.statusError),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 13, color: AppColors.statusError),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Form Fields
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Campus Email',
                        prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                        hintText: 'student@campus.edu',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Email is required';
                        if (!val.contains('@')) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Password is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Submit Button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Registration Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'Register as Student',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),

                    // Demo Accounts Quick Selection
                    const Text(
                      'Demo Quick Login:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.school_rounded, size: 16, color: AppColors.primary),
                          label: const Text('Student Demo', style: TextStyle(fontSize: 12)),
                          onPressed: () => _autofillDemo('student_p7_1@test.edu', 'password'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.store_rounded, size: 16, color: AppColors.primary),
                          label: const Text('Merchant Demo', style: TextStyle(fontSize: 12)),
                          onPressed: () => _autofillDemo('merchant@carbontrack.edu', 'merchant_secure_password'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: AppColors.primary),
                          label: const Text('Admin Demo', style: TextStyle(fontSize: 12)),
                          onPressed: () => _autofillDemo('admin@carbontrack.edu', 'admin_secure_password'),
                        ),
                      ],
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
