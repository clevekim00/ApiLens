import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/models/response_model.dart';
import '../../request/providers/request_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../history/models/history_item.dart';
import '../../environments/providers/environment_provider.dart';
import 'dart:convert';

part 'response_provider.g.dart';

// Standalone ApiService Provider
@riverpod
ApiService apiService(ApiServiceRef ref) {
  return ApiService(DioClient());
}

@riverpod
class ResponseNotifier extends _$ResponseNotifier {
  @override
  AsyncValue<ResponseModel?> build() {
    return const AsyncData(null);
  }

  Future<void> sendRequest() async {
    final request = ref.read(requestNotifierProvider);
    final service = ref.read(apiServiceProvider);

    state = const AsyncLoading();

    try {
      // Fetch Active Environment Variables
      Map<String, String>? envVars;
      final activeId = ref.read(activeEnvironmentIdProvider);
      if (activeId != null) {
        final list = await ref.read(environmentListProvider.future);
        final item = list.where((e) => e.id == activeId).firstOrNull;
        if (item != null) {
          try {
             envVars = Map<String, String>.from(jsonDecode(item.variablesJson));
          } catch (_) {}
        }
      }

      final response = await service.send(request, env: envVars);
      state = AsyncData(response);

      // Auto-save to history
      final historyItem = HistoryItem()
        ..createdAt = DateTime.now()
        ..method = request.method
        ..url = request.url
        ..headersJson = jsonEncode(request.headers.map((e) => {'key': e.key, 'value': e.value, 'isEnabled': e.isEnabled}).toList())
        ..paramsJson = jsonEncode(request.params.map((e) => {'key': e.key, 'value': e.value, 'isEnabled': e.isEnabled}).toList())
        ..body = request.body
        ..authJson = jsonEncode({
           'type': request.authType.name,
           'data': request.authData ?? {},
        })
        ..statusCode = response.statusCode
        ..durationMs = response.durationMs;
      
      ref.read(historyNotifierProvider.notifier).addToHistory(historyItem);

    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void clearResponse() {
    state = const AsyncData(null);
  }
}
