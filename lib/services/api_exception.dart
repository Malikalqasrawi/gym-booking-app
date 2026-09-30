/// Every error from the backend comes in the same shape (Java's ErrorResponse):
/// { "status": 409, "code": "EMAIL_TAKEN", "message": "...", "fieldErrors": {...} }
///
/// We turn it into this Dart exception so screens can simply do:
///   try { ... } on ApiException catch (e) { showError(e.message); }
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

  /// The phone couldn't reach the server at all (backend not running, wrong IP...).
  factory ApiException.network([String? message]) {
    return ApiException(
      statusCode: 0,
      code: 'NETWORK',
      message: message ??
          "Can't reach the server. Make sure the backend is running in NetBeans.",
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
