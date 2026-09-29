import 'package:dio/dio.dart';
import '../models/reward_model.dart';
import '../models/coupon_model.dart';

class RewardRepository {
  final Dio _dio;

  RewardRepository(this._dio);

  Future<List<Reward>> getActiveRewards() async {
    final response = await _dio.get('/rewards');
    final data = response.data as List;
    return data.map((e) => Reward.fromJson(e)).toList();
  }

  Future<Coupon> redeemReward(String rewardId) async {
    final response = await _dio.post('/rewards/$rewardId/redeem');
    return Coupon.fromJson(response.data);
  }

  Future<List<Coupon>> getMyCoupons() async {
    final response = await _dio.get('/coupons/me');
    final data = response.data as List;
    return data.map((e) => Coupon.fromJson(e)).toList();
  }
  
  // Merchant specific
  Future<Coupon> validateCoupon(String code) async {
    final response = await _dio.post('/merchant/coupons/validate', data: {'code': code});
    return Coupon.fromJson(response.data);
  }

  Future<Coupon> consumeCoupon(String code) async {
    final response = await _dio.post('/merchant/coupons/consume', data: {'code': code});
    return Coupon.fromJson(response.data);
  }
}
