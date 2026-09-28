import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/expense.dart';

class AddExpenseModal extends StatefulWidget {
  final Function(Expense newExpense) onExpenseAdded;
  final bool isPettyCash;

  const AddExpenseModal({
    super.key,
    required this.onExpenseAdded,
    this.isPettyCash = false,
  });

  @override
  State<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.mess;
  String _paymentMode = 'Cash Voucher';

  @override
  void initState() {
    super.initState();
    if (widget.isPettyCash) {
      _titleController.text = 'Daily Kitchen Veg & Milk';
      _vendorController.text = 'Local Market';
      _amountController.text = '850';
      _paymentMode = 'Cash Voucher';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid expense title and amount')),
      );
      return;
    }

    String catLabel;
    switch (_category) {
      case ExpenseCategory.mess:
        catLabel = 'Food & Meals • Kitchen';
        break;
      case ExpenseCategory.utilities:
        catLabel = 'Utilities • Electricity / Water';
        break;
      case ExpenseCategory.salaries:
        catLabel = 'Staff Salaries • Security & Staff';
        break;
      case ExpenseCategory.maintenance:
        catLabel = 'Maintenance & Repair';
        break;
      case ExpenseCategory.supplies:
        catLabel = 'Supplies & Sanitization';
        break;
      case ExpenseCategory.other:
        catLabel = 'Operational Miscellaneous';
        break;
    }

    final exp = Expense(
      id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: _category,
      categoryLabel: catLabel,
      vendorOrLocation: _vendorController.text.isEmpty ? 'Property' : _vendorController.text.trim(),
      amount: amount,
      paymentMode: _paymentMode,
      voucherDoc: 'Voucher #${DateTime.now().millisecondsSinceEpoch.toString().substring(8)} Signed',
      transactionRef: 'Expense Out',
      timestamp: 'Just now',
      dateGroup: 'TODAY',
    );

    widget.onExpenseAdded(exp);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Expense "${exp.title}" of ${CurrencyFormatter.format(exp.amount)} logged in ledger.'),
        backgroundColor: const Color(0xFF0D9488),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.primaryTintColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primaryAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.isPettyCash ? 'Quick Petty Cash Log' : 'Add Property Expense',
                      style: AppTypography.heading3.copyWith(color: context.textPrimaryColor),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: context.textSecondaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Expense Description *', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Vegetables & Groceries'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount (रु) *', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.payments_outlined, size: 16)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ExpenseCategory>(
                        initialValue: _category,
                        dropdownColor: context.cardColor,
                        items: [
                          DropdownMenuItem(value: ExpenseCategory.mess, child: Text('Mess & Food', style: TextStyle(fontSize: 12, color: context.textPrimaryColor))),
                          DropdownMenuItem(value: ExpenseCategory.maintenance, child: Text('Maintenance', style: TextStyle(fontSize: 12, color: context.textPrimaryColor))),
                          DropdownMenuItem(value: ExpenseCategory.utilities, child: Text('Utilities', style: TextStyle(fontSize: 12, color: context.textPrimaryColor))),
                          DropdownMenuItem(value: ExpenseCategory.salaries, child: Text('Salaries', style: TextStyle(fontSize: 12, color: context.textPrimaryColor))),
                          DropdownMenuItem(value: ExpenseCategory.supplies, child: Text('Supplies', style: TextStyle(fontSize: 12, color: context.textPrimaryColor))),
                        ],
                        onChanged: (v) => setState(() => _category = v!),
                        decoration: const InputDecoration(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Vendor / Payee / Location', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _vendorController,
              decoration: const InputDecoration(hintText: 'e.g. Block B Kitchen / Vendor Name'),
            ),
            const SizedBox(height: 14),
            Text('Payment Mode', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: 6),
            Row(
              children: ['eSewa', 'Cash Voucher', 'Khalti', 'Fonepay'].map((m) {
                final isSel = _paymentMode == m;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMode = m),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF9A3412) : context.surfaceSecondaryColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSel ? const Color(0xFF9A3412) : context.borderColor),
                      ),
                      child: Center(
                        child: Text(
                          m,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : context.textPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A3412)),
                child: const Text('Post to Ledger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
