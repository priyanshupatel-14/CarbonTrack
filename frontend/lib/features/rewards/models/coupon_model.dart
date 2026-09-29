import 'reward_model.dart';

class Coupon {
  final String id;
  final String code;
  final String status;
  final String? expiresAt;
  final String? redeemedAt;
  final Reward reward;

  Coupon({
    required this.id,
    required this.code,
    required this.status,
    this.expiresAt,
    this.redeemedAt,
    required this.reward,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      expiresAt: json['expiresAt']?.toString(),
      redeemedAt: json['redeemedAt']?.toString(),
      reward: json['reward'] is Map<String, dynamic>
          ? Reward.fromJson(json['reward'] as Map<String, dynamic>)
          : Reward(
              id: '',
              name: 'Campus Reward',
              description: '',
              pointsRequired: 0,
              inventory: 0,
              merchantName: 'Campus Merchant',
            ),
    );
  }
}
