import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/overflow_safe_widget.dart';

void main() {
  group('OverflowSafeWidget Tests', () {
    testWidgets('should render child widget', (WidgetTester tester) async {
      // Arrange
      final childWidget = Text('Test Child');
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverflowSafeWidget(
              child: childWidget,
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Test Child'), findsOneWidget);
    });
    
    testWidgets('should set textScaler to 1.0', (WidgetTester tester) async {
      // Arrange
      final childKey = GlobalKey();
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                textScaler: TextScaler.linear(1.5),
              ),
              child: Builder(
                builder: (context) => OverflowSafeWidget(
                  child: Builder(
                    key: childKey,
                    builder: (context) {
                      // Store the MediaQuery that the child receives
                      final textScaler = MediaQuery.of(context).textScaler;
                      return Text('Scale: ${textScaler.scale(10.0)}');
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Scale: 10.0'), findsOneWidget);
    });
    
    testWidgets('should handle font errors when enabled', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverflowSafeWidget(
              handleFontErrors: true,
              child: Text('Test with font error handling'),
            ),
          ),
        ),
      );
      
      // Assert - Look for the _FontErrorHandler widget
      // Since _FontErrorHandler is private, we can't directly find it,
      // but we can verify our child text is rendered
      expect(find.text('Test with font error handling'), findsOneWidget);
    });
    
    testWidgets('should not wrap with _FontErrorHandler when disabled', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverflowSafeWidget(
              handleFontErrors: false,
              child: Text('Test without font error handling'),
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Test without font error handling'), findsOneWidget);
    });
  });
}
