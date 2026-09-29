import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/carbon/ui/carbon_screen.dart';
import 'features/rewards/ui/merchant_scanner_screen.dart';

void main() {
  runApp(const ProviderScope(child: CarbonTrackApp()));
}

class CarbonTrackApp extends ConsumerWidget {
  const CarbonTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'CarbonTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }
          if (user.role == 'MERCHANT') {
            return const MerchantScannerScreen();
          }
          return const CarbonScreen();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => const LoginScreen(),
      ),
    );
  }
}


