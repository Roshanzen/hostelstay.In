import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/expense.dart';
import '../../../state/app_state.dart';

class AnalyticsScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback? onProfileTap;

  const AnalyticsScreen({
    super.key,
    required this.state,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final totalBeds = state.totalBeds;
        final occupiedBeds = state.occupiedBeds;
        final vacantBeds = totalBeds > occupiedBeds ? totalBeds - occupiedBeds : 0;
        final liveLoadPct = state.occupancyRate.toStringAsFixed(1);

        final totalInvoiced = state.invoices.fold<double>(0, (s, i) => s + i.totalAmount);
        final totalCollected = state.invoices.fold<double>(0, (s, i) => s + i.paidAmount);
        final totalDues = state.invoices.where((i) => !i.isFullyPaid).fold<double>(0, (s, i) => s + i.outstandingAmount);
        final totalExpenses = state.expenses.fold<double>(0, (s, e) => s + e.amount);
        final netOperatingCash = totalCollected - totalExpenses;

        final messExp = state.expenses.where((e) => e.category == ExpenseCategory.mess).fold<double>(0, (s, e) => s + e.amount);
        final salaryExp = state.expenses.where((e) => e.category == ExpenseCategory.salaries).fold<double>(0, (s, e) => s + e.amount);
        final utilExp = state.expenses.where((e) => e.category == ExpenseCategory.utilities).fold<double>(0, (s, e) => s + e.amount);
        final maintExp = state.expenses.where((e) => e.category == ExpenseCategory.maintenance).fold<double>(0, (s, e) => s + e.amount);

        final totalDeposits = state.tenants.fold<double>(0, (s, t) => s + t.securityDeposit);

        return Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: AppBar(
            backgroundColor: context.surfaceColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: context.textPrimaryColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reports & Analytics',
                  style: AppTypography.heading2,
                ),
                Text(
                  state.currentProperty.name.isNotEmpty ? state.currentProperty.name : 'HostelGhar PG',
                  style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Occupancy Card
              const Text('Occupancy Analytics', style: AppTypography.heading3),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: context.borderColor),
                  boxShadow: context.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Load',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        Text('$liveLoadPct% Occupied', style: TextStyle(fontWeight: FontWeight.w700, color: context.tealFgColor)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalBeds > 0 ? (occupiedBeds / totalBeds).clamp(0.0, 1.0) : 0.0,
                        backgroundColor: context.elevatedSurfaceColor,
                        valueColor: AlwaysStoppedAnimation<Color>(context.tealFgColor),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(context, 'Total Beds', '$totalBeds'),
                        _buildStat(context, 'Occupied', '$occupiedBeds'),
                        _buildStat(context, 'Vacant', '$vacantBeds'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Financial Performance
              const Text('Revenue & Cashflow', style: AppTypography.heading3),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: context.borderColor),
                  boxShadow: context.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildFinanceRow(context, 'Total Invoiced', CurrencyFormatter.format(totalInvoiced), context.textPrimaryColor),
                    const Divider(height: 16),
                    _buildFinanceRow(context, 'Collected Rent', CurrencyFormatter.format(totalCollected), context.tealFgColor),
                    const Divider(height: 16),
                    _buildFinanceRow(context, 'Pending / Overdue', CurrencyFormatter.format(totalDues), totalDues > 0 ? context.redFgColor : context.tealFgColor),
                    const Divider(height: 16),
                    _buildFinanceRow(context, 'Operational Expenses', CurrencyFormatter.format(totalExpenses), context.orangeFgColor),
                    const Divider(height: 16),
                    _buildFinanceRow(
                      context,
                      'Net Operating Cash',
                      CurrencyFormatter.format(netOperatingCash),
                      netOperatingCash >= 0 ? context.tealFgColor : context.redFgColor,
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Expense Breakdown
              const Text('Expense Breakdown', style: AppTypography.heading3),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: context.borderColor),
                  boxShadow: context.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildFinanceRow(context, 'Mess & Food Supplies', CurrencyFormatter.format(messExp), context.textPrimaryColor),
                    const Divider(height: 16),
                    _buildFinanceRow(context, 'Utilities (Water, Power, Net)', CurrencyFormatter.format(utilExp), context.textPrimaryColor),
                    const Divider(height: 16),
                    _buildFinanceRow(context, 'Staff Salaries', CurrencyFormatter.format(salaryExp), context.textPrimaryColor),
                    const Divider(height: 16),
                    _buildFinanceRow(context, 'Maintenance & Repairs', CurrencyFormatter.format(maintExp), context.textPrimaryColor),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Security Deposit Reserve
              const Text('Security Deposit Ledger', style: AppTypography.heading3),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: context.borderColor),
                  boxShadow: context.cardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Refundable Deposits',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        Text('Held in trust for ${state.tenants.length} tenants', style: AppTypography.caption),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(totalDeposits),
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: context.indigoFgColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: AppTypography.caption.copyWith(color: context.textSecondaryColor, fontSize: 11)),
      ],
    );
  }

  Widget _buildFinanceRow(BuildContext context, String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: context.textPrimaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
