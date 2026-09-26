import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hms/backend/core/api_client.dart';
import 'package:hms/features/rooms/widgets/add_room_modal.dart';

void main() {
  testWidgets('AddRoomModal validates required room number and rent', (WidgetTester tester) async {
    bool added = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddRoomModal(
            onRoomAdded: (room) async {
              added = true;
            },
          ),
        ),
      ),
    );

    // Tap Save Room with empty fields
    await tester.tap(find.textContaining('Save Room'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter room number (e.g. 101, A)'), findsOneWidget);
    expect(added, isFalse);
  });

  testWidgets('AddRoomModal handles duplicate room error cleanly without closing modal', (WidgetTester tester) async {
    int attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddRoomModal(
            onRoomAdded: (room) async {
              attempts++;
              if (room.roomNumber.contains('A')) {
                throw ApiException(
                  'Room number already exists in this property.',
                  statusCode: 400,
                  errors: {
                    'room_number': [
                      'A room with this number already exists in the selected property.'
                    ]
                  },
                );
              }
            },
          ),
        ),
      ),
    );

    // Enter duplicate room A
    await tester.enterText(find.byType(TextField).first, 'A');
    await tester.enterText(find.byType(TextField).last, '12000');
    await tester.pumpAndSettle();

    // Tap Save Room
    await tester.tap(find.textContaining('Save Room'));
    await tester.pumpAndSettle();

    // Modal must NOT close, and must display clear duplicate message
    expect(find.text('Room A already exists in this property.'), findsWidgets);
    expect(find.text('Add New Room'), findsOneWidget);
    expect(attempts, equals(1));

    // User corrects room number to B
    await tester.enterText(find.byType(TextField).first, 'B');
    await tester.pumpAndSettle();

    // Tap Save Room again
    await tester.tap(find.textContaining('Save Room'));
    await tester.pumpAndSettle();

    expect(attempts, equals(2));
  });

  testWidgets('AddRoomModal guards against double clicks while submitting', (WidgetTester tester) async {
    final completer = Completer<void>();
    int callCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddRoomModal(
            onRoomAdded: (room) async {
              callCount++;
              await completer.future;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '105');
    await tester.enterText(find.byType(TextField).last, '9000');
    await tester.pumpAndSettle();

    // First tap
    await tester.tap(find.textContaining('Save Room'));
    await tester.pump(); // Start async work, but don't finish completer

    // Verify progress indicator is showing and button is disabled
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Try tapping again while submitting
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pump();

    // Still only 1 call
    expect(callCount, equals(1));

    // Finish async submission
    completer.complete();
    await tester.pumpAndSettle();

    expect(callCount, equals(1));
  });
}
