import 'package:dio/dio.dart';

/// Converts raw exceptions or DioExceptions into clean, human-readable error messages.
String formatApiError(dynamic error, {String fallback = 'An unexpected error occurred'}) {
  if (error == null) return fallback;

  if (error is DioException) {
    // 1. Try to extract structured backend error payload
    final data = error.response?.data;
    if (data is Map) {
      if (data['error'] != null && data['error'].toString().trim().isNotEmpty) {
        return _cleanBackendMessage(data['error'].toString());
      }
      if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
        return _cleanBackendMessage(data['message'].toString());
      }
    } else if (data is String && data.trim().isNotEmpty && !data.contains('<!DOCTYPE html>')) {
      return _cleanBackendMessage(data);
    }

    // 2. Status codes
    final statusCode = error.response?.statusCode;
    if (statusCode == 400) {
      return 'Invalid request details. Please check your input and try again.';
    }
    if (statusCode == 401) {
      return 'Invalid credentials or session expired. Please sign in again.';
    }
    if (statusCode == 403) {
      return 'You are not authorized to perform this action.';
    }
    if (statusCode == 404) {
      return 'Item or resource not found.';
    }
    if (statusCode == 409) {
      return 'This action has already been performed or already exists.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Campus server encountered an error. Please try again later.';
    }

    // 3. Network connection issues
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Unable to reach the campus server. Please check your network connection.';
    }
  }

  // 4. String inspection for raw strings that wrap DioException
  String str = error.toString().replaceAll('Exception: ', '').trim();
  if (str.contains('DioException [bad response]') || str.contains('status code of 400')) {
    return 'Invalid request. Please verify the entered details.';
  }
  if (str.contains('SocketException') || str.contains('connectTimeout')) {
    return 'Unable to connect to the campus server.';
  }

  return str.isNotEmpty ? str : fallback;
}

String _cleanBackendMessage(String msg) {
  if (msg.contains('Invalid coupon code')) {
    return 'Coupon code is invalid or not found. Please check and try again.';
  }
  if (msg.contains('Merchant not authorized')) {
    return 'This coupon belongs to a different merchant partner.';
  }
  if (msg.contains('Coupon is not active') || msg.contains('REDEEMED')) {
    return 'This coupon has already been redeemed.';
  }
  if (msg.contains('expired')) {
    return 'This coupon has expired.';
  }
  if (msg.contains('Malformed request body') || msg.contains('UUID')) {
    return 'Invalid format. Please check the entered fields.';
  }
  if (msg.contains('Merchant not found')) {
    return 'Merchant account not found. Please select a registered merchant.';
  }
  return msg;
}
