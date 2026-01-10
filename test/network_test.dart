import 'package:flutter/widgets.dart';
import 'package:apilens/core/network/dio_client.dart';
import 'package:apilens/core/network/api_service.dart';
import 'package:apilens/features/request/models/request_model.dart';
import 'package:apilens/core/network/models/response_model.dart';

// Simple main function to test without UI
void main() async {
  print('--- Starting Network Test ---');
  
  final dioClient = DioClient();
  final apiService = ApiService(dioClient);

  final request = RequestModel.initial().copyWith(
    method: 'GET',
    url: 'https://jsonplaceholder.typicode.com/todos/1',
  );

  print('Sending Request: ${request.method} ${request.url}');
  
  final ResponseModel response = await apiService.send(request);

  if (response.isSuccess) {
    print('✅ SUCCESS!');
    print('Status: ${response.statusCode}');
    print('Duration: ${response.durationMs}ms');
    print('Body: ${response.body}');
  } else {
    print('❌ FAILED');
    print('Error: ${response.error}');
    print('Status: ${response.statusCode}');
  }
  
  print('--- Test Complete ---');
}
