class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([super.message = 'No internet connection']);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([super.message = 'Unauthorized access'])
    : super(statusCode: 401);
}

class NotFoundException extends AppException {
  NotFoundException([super.message = 'Resource not found'])
    : super(statusCode: 404);
}

class ServerException extends AppException {
  ServerException([super.message = 'Server error occurred'])
    : super(statusCode: 500);
}

class ValidationException extends AppException {
  ValidationException([super.message = 'Validation failed'])
    : super(statusCode: 400);
}
