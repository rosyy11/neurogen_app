// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neurogen_app/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(NeuroGenApp());

    // Check if the home screen title is displayed.
    expect(find.text('NeuroGen'), findsOneWidget);

    // Check if one of the tool names is displayed.
    expect(find.text('AI Image Generator'), findsOneWidget);
  });
}
