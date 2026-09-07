import 'package:B2B/app/core/networking/api_constans.dart';
import 'package:B2B/app/features/auth/data/auth_session_notifier.dart';
import 'package:B2B/app/features/auth/data/repos/auth_repository.dart';
import 'package:B2B/app/features/auth/data/session_expired_exception.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends QueuedInterceptor {
  static const _retriedKey = 'retriedAfterRefresh';

  final Dio _retryDio;

  final AuthRepository _authRepository;
  AuthInterceptor({
    required Dio retryDio,
    required AuthRepository authRepository,
  })  : _retryDio = retryDio,
        _authRepository = authRepository;

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;

    if (error.response?.statusCode != 401) {
      handler.next(error);
      return;
    }

    // لا نحاول refresh على login/register/refresh/logout نفسه
    // حتى لا ندخل في refresh loop.
    if (_shouldNotAttemptRefresh(request.path)) {
      handler.next(error);
      return;
    }

    // إذا جربنا refresh لهذا الطلب مسبقاً وفشل مرة ثانية،
    // نعتبر الجلسة منتهية.
    if (request.extra[_retriedKey] == true) {
      await _authRepository.clearSession(
        status: AuthSessionStatus.sessionExpired,
      );

      handler.next(error);
      return;
    }

    try {
      final failedToken =
          _bearerToken(request.headers['Authorization']);

      final storedToken =
          await _authRepository.tokenStorage.readToken();

      final newToken = storedToken != null &&
              storedToken.isNotEmpty &&
              failedToken != null &&
              storedToken != failedToken
          ? storedToken
          : await _authRepository.refreshToken();

      request.headers['Authorization'] = 'Bearer $newToken';
      request.extra[_retriedKey] = true;

      final response =
          await _retryDio.fetch<dynamic>(request);

      handler.resolve(response);
    } on SessionExpiredException {
      handler.next(error);
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        await _authRepository.clearSession(
          status: AuthSessionStatus.sessionExpired,
        );
      }

      handler.next(retryError);
    } catch (_) {
      handler.next(error);
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // login + register فقط لا يحتاجان token.
    // refresh + logout يحتاجان Authorization.
    if (!_shouldSkipAuthorization(options.path)) {
      final token =
          await _authRepository.tokenStorage.readToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  String? _bearerToken(dynamic authorization) {
    if (authorization is! String) return null;

    const prefix = 'Bearer ';

    return authorization.startsWith(prefix)
        ? authorization.substring(prefix.length)
        : null;
  }

  String _normalizePath(String path) {
    return path
        .split('?')
        .first
        .replaceAll(RegExp(r'/+$'), '');
  }

  /// endpoints التي لا يجب أن تؤدي إلى refresh جديد عند 401.
  bool _shouldNotAttemptRefresh(String path) {
    final normalized = _normalizePath(path);

    return const {
      ApiConstants.login,
      ApiConstants.register,
      ApiConstants.refresh,
      ApiConstants.logout,
      '/api/store/login',
      '/api/store/register',
      '/api/store/refresh',
      '/api/store/logout',
    }.contains(normalized);
  }

  /// فقط endpoints التي يجب ألا نرسل لها Authorization.
  bool _shouldSkipAuthorization(String path) {
    final normalized = _normalizePath(path);

    return const {
      ApiConstants.login,
      ApiConstants.register,
      '/api/store/login',
      '/api/store/register',
    }.contains(normalized);
  }
}
