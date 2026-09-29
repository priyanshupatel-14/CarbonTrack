import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_components.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/coupon_model.dart';
import '../providers/reward_provider.dart';

class MerchantScannerScreen extends ConsumerStatefulWidget {
  const MerchantScannerScreen({super.key});

  @override
  ConsumerState<MerchantScannerScreen> createState() => _MerchantScannerScreenState();
}

class _MerchantScannerScreenState extends ConsumerState<MerchantScannerScreen> {
  final _codeController = TextEditingController();
  Coupon? _validatedCoupon;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Merchant Terminal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
            ),
            Text(
              user != null ? '${user.firstName} (${user.email})' : 'Coupon Validator',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        leading: IconButton(
          tooltip: 'Back to Sign In',
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: _logout,
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.statusError),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _logout,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.mintSurface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.mintBorder),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Campus Merchant Terminal',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Verify student Green Points discount coupons and redeem them at checkout.',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Validation Input Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Coupon Code',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _codeController,
                        style: const TextStyle(
                          fontSize: 18,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. CAMPUS-COFFEE-XXXX',
                          hintStyle: const TextStyle(letterSpacing: 0, fontSize: 14, fontWeight: FontWeight.normal),
                          prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 22),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => _codeController.clear(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _validateCode,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('Verify Coupon Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Error view if any
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.statusErrorBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.statusError, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppColors.statusError, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Validated Coupon Result
                if (_validatedCoupon != null) ...[
                  AppCard(
                    borderColor: _validatedCoupon!.status == 'ACTIVE' ? AppColors.mintBorder : AppColors.border,
                    backgroundColor: _validatedCoupon!.status == 'ACTIVE' ? AppColors.mintSurface : AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _validatedCoupon!.reward.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                            ),
                            StatusBadge(status: _validatedCoupon!.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _validatedCoupon!.reward.description,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const Divider(height: AppSpacing.xxl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Code:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                            SelectableText(
                              _validatedCoupon!.code,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Partner Merchant:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                            Text(
                              _validatedCoupon!.reward.merchantName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (_validatedCoupon!.expiresAt != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Expires At:', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                              Text(
                                _validatedCoupon!.expiresAt!.split('T')[0],
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),

                        if (_validatedCoupon!.status == 'ACTIVE')
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              icon: const Icon(Icons.check_circle_rounded, size: 20),
                              label: const Text('Mark as Consumed & Redeem', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: _isLoading ? null : _consumeCode,
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Center(
                              child: Text(
                                _validatedCoupon!.status == 'REDEEMED'
                                    ? 'This coupon has already been redeemed.'
                                    : 'This coupon is not active and cannot be redeemed.',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _validateCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _validatedCoupon = null;
    });

    try {
      final coupon = await ref.read(rewardRepositoryProvider).validateCoupon(code);
      setState(() {
        _validatedCoupon = coupon;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = _cleanError(e, code);
        _isLoading = false;
      });
    }
  }

  Future<void> _consumeCode() async {
    if (_validatedCoupon == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final code = _validatedCoupon!.code;
      final updatedCoupon = await ref.read(rewardRepositoryProvider).consumeCoupon(code);
      setState(() {
        _validatedCoupon = updatedCoupon;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon consumed successfully!'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = _cleanError(e, _validatedCoupon?.code ?? '');
        _isLoading = false;
      });
    }
  }

  String _cleanError(dynamic err, String code) {
    return formatApiError(
      err,
      fallback: code.isNotEmpty
          ? 'Coupon code "$code" is invalid or was not found. Please verify the code.'
          : 'Invalid coupon code or request could not be processed.',
    );
  }
}
