import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../contracts/i_translation_service.dart';
import '../../models/word_input.dart';
import '../../models/translation_result.dart';
import '../../modules/auth/auth_provider.dart';
import 'deepl_translation_service.dart';

final translationServiceProvider = Provider<ITranslationService>((ref) {
  return DeepLTranslationService(
    supabase: ref.read(supabaseClientProvider),
  );
});

// ── Translation state ─────────────────────────────────────────────────────────

class TranslationNotifier
    extends StateNotifier<AsyncValue<TranslationResult?>> {
  final ITranslationService _service;

  TranslationNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> translate(WordInput input) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.translate(input));
  }

  void clear() => state = const AsyncValue.data(null);
}

final translationProvider = StateNotifierProvider.autoDispose<
    TranslationNotifier, AsyncValue<TranslationResult?>>(
  (ref) => TranslationNotifier(ref.read(translationServiceProvider)),
);
