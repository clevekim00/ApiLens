import 'package:apilens/core/network/models/response_model.dart';
import 'package:apilens/features/response/widgets/response_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ResponseViewer supports body search and header filtering',
      (tester) async {
    const response = ResponseModel(
      statusCode: 200,
      statusMessage: 'OK',
      headers: {
        'content-type': ['application/json'],
        'x-request-id': ['abc-123'],
      },
      body: '{"message":"alpha beta alpha"}',
      jsonBody: {'message': 'alpha beta alpha'},
      durationMs: 42,
      sizeBytes: 32,
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 640,
              child: ResponseViewer(response: response),
            ),
          ),
        ),
      ),
    );

    expect(find.text('200 OK'), findsOneWidget);
    expect(find.text('Search ready'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Search body'), 'alpha');
    await tester.pump();

    expect(find.text('2 matches'), findsOneWidget);

    await tester.tap(find.text('Headers (2)'));
    await tester.pumpAndSettle();

    expect(find.text('2 total'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Filter headers'),
      'content',
    );
    await tester.pump();

    expect(find.text('1 of 2'), findsOneWidget);
    expect(find.text('content-type'), findsOneWidget);
    expect(find.text('x-request-id'), findsNothing);
  });
}
