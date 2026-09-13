import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splixa_app/core/splixa_loading.dart';

void main() {
  testWidgets('skeleton becomes static when reduced motion is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: SplixaSkeletonView(type: SplixaSkeletonType.dashboard),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ShaderMask), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skeleton exposes one localized loading announcement', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: SplixaSkeletonView())),
      ),
    );

    expect(find.bySemanticsLabel('Loading...'), findsOneWidget);
  });
}
