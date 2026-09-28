import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hms/backend/core/api_client.dart';
import 'package:hms/features/tenants/screens/add_tenant_screen.dart';
import 'package:hms/models/room.dart';
import 'package:hms/models/tenant.dart';

void main() {
  final testRooms = [
    Room(
      id: 'room-6',
      roomNumber: 'Room A',
      floor: 'Floor 1',
      sharingType: '2-Sharing',
      rentAmount: 12000,
      totalCapacity: 2,
      slots: const [
        RoomSlot(slotId: 'A', isOccupied: true, tenantName: 'Existing Tenant'),
        RoomSlot(slotId: 'B', isOccupied: false, tenantName: 'Bed Available'),
      ],
      amenities: const ['WiFi', 'AC'],
    ),
  ];

  testWidgets('AddTenantScreen formats dynamic success toast and passes resolved room/bed', (WidgetTester tester) async {
    Tenant? addedTenant;
    String? passedRoomId;
    String? passedBedId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTenantScreen(
            rooms: testRooms,
            onTenantAdded: (tenant, {roomId, bedId}) async {
              addedTenant = tenant;
              passedRoomId = roomId;
              passedBedId = bedId;
            },
          ),
        ),
      ),
    );

    // Fill tenant legal name
    await tester.enterText(find.byType(TextField).first, 'Roshan');
    await tester.pumpAndSettle();

    // Scroll to and tap Save & Admit Tenant
    final saveButton = find.textContaining('Save & Admit Tenant');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pump();

    // Verify callback was called with correct data
    expect(addedTenant, isNotNull);
    expect(addedTenant!.fullName, equals('Roshan'));
    expect(passedRoomId, equals('room-6'));
    expect(passedBedId, equals('B'));

    // Verify toast is NOT "Room 201"
    expect(find.textContaining('Room 201'), findsNothing);
    expect(find.textContaining('Tenant Roshan admitted to Room A • Bed B!'), findsOneWidget);
  });

  testWidgets('AddTenantScreen displays backend error and stays open on occupied bed collision', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTenantScreen(
            rooms: testRooms,
            onTenantAdded: (tenant, {roomId, bedId}) async {
              throw ApiException(
                'Bed B in Room A is already occupied. Please select an available bed.',
                statusCode: 400,
                errors: {
                  'bed': ['Bed B in Room A is already occupied. Please select an available bed.']
                },
              );
            },
          ),
        ),
      ),
    );

    // Enter name
    await tester.enterText(find.byType(TextField).first, 'Roshan');
    await tester.pumpAndSettle();

    // Scroll to and tap Save & Admit Tenant
    final saveButton = find.textContaining('Save & Admit Tenant');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify error message is displayed
    expect(find.textContaining('Bed B in Room A is already occupied'), findsOneWidget);
    // Modal must NOT pop; screen is still present
    expect(find.byType(AddTenantScreen), findsOneWidget);
  });

  testWidgets('AddTenantScreen guards against double clicks while submitting', (WidgetTester tester) async {
    final completer = Completer<void>();
    int calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTenantScreen(
            rooms: testRooms,
            onTenantAdded: (tenant, {roomId, bedId}) async {
              calls++;
              await completer.future;
            },
          ),
        ),
      ),
    );

    // Enter name
    await tester.enterText(find.byType(TextField).first, 'Roshan');
    await tester.pumpAndSettle();

    // Scroll to and tap Save & Admit Tenant
    final saveButton = find.textContaining('Save & Admit Tenant');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    // First tap
    await tester.tap(saveButton);
    await tester.pump(); // Starts submitting

    // Button should now show spinner or 'Admitting Tenant...'
    expect(find.text('Admitting Tenant...'), findsOneWidget);
    expect(calls, equals(1));

    // Try tapping again while submitting
    await tester.tap(find.text('Admitting Tenant...'));
    await tester.pump();
    expect(calls, equals(1)); // Must NOT trigger again

    // Complete async action
    completer.complete();
    await tester.pumpAndSettle();
  });
}
