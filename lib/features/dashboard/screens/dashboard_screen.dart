import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/invoice.dart';
import '../../../models/tenant.dart';
import '../../../shared/widgets/property_switcher_modal.dart';
import '../../../state/app_state.dart';
import 'analytics_screen.dart' as deep_analytics;
import '../../billing/widgets/add_expense_modal.dart';
import '../../billing/widgets/record_payment_modal.dart';
import '../../rooms/widgets/add_room_modal.dart';
import '../../tenants/screens/add_tenant_screen.dart';

class DashboardScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onProfileTap;
  final Function(int tabIndex) onNavigateToTab;

  const DashboardScreen({
    super.key,
    required this.state,
    required this.onProfileTap,
    required this.onNavigateToTab,
  });

  void _openPropertySwitcher(BuildContext context) {
    showPropertySwitcherModal(context, state);
  }

  void _openRecordPayment(BuildContext context, Tenant tenant) {
    final matchingInvoice = state.invoices
            .where((i) =>
                (i.tenantId == tenant.id || i.tenantName == tenant.fullName) &&
                i.status != InvoiceStatus.paid)
            .firstOrNull ??
        Invoice(
          id: '',
          tenantId: tenant.id,
          invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          tenantName: tenant.fullName,
          tenantInitials: tenant.initials,
          roomInfo: '${tenant.roomNumber} • ${tenant.bedSlot}',
          status: InvoiceStatus.overdue,
          statusBadgeText: 'Overdue',
          totalAmount: tenant.outstandingBalance > 0 ? tenant.outstandingBalance : tenant.monthlyRent,
          paidAmount: 0,
          outstandingAmount: tenant.outstandingBalance > 0 ? tenant.outstandingBalance : tenant.monthlyRent,
          dueDate: 'Due',
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordPaymentModal(
        invoice: matchingInvoice,
        onPaymentRecorded: (amount, method, txRef) async {
          await state.recordPayment(
            tenant.id,
            amount,
            method,
            matchingInvoice.id.isNotEmpty ? matchingInvoice.id : null,
            txRef,
          );
        },
      ),
    );
  }

  void _openAddTenant(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddTenantScreen(
          rooms: state.rooms,
          onTenantAdded: (tenant, {roomId, bedId}) =>
              state.addTenant(tenant, targetRoomId: roomId, targetBedId: bedId),
        ),
      ),
    );
  }

  void _openAddRoom(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddRoomModal(
        onRoomAdded: (room) => state.addRoom(room),
      ),
    );
  }

  void _openAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddExpenseModal(
        onExpenseAdded: (expense) => state.addExpense(expense),
      ),
    );
  }

  void _openAnalytics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => deep_analytics.AnalyticsScreen(state: state),
      ),
    );
  }

  void _sendReminder(BuildContext context, Tenant tenant) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment reminder dispatched to ${tenant.fullName} (${tenant.phoneNumber})'),
        backgroundColor: AppColors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertyName = state.currentProperty.name.isNotEmpty
        ? state.currentProperty.name
        : 'Kathmandu Hostel';
    final overdueList = state.overdueTenants;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: AppTypography.heading2,
            ),
            InkWell(
              onTap: () => _openPropertySwitcher(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    propertyName,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: AppColors.primaryAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics_outlined, color: context.textPrimaryColor, size: 22),
            tooltip: 'Reports & Analytics',
            onPressed: () => _openAnalytics(context),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_none_rounded, color: context.textPrimaryColor, size: 22),
                if (state.openComplaintsCount > 0 || state.unpaidTenantsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${state.unpaidTenantsCount} overdue payments • ${state.openComplaintsCount} open tickets',
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: context.primaryTintColor,
                child: Text(
                  state.warden.name.isNotEmpty ? state.warden.name[0].toUpperCase() : 'W',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => state.loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2x2 KPI Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  _buildKpiCard(
                    context,
                    title: 'Occupancy',
                    value: '${state.occupiedBeds}/${state.totalBeds}',
                    subtext: '${state.occupancyRate.toStringAsFixed(0)}% Occupied',
                    icon: Icons.hotel_rounded,
                    accentColor: AppColors.primaryAccent,
                    onTap: () => onNavigateToTab(1),
                  ),
                  _buildKpiCard(
                    context,
                    title: 'Invoiced',
                    value: CurrencyFormatter.format(state.totalInvoiced),
                    subtext: 'Collected: ${CurrencyFormatter.format(state.totalCollected)}',
                    icon: Icons.payments_rounded,
                    accentColor: context.tealFgColor,
                    onTap: () => onNavigateToTab(3),
                  ),
                  _buildKpiCard(
                    context,
                    title: 'Overdue Rent',
                    value: CurrencyFormatter.format(state.totalOverdue),
                    subtext: '${state.unpaidTenantsCount} Pending',
                    icon: Icons.warning_amber_rounded,
                    accentColor: state.totalOverdue > 0 ? context.redFgColor : context.tealFgColor,
                    onTap: () => onNavigateToTab(3),
                  ),
                  _buildKpiCard(
                    context,
                    title: 'Complaints',
                    value: '${state.openComplaintsCount}',
                    subtext: '${state.urgentComplaintsCount} Urgent',
                    icon: Icons.build_circle_outlined,
                    accentColor: state.urgentComplaintsCount > 0 ? context.orangeFgColor : context.textSecondaryColor,
                    onTap: () => onNavigateToTab(4),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quick Warden Operations
              const Text('Quick Actions', style: AppTypography.heading3),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.person_add_alt_1_rounded,
                      label: '+ Tenant',
                      onTap: () => _openAddTenant(context),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.meeting_room_rounded,
                      label: '+ Room',
                      onTap: () => _openAddRoom(context),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.receipt_long_rounded,
                      label: '+ Invoice',
                      onTap: () => onNavigateToTab(3),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Log Expense',
                      onTap: () => _openAddExpense(context),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.bar_chart_rounded,
                      label: 'Analytics',
                      onTap: () => _openAnalytics(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Overdue Ledger / Action Required
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Overdue Rent', style: AppTypography.heading3),
                  if (overdueList.isNotEmpty)
                    TextButton(
                      onPressed: () => onNavigateToTab(3),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: Text(
                        'View All (${overdueList.length})',
                        style: AppTypography.caption.copyWith(color: AppColors.primaryAccent, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (overdueList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.tealTintColor,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(Icons.check_circle_outline_rounded, color: context.tealFgColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('All Rent Up to Date', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            const Text('No pending or overdue balances across residents.', style: AppTypography.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: overdueList.take(5).length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final tenant = overdueList[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ctx.cardColor,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: ctx.borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: ctx.redTintColor,
                            child: Text(
                              tenant.initials,
                              style: TextStyle(color: ctx.redFgColor, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tenant.fullName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                Text(
                                  '${tenant.roomNumber} • ${tenant.phoneNumber}',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(tenant.outstandingBalance > 0 ? tenant.outstandingBalance : tenant.monthlyRent),
                                style: AppTypography.bodyMedium.copyWith(color: ctx.redFgColor, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _sendReminder(context, tenant),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: ctx.elevatedSurfaceColor,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: ctx.borderColor),
                                      ),
                                      child: Text(
                                        'Remind',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: ctx.textPrimaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _openRecordPayment(context, tenant),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Collect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Recent Rooms Occupancy Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Rooms Overview', style: AppTypography.heading3),
                  TextButton(
                    onPressed: () => onNavigateToTab(1),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text(
                      'View All (${state.rooms.length})',
                      style: AppTypography.caption.copyWith(color: AppColors.primaryAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (state.rooms.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.meeting_room_outlined, size: 36, color: context.textMutedColor),
                        const SizedBox(height: 8),
                        const Text('No rooms configured yet', style: AppTypography.bodySmall),
                        TextButton(
                          onPressed: () => _openAddRoom(context),
                          child: const Text('+ Add First Room'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.rooms.take(3).length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final r = state.rooms[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ctx.cardColor,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: ctx.borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ctx.primaryTintColor,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: const Icon(Icons.meeting_room_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.roomNumber, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                Text('${r.sharingType} • ${CurrencyFormatter.format(r.rentAmount)}/mo', style: AppTypography.caption),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: r.vacantCount > 0 ? ctx.tealTintColor : ctx.elevatedSurfaceColor,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              r.vacantCount > 0 ? '${r.vacantCount} Vacant' : 'Full',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: r.vacantCount > 0 ? ctx.tealFgColor : ctx.textSecondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: context.borderColor),
          boxShadow: context.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(color: context.textSecondaryColor, fontWeight: FontWeight.w500),
                ),
                Icon(icon, size: 18, color: accentColor),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.heading2.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: AppTypography.caption.copyWith(fontSize: 11, color: context.textMutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: context.borderColor),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryAccent),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.badge.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
