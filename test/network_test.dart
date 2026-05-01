import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:apilens/core/network/api_service.dart';
import 'package:apilens/core/network/dio_client.dart';
import 'package:apilens/features/request/models/request_model.dart';

void main() {
  group('ApiService.send', () {
    late HttpServer server;
    late ApiService apiService;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      apiService = ApiService(DioClient());
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('decodes a plain JSON response and parses jsonBody', () async {
      server.listen((request) async {
        final payload = jsonEncode({
          'message': 'plain-ok',
          'count': 1,
        });

        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(payload);
        await request.response.close();
      });

      final response = await apiService.send(
        RequestModel.initial().copyWith(
          method: 'GET',
          url: 'http://${server.address.address}:${server.port}/plain',
        ),
      );

      expect(response.isSuccess, isTrue);
      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, contains('"message":"plain-ok"'));
      expect(response.jsonBody, isA<Map<String, dynamic>>());
      expect(response.jsonBody['message'], 'plain-ok');
      expect(response.jsonBody['count'], 1);
    });

    test('decodes a gzip-compressed JSON response', () async {
      server.listen((request) async {
        final payload = jsonEncode({
          'message': 'gzip-ok',
          'count': 2,
        });
        final bytes = gzip.encode(utf8.encode(payload));

        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
        request.response.add(bytes);
        await request.response.close();
      });

      final response = await apiService.send(
        RequestModel.initial().copyWith(
          method: 'GET',
          url: 'http://${server.address.address}:${server.port}/gzip',
        ),
      );

      expect(response.isSuccess, isTrue);
      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, contains('"message":"gzip-ok"'));
      expect(response.jsonBody, isA<Map<String, dynamic>>());
      expect(response.jsonBody['message'], 'gzip-ok');
      expect(response.jsonBody['count'], 2);
    });

    test('returns plain text when response is not JSON', () async {
      server.listen((request) async {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.text;
        request.response.write('hello from ApiLens');
        await request.response.close();
      });

      final response = await apiService.send(
        RequestModel.initial().copyWith(
          method: 'GET',
          url: 'http://${server.address.address}:${server.port}/text',
        ),
      );

      expect(response.isSuccess, isTrue);
      expect(response.body, 'hello from ApiLens');
      expect(response.jsonBody, isNull);
    });
  });
}
