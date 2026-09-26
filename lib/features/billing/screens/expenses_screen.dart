import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/custom_search_bar.dart';
import '../../../state/app_state.dart';
import '../widgets/add_expense_modal.dart';

class ExpensesScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onProfileTap;

  const ExpensesScreen({
    super.key,
    required this.state,
    required this.onProfileTap,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddExpenseModal(
        onExpenseAdded: (exp) => widget.state.addExpense(exp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final expenses = widget.state.filteredExpenses;
        final allExpenses = widget.state.expenses;

        final totalExpenses = allExpenses.fold<double>(0, (s, e) => s + e.amount);
        final totalCollections = widget.state.invoices.fold<double>(0, (s, i) => s + i.paidAmount);
        final netOperatingCash = totalCollections - totalExpenses;

        final filters = [
          'All (${allExpenses.length})',
          'Mess',
          'Utilities',
          'Salaries',
          'Maintenance',
        ];

        return Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: AppBar(
            backgroundColor: context.surfaceColor,
            elevation: 0,
            titleSpacing: 16,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expenses',
                  style: AppTypography.heading2.copyWith(color: context.textPrimaryColor),
                ),
                Text(
                  'Spent: ${CurrencyFormatter.format(totalExpenses)} • Net Cash: ${CurrencyFormatter.format(netOperatingCash)}',
                  style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.primaryAccent, size: 26),
                tooltip: 'Log Expense',
                onPressed: _openAddExpense,
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
                // Search Bar
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search expense title or vendor...',
                  onChanged: (val) => widget.state.setExpenseSearchQuery(val),
                ),
                const SizedBox(height: 12),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((opt) {
                      final key = opt.split(' ').first;
                      final isSelected = widget.state.expenseFilter == key;

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
                          onSelected: (_) => widget.state.setExpenseFilter(key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Expenses List
                if (expenses.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 48, color: context.textMutedColor),
                        const SizedBox(height: 12),
                        Text(
                          'No expense records found',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Log operational expenses such as groceries, electricity, or repairs.',
                          style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openAddExpense,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Log Expense'),
                        ),
                      ],
                    ),
                  )
                else
                  ...expenses.map(
                    (exp) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: context.borderColor),
                        boxShadow: context.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.orangeTintColor,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Icon(Icons.receipt_outlined, color: context.orangeFgColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.title,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                                Text(
                                  '${exp.categoryLabel} • ${exp.dateGroup}',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 11,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(exp.amount),
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.redFgColor,
                                ),
                              ),
                              Text(
                                exp.paymentMode,
                                style: AppTypography.caption.copyWith(fontSize: 11, color: context.textMutedColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
