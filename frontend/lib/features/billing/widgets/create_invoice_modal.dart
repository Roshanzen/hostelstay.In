import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/tenant.dart';

class CreateInvoiceModal extends StatefulWidget {
  final List<Tenant> tenants;
  final Future<void> Function({
    required String tenantId,
    required String type,
    required double amount,
    required DateTime dueDate,
    String? note,
  }) onInvoiceCreated;

  const CreateInvoiceModal({
    super.key,
    required this.tenants,
    required this.onInvoiceCreated,
  });

  @override
  State<CreateInvoiceModal> createState() => _CreateInvoiceModalState();
}

class _CreateInvoiceModalState extends State<CreateInvoiceModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedTenantId;
  String _selectedType = 'Utility';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _types = ['Utility', 'Maintenance', 'Rent', 'Meal'];

  @override
  void initState() {
    super.initState();
    if (widget.tenants.isNotEmpty) {
      _selectedTenantId = widget.tenants.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (_selectedTenantId == null || _selectedTenantId!.isEmpty) {
      setState(() => _errorMessage = 'Please select a resident.');
      return;
    }

    final amt = double.tryParse(_amountController.text.trim());
    if (amt == null || amt <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount greater than 0.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onInvoiceCreated(
        tenantId: _selectedTenantId!,
        type: _selectedType,
        amount: amt,
        dueDate: _dueDate,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice created successfully!'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted && _errorMessage == null) {
        setState(() => _isSubmitting = false);
      }
    }
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
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Create Ad-Hoc Invoice', style: AppTypography.heading3.copyWith(color: context.textPrimaryColor)),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: context.textSecondaryColor),
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.redTintColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.redFgColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: context.redFgColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            Text('Select Resident *', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedTenantId,
              isExpanded: true,
              dropdownColor: context.cardColor,
              items: widget.tenants.map((t) {
                return DropdownMenuItem(
                  value: t.id,
                  child: Text(
                    '${t.fullName} (${t.roomNumber})',
                    style: TextStyle(fontSize: 13, color: context.textPrimaryColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedTenantId = val),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            Text('Invoice Category', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: 6),
            Row(
              children: _types.map((type) {
                final isSel = _selectedType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary : context.surfaceSecondaryColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSel ? AppColors.primary : context.borderColor),
                      ),
                      child: Center(
                        child: Text(
                          type,
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
            const SizedBox(height: 12),
            Text('Amount (₹) *', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 1500',
                prefixIcon: Icon(Icons.currency_rupee, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            Text('Due Date', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: context.surfaceSecondaryColor,
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd MMM yyyy').format(_dueDate), style: TextStyle(fontSize: 13, color: context.textPrimaryColor)),
                    Icon(Icons.calendar_today_outlined, size: 16, color: context.textSecondaryColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Description / Note', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'e.g. Monthly laundry or electricity split',
                prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Generate Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
