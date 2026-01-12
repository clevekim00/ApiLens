import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../import/application/swagger_parser_service.dart';
import '../models/request_model.dart';
import '../data/request_repository.dart';

class SavedRequestController extends StateNotifier<List<RequestModel>> {
  final RequestRepository _repository;

  SavedRequestController(this._repository) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repository.getAll();
  }

  Future<void> saveRequest(RequestModel request) async {
    await _repository.save(request);
    refresh();
  }

  Future<void> moveRequest(String requestId, String? newGroupId) async {
    final existingIndex = state.indexWhere((r) => r.id == requestId);
    if (existingIndex != -1) {
      final updated = state[existingIndex].copyWith(groupId: newGroupId ?? 'no-workgroup');
      await _repository.save(updated);
      refresh();
    }
  }

  Future<void> deleteRequest(String id) async {
    await _repository.delete(id);
    refresh();
  }
  
  Future<void> importSwagger(String content, {String? targetGroupId}) async {
    final parser = SwaggerParserService();
    final requests = parser.parse(content);
    
    for (final req in requests) {
      final newReq = req.copyWith(groupId: targetGroupId ?? 'no-workgroup');
      await _repository.save(newReq);
    }
    refresh();
  }
}

final savedRequestControllerProvider = StateNotifierProvider<SavedRequestController, List<RequestModel>>((ref) {
  final repo = ref.watch(requestRepositoryProvider);
  return SavedRequestController(repo);
});
