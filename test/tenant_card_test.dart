import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hms/core/utils/currency_formatter.dart';
import 'package:hms/features/tenants/widgets/tenant_card.dart';
import 'package:hms/features/tenants/widgets/tenant_details_sheet.dart';
import 'package:hms/models/tenant.dart';

void main() {
  const sampleOverdueTenant = Tenant(
    id: 't-1',
    fullName: 'Aarav Sharma',
    initials: 'AS',
    phoneNumber: '9841234567',
    email: 'aarav@gmail.com',
    organizationOrCollege: 'Pulchowk Campus',
    isKycVerified: true,
    paymentStatus: TenantPaymentStatus.overdue,
    statusLabel: '8d Late',
    roomNumber: '101',
    bedSlot: 'B1',
    floor: '1st Floor',
    roomType: 'Double Shared',
    joinedDate: 'Jan 15, 2024',
    monthlyRent: 8500,
    outstandingBalance: 9000,
    totalCycleAmount: 9000,
    dueSince: 'May 1, 2024',
  );

  const samplePaidTenant = Tenant(
    id: 't-2',
    fullName: 'Pooja Thapa',
    initials: 'PT',
    phoneNumber: '9801234567',
    email: 'pooja@gmail.com',
    organizationOrCollege: 'Apex College',
    isKycVerified: false,
    paymentStatus: TenantPaymentStatus.paid,
    statusLabel: 'Paid',
    roomNumber: '202',
    bedSlot: 'A',
    floor: '2nd Floor',
    roomType: 'Single Deluxe',
    joinedDate: 'Feb 1, 2024',
    monthlyRent: 12000,
    outstandingBalance: 0,
    totalCycleAmount: 12000,
    nextDueDate: 'June 1, 2024',
  );

  testWidgets('TenantCard renders dynamic tenant fields and triggers onCollect',
      (WidgetTester tester) async {
    bool collected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantCard(
            tenant: sampleOverdueTenant,
            onCollect: () {
              collected = true;
            },
          ),
        ),
      ),
    );

    // Verify dynamic fields
    expect(find.text('Aarav Sharma'), findsOneWidget);
    expect(find.text('AS'), findsOneWidget);
    expect(find.textContaining('9841234567'), findsOneWidget);
    expect(find.textContaining('Pulchowk Campus'), findsWidgets);
    expect(find.text('8d Late'), findsOneWidget);
    expect(find.textContaining('101 • Bed B1'), findsOneWidget);
    expect(find.textContaining('1st Floor • Double Shared'), findsOneWidget);
    expect(find.textContaining('Due since May 1, 2024'), findsOneWidget);
    expect(find.text(CurrencyFormatter.format(9000)), findsWidgets);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);

    // Tap Collect button
    final collectFinder = find.widgetWithText(ElevatedButton, 'Collect');
    expect(collectFinder, findsOneWidget);
    await tester.tap(collectFinder);
    await tester.pump();

    expect(collected, isTrue);
  });

  testWidgets('TenantCard opens TenantDetailsSheet on tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantCard(
            tenant: samplePaidTenant,
            onCollect: () {},
          ),
        ),
      ),
    );

    expect(find.text('Pooja Thapa'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text(CurrencyFormatter.format(12000)), findsOneWidget);

    // Tap on card to open details bottom sheet
    await tester.tap(find.text('Pooja Thapa'));
    await tester.pumpAndSettle();

    expect(find.byType(TenantDetailsSheet), findsOneWidget);
    expect(find.textContaining('pooja@gmail.com'), findsWidgets);
  });
}
