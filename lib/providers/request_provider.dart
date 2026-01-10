import 'package:flutter/material.dart';
import '../models/http_request_model.dart';
import '../models/http_response_model.dart';
import '../services/http_service.dart';
import '../services/storage_service.dart';

class RequestProvider extends ChangeNotifier {
  final HttpService _httpService = HttpService();
  final StorageService _storageService = StorageService();

  // Current request state
  HttpRequestModel _currentRequest = HttpRequestModel(
    name: 'New Request',
    method: 'GET',
    url: '',
  );

  HttpResponseModel? _currentResponse;
  bool _isLoading = false;
  String? _error;

  // History
  List<HttpRequestModel> _history = [];

  // Getters
  HttpRequestModel get currentRequest => _currentRequest;
  HttpResponseModel? get currentResponse => _currentResponse;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<HttpRequestModel> get history => _history;

  // Initialize provider
  Future<void> init() async {
    await loadHistory();
  }

  // Update current request
  void updateRequest(HttpRequestModel request) {
    _currentRequest = request;
    notifyListeners();
  }

  // Update specific fields
  void updateMethod(String method) {
    _currentRequest = _currentRequest.copyWith(method: method);
    notifyListeners();
  }

  void updateUrl(String url) {
    _currentRequest = _currentRequest.copyWith(url: url);
    _autoUpdateNameFromUrl();
    notifyListeners();
  }

  void updateHeaders(Map<String, String> headers) {
    _currentRequest = _currentRequest.copyWith(headers: headers);
    notifyListeners();
  }

  void updateBody(String body) {
    _currentRequest = _currentRequest.copyWith(body: body);
    notifyListeners();
  }

  void updateQueryParams(Map<String, String> queryParams) {
    _currentRequest = _currentRequest.copyWith(queryParams: queryParams);
    notifyListeners();
  }

  void updateName(String name) {
    _currentRequest = _currentRequest.copyWith(name: name);
    notifyListeners();
  }

  // Execute request
  Future<void> executeRequest() async {
    if (_currentRequest.url.isEmpty) {
      _error = 'Please enter a URL';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _currentResponse = null;
    notifyListeners();

    try {
      final response = await _httpService.executeRequest(_currentRequest);
      _currentResponse = response;

      // Save to history
      await _storageService.saveToHistory(_currentRequest);
      await loadHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load history
  Future<void> loadHistory() async {
    _history = await _storageService.getHistory();
    notifyListeners();
  }

  // Load request from history
  void loadRequestFromHistory(HttpRequestModel request) {
    _currentRequest = request;
    _currentResponse = null;
    _error = null;
    notifyListeners();
  }

  // Load request (alias for consistency)
  void loadRequest(HttpRequestModel request) {
    loadRequestFromHistory(request);
  }

  // Delete from history
  Future<void> deleteFromHistory(String requestId) async {
    await _storageService.deleteFromHistory(requestId);
    await loadHistory();
  }

  // Clear history
  Future<void> clearHistory() async {
    await _storageService.clearHistory();
    await loadHistory();
  }

  // Create new request
  void createNewRequest() {
    _currentRequest = HttpRequestModel(
      name: 'New Request', // Will be updated when URL is set
      method: 'GET',
      url: '',
    );
    _currentResponse = null;
    _error = null;
    notifyListeners();
  }

  // Auto-update name from URL if it's still the default
  void _autoUpdateNameFromUrl() {
    if ((_currentRequest.name == 'New Request' || _currentRequest.name.isEmpty) && _currentRequest.url.isNotEmpty) {
      _currentRequest = _currentRequest.copyWith(name: _currentRequest.url);
    }
  }

  // Search history
  Future<List<HttpRequestModel>> searchHistory(String query) async {
    return await _storageService.searchHistory(query);
  }
}
