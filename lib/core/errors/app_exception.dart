/// Base exception for all WordDeck errors.
/// Thrown internally; caught at module boundaries and converted to [Failure].
class AppException implements Exception {
  final String message;
  final int? code;      // HTTP status code or domain-specific code
  final Object? cause;  // underlying error for debugging

  const AppException(this.message, {this.code, this.cause});

  @override
  String toString() {
    final codePart = code != null ? ' [$code]' : '';
    final causePart = cause != null ? ' (caused by: $cause)' : '';
    return 'AppException$codePart: $message$causePart';
  }
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.cause});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.cause});
}

class TranslationException extends AppException {
  const TranslationException(super.message, {super.code, super.cause});
}

class EnrichmentException extends AppException {
  const EnrichmentException(super.message, {super.code, super.cause});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.cause});
}
