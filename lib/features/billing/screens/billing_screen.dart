import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/invoice.dart';
import '../../../shared/widgets/custom_search_bar.dart';
import '../../../state/app_state.dart';
import '../widgets/invoice_card.dart';
import '../widgets/record_payment_modal.dart';
import '../widgets/create_invoice_modal.dart';
import 'expenses_screen.dart';
import 'rent_cycles_screen.dart';

class BillingScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onProfileTap;

  const BillingScreen({
    super.key,
    required this.state,
    required this.onProfileTap,
  });

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateInvoice() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateInvoiceModal(
        tenants: widget.state.tenants,
        onInvoiceCreated: ({
          required String tenantId,
          required String type,
          required double amount,
          required DateTime dueDate,
          String? note,
        }) async {
          await widget.state.createAdHocInvoice(
            tenantId: tenantId,
            type: type,
            amount: amount,
            dueDate: dueDate,
            note: note,
          );
        },
      ),
    );
  }

  void _openExpensesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ExpensesScreen(
          state: widget.state,
          onProfileTap: widget.onProfileTap,
        ),
      ),
    );
  }

  void _openRecordPayment(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordPaymentModal(
        invoice: invoice,
        onPaymentRecorded: (amount, method, txRef) async {
          await widget.state.recordPayment(
            invoice.tenantId,
            amount,
            method,
            invoice.id,
            txRef,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final invoices = widget.state.filteredInvoices;
        final allInvoices = widget.state.invoices;

        final totalInvoicesCount = allInvoices.length;
        final paidInvoices = allInvoices.where((i) => i.status == InvoiceStatus.paid).toList();
        final pendingInvoices = allInvoices.where((i) => i.status == InvoiceStatus.grace || i.status == InvoiceStatus.unpaid).toList();
        final overdueInvoices = allInvoices.where((i) => i.status == InvoiceStatus.overdue).toList();

        final totalBilled = allInvoices.fold<double>(0, (s, i) => s + i.totalAmount);
        final totalCollected = allInvoices.fold<double>(0, (s, i) => s + i.paidAmount);
        final totalOverdue = overdueInvoices.fold<double>(0, (s, i) => s + i.outstandingAmount);

        final filters = [
          'All ($totalInvoicesCount)',
          'Overdue (${overdueInvoices.length})',
          'Pending (${pendingInvoices.length})',
          'Paid (${paidInvoices.length})',
        ];

        return Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: AppBar(
            backgroundColor: context.surfaceColor,
            elevation: 0,
            titleSpacing: 16,
            title: Builder(builder: (context) {
              final summary = widget.state.billingSummary;
              final summaryBilled = summary.totalInvoiced > 0 ? summary.totalInvoiced : totalBilled;
              final summaryOverdue = summary.overdueAmount > 0 ? summary.overdueAmount : totalOverdue;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoices & Billing',
                    style: AppTypography.heading2.copyWith(color: context.textPrimaryColor),
                  ),
                  Text(
                    'Total ${CurrencyFormatter.format(summaryBilled)} • Overdue ${CurrencyFormatter.format(summaryOverdue)}',
                    style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                  ),
                ],
              );
            }),

            actions: [
              IconButton(
                icon: const Icon(Icons.sync_rounded, size: 20),
                tooltip: 'Refresh Statuses',
                onPressed: () async {
                  await widget.state.refreshInvoiceStatuses();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice overdue statuses refreshed!'), duration: Duration(seconds: 2)),
                    );
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.autorenew_rounded, size: 20, color: context.tealFgColor),
                tooltip: 'Generate Rent Cycle',
                onPressed: () async {
                  try {
                    final res = await widget.state.generatePeriodInvoices();
                    if (context.mounted) {
                      final count = res['invoices_created'] ?? 0;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rent Cycle: $count new invoices created.'),
                          backgroundColor: const Color(0xFF0D9488),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
              TextButton.icon(
                onPressed: _openExpensesScreen,
                icon: Icon(Icons.outbox_rounded, size: 16, color: context.orangeFgColor),
                label: Text('Expenses', style: TextStyle(color: context.orangeFgColor, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded, color: AppColors.teal, size: 22),
                tooltip: 'Rent Cycles',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => RentCyclesScreen(
                        state: widget.state,
                        onProfileTap: widget.onProfileTap,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.primaryAccent, size: 26),
                tooltip: 'Generate Invoice',
                onPressed: _openCreateInvoice,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 4),
                child: InkWell(
                  onTap: widget.onProfileTap,
                  borderRadius: BorderRadius.circular(16),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: context.primaryTintColor,
                    child: Text(
                      widget.state.warden.name.isNotEmpty ? widget.state.warden.name[0].toUpperCase() : 'W',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => widget.state.loadAllData(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Reconciled Financial Metrics Bar
                Builder(builder: (context) {
                  final summary = widget.state.billingSummary;
                  final billed = summary.totalInvoiced > 0 ? summary.totalInvoiced : totalBilled;
                  final collected = summary.totalCollected > 0 ? summary.totalCollected : totalCollected;
                  final outstanding = summary.totalOutstanding > 0 ? summary.totalOutstanding : (billed - collected).clamp(0.0, double.infinity);
                  final overdue = summary.overdueAmount > 0 ? summary.overdueAmount : totalOverdue;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: context.borderColor),
                      boxShadow: context.cardShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric(context, 'Invoiced', CurrencyFormatter.format(billed), context.textPrimaryColor),
                        Container(height: 24, width: 1, color: context.dividerColor),
                        _buildMetric(context, 'Collected', CurrencyFormatter.format(collected), context.tealFgColor),
                        Container(height: 24, width: 1, color: context.dividerColor),
                        _buildMetric(context, 'Outstanding', CurrencyFormatter.format(outstanding), context.textPrimaryColor),
                        Container(height: 24, width: 1, color: context.dividerColor),
                        _buildMetric(context, 'Overdue', CurrencyFormatter.format(overdue), overdue > 0 ? context.redFgColor : context.tealFgColor),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Search Bar
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search by tenant name, room or invoice #...',
                  onChanged: (val) => widget.state.setInvoiceSearchQuery(val),
                ),
                const SizedBox(height: 12),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((opt) {
                      final key = opt.split(' ').first;
                      final isSelected = widget.state.invoiceFilter == key;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : context.textPrimaryColor,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: context.cardColor,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : context.borderColor,
                          ),
                          onSelected: (_) => widget.state.setInvoiceFilter(key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Invoices List
                if (invoices.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: context.textMutedColor),
                        const SizedBox(height: 12),
                        Text(
                          'No invoices found',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try clearing your search query or generate new invoices.',
                          style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openCreateInvoice,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Generate Invoice'),
                        ),
                      ],
                    ),
                  )
                else
                  ...invoices.map(
                    (inv) => InvoiceCard(
                      invoice: inv,
                      onRecordPayment: () => _openRecordPayment(inv),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: context.textSecondaryColor, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor),
        ),
      ],
    );
  }
}
