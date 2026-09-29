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
      id: json['id'],
      code: json['code'],
      status: json['status'],
      expiresAt: json['expiresAt'],
      redeemedAt: json['redeemedAt'],
      reward: Reward.fromJson(json['reward']),
    );
  }
}
