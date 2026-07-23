import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:village_app/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const VillageApp());
    // Just verify the app renders — no crash
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
