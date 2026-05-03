import 'package:apilens/core/network/graphql_service.dart';
import 'package:apilens/features/graphql/application/graphql_controller.dart';
import 'package:apilens/features/graphql/data/graphql_request_repository.dart';
import 'package:apilens/features/graphql/domain/models/graphql_request_config.dart';
import 'package:apilens/features/graphql/domain/models/graphql_response.dart';
import 'package:apilens/features/graphql/presentation/widgets/graphql_editors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validateVariablesJson accepts objects and rejects invalid variables',
      () {
    expect(validateVariablesJson(''), isNull);
    expect(validateVariablesJson('{}'), isNull);
    expect(validateVariablesJson('{"id":"1"}'), isNull);
    expect(validateVariablesJson('[1, 2]'), contains('JSON object'));
    expect(validateVariablesJson('{bad'), contains('Invalid variables JSON'));
  });

  test('GraphQLController blocks execution when variables JSON is invalid',
      () async {
    final service = _CountingGraphQLService();
    final controller = GraphQLController(_FakeGraphQLRepository(), service);

    controller.updateVariables('{bad');
    await controller.executeRequest();

    expect(service.executeCount, 0);
    expect(controller.state.isLoading, isFalse);
    expect(controller.state.error, contains('Invalid variables JSON'));
    expect(
      controller.state.variablesValidationError,
      contains('Invalid variables JSON'),
    );
  });

  testWidgets('GraphQLVariablesEditor shows validation status', (tester) async {
    var formatted = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 720,
              height: 420,
              child: GraphQLVariablesEditor(
                variables: '{bad',
                validationError: 'Invalid variables JSON: test',
                onChanged: (_) {},
                onFormat: () => formatted = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Invalid variables JSON: test'), findsOneWidget);
    expect(find.text('Format JSON'), findsOneWidget);

    await tester.tap(find.text('Format JSON'));
    await tester.pump();

    expect(formatted, isTrue);
  });
}

class _CountingGraphQLService extends GraphQLService {
  int executeCount = 0;

  @override
  Future<GraphQLResponse> execute(GraphQLRequestConfig config) async {
    executeCount++;
    return GraphQLResponse(
      data: {'ok': true},
      rawText: '{"data":{"ok":true}}',
      statusCode: 200,
      durationMs: 1,
    );
  }
}

class _FakeGraphQLRepository extends GraphQLRequestRepository {
  GraphQLRequestConfig? saved;

  @override
  Future<void> save(GraphQLRequestConfig config) async {
    saved = config;
  }

  @override
  Future<GraphQLRequestConfig?> get(String id) async => saved;

  @override
  Future<List<GraphQLRequestConfig>> getAll() async {
    return saved == null ? const [] : [saved!];
  }

  @override
  Future<void> delete(String id) async {
    if (saved?.id == id) saved = null;
  }
}
