import 'package:dio/dio.dart';

/// Everything that can go wrong, as the screens need to know it.
sealed class Failure implements Exception {
  const Failure();

  factory Failure.from(Object error) => switch (error) {
    final Failure f => f,
    DioException(type: DioExceptionType.badResponse, response: Response(statusCode: 404 || 410)) =>
      const NotFoundFailure(),
    DioException(type: DioExceptionType.badResponse) => const ServerFailure(),
    DioException(
      type: DioExceptionType.connectionError ||
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout,
    ) =>
      const OfflineFailure(),
    DioException(error: final CacheMiss _) => const OfflineFailure(),
    _ => const UnexpectedFailure(),
  };
}

class OfflineFailure extends Failure {
  const OfflineFailure();
}

class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

class ServerFailure extends Failure {
  const ServerFailure();
}

/// A shape this version does not understand, or a bug.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure();
}

/// Nothing is kept for this address.
class CacheMiss implements Exception {
  const CacheMiss();
}
