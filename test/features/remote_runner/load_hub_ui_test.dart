import 'package:apilens/features/remote_runner/presentation/screens/load_hub_screen.dart';
import 'package:apilens/features/remote_runner/presentation/widgets/agent_update_panel.dart';
import 'package:apilens/features/remote_runner/presentation/widgets/machine_table.dart';
import 'package:apilens/features/remote_runner/presentation/widgets/metrics_overview.dart';
import 'package:apilens/features/remote_runner/presentation/widgets/run_monitor_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('LoadHubScreen renders tabs and summary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadHubScreen.sample(),
      ),
    );

    expect(find.text('Load Hub'), findsOneWidget);
    expect(find.text('Machines'), findsWidgets);
    expect(find.text('Runs'), findsOneWidget);
    expect(find.text('Metrics'), findsOneWidget);
    expect(find.text('Agent Updates'), findsOneWidget);
    expect(find.byType(MachineTable), findsOneWidget);
  });

  testWidgets('LoadHubScreen switches to metrics and update panels',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadHubScreen.sample(),
      ),
    );

    await tester.tap(find.text('Metrics'));
    await tester.pumpAndSettle();
    expect(find.byType(MetricsOverview), findsOneWidget);
    expect(find.text('Requests'), findsWidgets);

    await tester.tap(find.text('Agent Updates'));
    await tester.pumpAndSettle();
    expect(find.byType(AgentUpdatePanel), findsOneWidget);
    expect(find.text('Rollout upgrade-1'), findsOneWidget);
  });

  testWidgets('LoadHubScreen keeps compact layout usable on narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LoadHubScreen.sample(),
      ),
    );

    expect(find.byType(MachineTable), findsOneWidget);
    expect(find.byType(RunMonitorPanel), findsNothing);
  });
}
