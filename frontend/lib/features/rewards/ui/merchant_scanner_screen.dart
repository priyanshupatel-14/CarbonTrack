import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reward_provider.dart';
import '../models/coupon_model.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merchant Validator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Enter Coupon Code',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _validateCode,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Validate Coupon'),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_validatedCoupon != null) ...[
              Card(
                color: _validatedCoupon!.status == 'ACTIVE' ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reward: ${_validatedCoupon!.reward.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Status: ${_validatedCoupon!.status}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      if (_validatedCoupon!.status == 'ACTIVE')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: _consumeCode,
                            child: const Text('Mark as Consumed', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ]
          ],
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
        _error = 'Failed to validate: $e';
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
          const SnackBar(content: Text('Coupon consumed successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to consume: $e';
        _isLoading = false;
      });
    }
  }
}
