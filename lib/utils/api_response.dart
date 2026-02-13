class ApiResponse<T> {
  final T? data;
  final String message;
  final bool success;
  final int? statusCode;

  ApiResponse({
    this.data,
    required this.message,
    this.success = true,
    this.statusCode,
  });

  factory ApiResponse.success({required T data, required String message}) {
    return ApiResponse(
      data: data,
      message: message,
      success: true,
      statusCode: 200,
    );
  }

  factory ApiResponse.error({required String message, int? statusCode}) {
    return ApiResponse(
      message: message,
      success: false,
      statusCode: statusCode,
    );
  }
}
