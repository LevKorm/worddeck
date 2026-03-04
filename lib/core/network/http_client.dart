import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

/// Creates a configured Dio instance.
/// Used by TranslationService and EnrichmentService.
Dio buildHttpClient() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {'Accept': 'application/json'},
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugPrint(o.toString()),
    ));
  }

  dio.interceptors.add(_ErrorInterceptor());
  return dio;
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = _extractMessage(err);
    final code = err.response?.statusCode;

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: NetworkException(message, code: code, cause: err),
        type: err.type,
      ),
    );
  }

  String _extractMessage(DioException err) {
    if (err.response?.data is Map) {
      final data = err.response!.data as Map;
      return data['message']?.toString() ??
          data['error']?.toString() ??
          'Request failed (${err.response?.statusCode})';
    }
    return switch (err.type) {
      DioExceptionType.connectionTimeout => 'Connection timed out',
      DioExceptionType.receiveTimeout    => 'Server took too long to respond',
      DioExceptionType.connectionError   => 'No internet connection',
      _ => err.message ?? 'Network error',
    };
  }
}
