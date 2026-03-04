// TODO: Sealed failure classes for all error types
// (network, auth, database, translation, enrichment)
import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database error occurred']);
}

class TranslationFailure extends Failure {
  const TranslationFailure([super.message = 'Translation failed']);
}

class EnrichmentFailure extends Failure {
  const EnrichmentFailure([super.message = 'Enrichment failed']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}
