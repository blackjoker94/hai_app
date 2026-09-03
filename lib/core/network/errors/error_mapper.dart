import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hai_app/core/network/errors/failure.dart';

Failure mapDioException(DioException e) {
  debugPrint("🔴 mapDioException called");
  debugPrint("🔴 Exception Type: ${e.type}");
  debugPrint("🔴 Exception Message: ${e.message}");
  debugPrint("🔴 Exception Error: ${e.error}");
  debugPrint("🔴 Response Status: ${e.response?.statusCode}");
  debugPrint("🔴 Response Data: ${e.response?.data}");
  
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const TimeoutFailure("Connection timeout");

    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;

      if (statusCode == 401) {
        return const UnauthorizedFailure("Unauthorized access");
      }

      if (statusCode == 404) {
        return const ServerFailure("Resource not found");
      }

      if (statusCode != null && statusCode >= 500) {
        return const ServerFailure("Server error");
      }

      return ServerFailure(
        e.response?.data['message'] ?? "Unexpected server error",
      );

    case DioExceptionType.connectionError:
      debugPrint("🔴 Connection Error - Likely network issue or wrong URL");
      return NetworkFailure(
        "No internet connection. Error: ${e.error ?? e.message ?? 'Unknown'}"
      );

    case DioExceptionType.cancel:
      return const NetworkFailure("Request cancelled");

    case DioExceptionType.unknown:
      debugPrint("🔴 Unknown Error - This usually means:");
      debugPrint("   - Base URL is wrong (localhost won't work on Android)");
      debugPrint("   - No internet permission in AndroidManifest");
      debugPrint("   - HTTP traffic blocked (need cleartext in AndroidManifest)");
      debugPrint("   - Response is not valid JSON");
      
      // Provide more helpful error message
      final errorMsg = e.error?.toString() ?? e.message ?? "Unknown error";
      debugPrint("🔴 Actual error: $errorMsg");
      
      return NetworkFailure(
        "Network error: $errorMsg. Please check your internet connection."
      );

    default:
      return const NetworkFailure("Something went wrong");
  }
}