import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/invoice.dart';

class RecordPaymentModal extends StatefulWidget {
  final Invoice invoice;
  final Future<void> Function(double amount, String paymentMethod, String txRef) onPaymentRecorded;

  const RecordPaymentModal({
    super.key,
    required this.invoice,
    required this.onPaymentRecorded,
  });

  @override
  State<RecordPaymentModal> createState() => _RecordPaymentModalState();
}

class _RecordPaymentModalState extends State<RecordPaymentModal> {
  late final TextEditingController _amountController;
  String _paymentMethod = 'Cash';
  final _refController = TextEditingController(text: 'RCP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.invoice.outstandingAmount.round().toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amt <= 0) {
      setState(() => _errorMessage = 'Please enter a valid payment amount greater than zero.');
      return;
    }


    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onPaymentRecorded(amt, _paymentMethod, _refController.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment of ${CurrencyFormatter.format(amt)} via $_paymentMethod recorded for ${widget.invoice.tenantName}!'),
          backgroundColor: const Color(0xFF0D9488),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Record Payment', style: AppTypography.heading3.copyWith(color: context.textPrimaryColor)),
                      Text(widget.invoice.invoiceNumber, style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                    ],
                  ),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.surfaceSecondaryColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.invoice.tenantName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.textPrimaryColor)),
                    Text(widget.invoice.roomInfo, style: TextStyle(fontSize: 11, color: context.textSecondaryColor)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Due Amount', style: TextStyle(fontSize: 10, color: context.textSecondaryColor)),
                    Text(
                      CurrencyFormatter.format(widget.invoice.outstandingAmount),
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.redFgColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Amount to Collect (रु) *', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimaryColor),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.payments_outlined, size: 18)),
          ),
          const SizedBox(height: 14),
          Text('Payment Mode', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['Cash', 'eSewa', 'Khalti', 'Fonepay', 'Bank Transfer'].map((m) {
              final isSel = _paymentMethod == m;
              return GestureDetector(
                onTap: () => setState(() => _paymentMethod = m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF9A3412) : context.surfaceSecondaryColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSel ? const Color(0xFF9A3412) : context.borderColor),
                  ),
                  child: Text(
                    m,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? Colors.white : context.textPrimaryColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text('Receipt / Transaction Reference', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: 6),
          TextField(
            controller: _refController,
            style: TextStyle(color: context.textPrimaryColor),
            decoration: const InputDecoration(hintText: 'e.g. eS-849201'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A3412)),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm & Issue Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

