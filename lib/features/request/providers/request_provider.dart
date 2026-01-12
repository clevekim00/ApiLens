import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../workgroup/application/workgroup_controller.dart';
import '../models/request_model.dart';
import '../models/key_value_item.dart';

part 'request_provider.g.dart';

@riverpod
class RequestNotifier extends _$RequestNotifier {
  @override
  RequestModel build() {
    // Auto-assign to active workgroup on creation
    // We use read() to avoid rebuilding when selection changes while editing
    final activeGroupId = ref.read(activeWorkgroupIdProvider);
    return RequestModel.initial(groupId: activeGroupId ?? 'no-workgroup');
  }

  void updateMethod(String method) {
    state = state.copyWith(method: method);
  }

  void updateUrl(String url) {
    state = state.copyWith(url: url);
  }

  void updateGroupId(String? groupId) {
    state = state.copyWith(groupId: groupId ?? 'no-workgroup');
  }

  // --- Header CRUD ---
  void addHeader() {
    final newHeaders = List<KeyValueItem>.from(state.headers);
    newHeaders.add(KeyValueItem.initial());
    state = state.copyWith(headers: newHeaders);
  }

  void updateHeader(int index, KeyValueItem item) {
    final newHeaders = List<KeyValueItem>.from(state.headers);
    if (index >= 0 && index < newHeaders.length) {
      newHeaders[index] = item;
      state = state.copyWith(headers: newHeaders);
    }
  }

  void removeHeader(int index) {
    final newHeaders = List<KeyValueItem>.from(state.headers);
    if (index >= 0 && index < newHeaders.length) {
      newHeaders.removeAt(index);
      state = state.copyWith(headers: newHeaders);
    }
  }

  // --- Param CRUD ---
  void addParam() {
    final newParams = List<KeyValueItem>.from(state.params);
    newParams.add(KeyValueItem.initial());
    state = state.copyWith(params: newParams);
  }

  void updateParam(int index, KeyValueItem item) {
    final newParams = List<KeyValueItem>.from(state.params);
    if (index >= 0 && index < newParams.length) {
      newParams[index] = item;
      state = state.copyWith(params: newParams);
    }
  }

  void removeParam(int index) {
    final newParams = List<KeyValueItem>.from(state.params);
    if (index >= 0 && index < newParams.length) {
      newParams.removeAt(index);
      state = state.copyWith(params: newParams);
    }
  }

  // --- Body ---
  void updateBody(String body) {
    state = state.copyWith(body: body);
  }

  void updateBodyType(RequestBodyType type) {
    state = state.copyWith(bodyType: type);
  }

  // --- Auth ---
  void updateAuthType(AuthType type) {
    state = state.copyWith(authType: type);
  }

  void updateAuthData(Map<String, String> data) {
    state = state.copyWith(authData: data);
  }

  void restoreRequest(RequestModel model) {
    // Use the model's group ID, not new session's
    // But generate new ID for the session? 
    // Usually restore is "Edit this request". 
    // If it's "Edit", we keep ID? 
    // If this provider is used for "New Request" and "Edit Request", we need to be careful.
    // Assuming this provider is the "Editor Buffer".
    state = model;
  }
  
  void resetForNewRequest() {
    final activeGroupId = ref.read(activeWorkgroupIdProvider);
    state = RequestModel.initial(groupId: activeGroupId ?? 'no-workgroup');
  }
}
