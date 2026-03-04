import 'package:equatable/equatable.dart';

/// Sealed failure hierarchy — safe to expose to UI layers (no stack traces).
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Check your connection.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed. Please sign in again.']);
}

class TranslationFailure extends Failure {
  const TranslationFailure([super.message = 'Translation unavailable. Please try again.']);
}

class EnrichmentFailure extends Failure {
  const EnrichmentFailure([super.message = 'Could not load word details.']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Failed to save data. Please try again.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
