import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  final Dio dio;

  ApiClient({required String baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            String? token;
            try {
              // Read cached token first
              token = await user.getIdToken(false).timeout(const Duration(seconds: 8));
            } catch (_) {
              try {
                // Quick retry if cached token wasn't ready immediately after OTP
                token = await user.getIdToken(true).timeout(const Duration(seconds: 5));
              } catch (e) {
                debugPrint('Failed to acquire Firebase ID token: $e');
              }
            }

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              return handler.next(options);
            } else {
              // Fail early rather than sending an invalid unauthenticated request
              debugPrint('Abort: Token missing for protected path: ${options.path}');
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Firebase session active but failed to retrieve token.',
                  type: DioExceptionType.cancel,
                ),
              );
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          debugPrint(
            'API Error [${error.response?.statusCode ?? 'NO_RESPONSE'}] '
            '=> Path: ${error.requestOptions.path}',
          );
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query, Options? options}) =>
      dio.get<T>(path, queryParameters: query, options: options);

  Future<Response<T>> post<T>(String path, {Object? data, Map<String, dynamic>? query, Options? options}) =>
      dio.post<T>(path, data: data, queryParameters: query, options: options);

  Future<Response<T>> put<T>(String path, {Object? data, Map<String, dynamic>? query, Options? options}) =>
      dio.put<T>(path, data: data, queryParameters: query, options: options);

  Future<Response<T>> delete<T>(String path, {Object? data, Map<String, dynamic>? query, Options? options}) =>
      dio.delete<T>(path, data: data, queryParameters: query, options: options);
}

class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
}