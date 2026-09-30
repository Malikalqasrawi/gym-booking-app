/// An error response from the backend (its ErrorResponse body), or a network failure.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final Map<String, String> fieldErrors;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.fieldErrors = const {},
  });

  factory ApiException.network([String? message]) {
    return ApiException(
      statusCode: 0,
      code: 'NETWORK',
      message: message ??
          "Can't reach the server. Check your connection and try again.",
    );
  }

  factory ApiException.fromJson(int statusCode, Map<String, dynamic> json) {
    final rawFieldErrors = json['fieldErrors'];
    return ApiException(
      statusCode: statusCode,
      code: (json['code'] as String?) ?? 'UNKNOWN',
      message: (json['message'] as String?) ?? 'Something went wrong',
      fieldErrors: rawFieldErrors is Map
          ? rawFieldErrors.map((key, value) => MapEntry('$key', '$value'))
          : const {},
    );
  }

  bool get isNetworkError => code == 'NETWORK';

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
