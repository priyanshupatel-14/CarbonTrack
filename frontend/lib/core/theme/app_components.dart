import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Reusable status badge with semantic color, icon, and label
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: fontSize + 2, color: config.textColor),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toUpperCase()) {
      case 'VERIFIED':
      case 'COMPLETED':
        return _StatusConfig(
          label: status.toUpperCase() == 'VERIFIED' ? 'Verified' : 'Completed',
          textColor: AppColors.statusSuccess,
          backgroundColor: AppColors.statusSuccessBg,
          borderColor: const Color(0xFF86EFAC),
          icon: Icons.check_circle_rounded,
        );
      case 'REVIEW_REQUIRED':
        return const _StatusConfig(
          label: 'Needs Review',
          textColor: AppColors.statusWarning,
          backgroundColor: AppColors.statusWarningBg,
          borderColor: Color(0xFFFDE68A),
          icon: Icons.rate_review_rounded,
        );
      case 'PENDING':
      case 'JOINED':
        return _StatusConfig(
          label: status.toUpperCase() == 'JOINED' ? 'Joined' : 'Pending',
          textColor: const Color(0xFFB45309),
          backgroundColor: const Color(0xFFFEF3C7),
          borderColor: const Color(0xFFFCD34D),
          icon: Icons.hourglass_top_rounded,
        );
      case 'REJECTED':
      case 'EXPIRED':
        return _StatusConfig(
          label: status.toUpperCase() == 'REJECTED' ? 'Rejected' : 'Expired',
          textColor: AppColors.statusError,
          backgroundColor: AppColors.statusErrorBg,
          borderColor: const Color(0xFFFCA5A5),
          icon: Icons.cancel_rounded,
        );
      case 'ACTIVE':
        return const _StatusConfig(
          label: 'Active',
          textColor: AppColors.emerald,
          backgroundColor: AppColors.mintSurface,
          borderColor: AppColors.mintBorder,
          icon: Icons.bolt_rounded,
        );
      case 'REDEEMED':
        return const _StatusConfig(
          label: 'Redeemed',
          textColor: AppColors.textSecondary,
          backgroundColor: AppColors.surfaceSecondary,
          borderColor: AppColors.border,
          icon: Icons.done_all_rounded,
        );
      default:
        return _StatusConfig(
          label: status,
          textColor: AppColors.textMuted,
          backgroundColor: AppColors.surfaceSecondary,
          borderColor: AppColors.border,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  const _StatusConfig({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });
}

/// Standardized card component with calm border and optional click action
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: borderColor ?? AppColors.border, width: 1);
    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: cardContent,
      );
    }
    return cardContent;
  }
}

/// Purposeful Empty State with supportive guidance
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: const BoxDecoration(
                color: AppColors.surfaceSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// User-friendly error display that hides technical exceptions
class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.statusErrorBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.statusError),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _cleanErrorMessage(message),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _cleanErrorMessage(String raw) {
    if (raw.contains('DioException [bad response]') || raw.contains('status code of 400')) {
      return 'The request could not be processed. Please verify the input details.';
    }
    if (raw.contains('401') || raw.contains('Invalid credentials')) {
      return 'Incorrect email or password. Please check your credentials.';
    }
    if (raw.contains('Connection') || raw.contains('SocketException') || raw.contains('connectTimeout')) {
      return 'Unable to reach the campus server. Please check your connection.';
    }
    if (raw.contains('403') || raw.contains('Forbidden')) {
      return 'You are not authorized to perform this operation.';
    }
    if (raw.contains('404') || raw.contains('not found')) {
      return 'The requested resource was not found.';
    }
    if (raw.startsWith('Exception: ')) {
      return raw.substring(11);
    }
    return raw;
  }
}

/// Loading placeholder state
class AppLoadingView extends StatelessWidget {
  final String? message;

  const AppLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
