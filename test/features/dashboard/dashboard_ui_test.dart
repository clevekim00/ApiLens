import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apilens/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:apilens/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:apilens/features/dashboard/presentation/widgets/traffic_chart.dart';

void main() {
  group('Dashboard UI Tests', () {
    testWidgets('DashboardScreen renders all key components', (WidgetTester tester) async {
      // Build the DashboardScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardScreen(),
          ),
        ),
      );

      // Verify Header
      expect(find.text('API Dashboard Summary - Global Payments'), findsOneWidget);
      expect(find.text('Real-time overview of your API orchestration health and performance.'), findsOneWidget);

      // Verify StatCards exist
      expect(find.byType(StatCard), findsNWidgets(4));
      expect(find.text('API HEALTH'), findsOneWidget);
      expect(find.text('TOTAL REQUESTS'), findsOneWidget);

      // Verify Traffic Chart exists
      expect(find.byType(TrafficChart), findsOneWidget);

      // Verify Recent Performance section
      expect(find.text('RECENT API PERFORMANCE'), findsOneWidget);
      expect(find.text('Checkout API'), findsOneWidget);
    });

    testWidgets('StatCard displays correct data and trend', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'TEST STAT',
              value: '100%',
              trend: '5%',
              isPositive: true,
              icon: Icons.check,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('TEST STAT'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('5%'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      
      // Verify positive trend icon
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('Dashboard handles responsive layout (Narrow Width)', (WidgetTester tester) async {
      // Set a narrow screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardScreen(),
          ),
        ),
      );

      // In narrow mode, the performance items should be in a Column
      // We can check if they are laid out vertically by checking their offsets
      final checkoutApiFinder = find.text('Checkout API');
      final paymentInitFinder = find.text('Payment-Init');
      
      final checkoutOffset = tester.getTopLeft(checkoutApiFinder);
      final paymentOffset = tester.getTopLeft(paymentInitFinder);

      // In a Column, Payment-Init should be below Checkout API (y coordinate is larger)
      expect(paymentOffset.dy > checkoutOffset.dy, isTrue);

      // Reset view size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
