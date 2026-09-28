import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/invoice.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onRecordPayment;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    Color statusBg;
    Color statusColor;

    switch (invoice.status) {
      case InvoiceStatus.paid:
        statusBg = context.tealTintColor;
        statusColor = context.tealFgColor;
        break;
      case InvoiceStatus.overdue:
        statusBg = context.redTintColor;
        statusColor = context.redFgColor;
        break;
      case InvoiceStatus.grace:
      case InvoiceStatus.unpaid:
        statusBg = context.orangeTintColor;
        statusColor = context.orangeFgColor;
        break;
      case InvoiceStatus.securityDeposit:
        statusBg = context.indigoTintColor;
        statusColor = context.indigoFgColor;
        break;
    }

    final hasDue = invoice.outstandingAmount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: context.borderColor),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: context.primaryTintColor,
                    child: Text(
                      invoice.tenantInitials,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.tenantName,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      Text(
                        '${invoice.roomInfo} • ${invoice.invoiceNumber}',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Text(
                  invoice.statusBadgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: context.dividerColor),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due: ${invoice.dueDate}',
                    style: AppTypography.caption.copyWith(fontSize: 11, color: context.textMutedColor),
                  ),
                  Text(
                    'Cycle: ${invoice.billingCycle}',
                    style: AppTypography.caption.copyWith(fontSize: 11, color: context.textSecondaryColor),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(invoice.totalAmount),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  if (hasDue)
                    Text(
                      'Pending: ${CurrencyFormatter.format(invoice.outstandingAmount)}',
                      style: AppTypography.caption.copyWith(
                        color: invoice.status == InvoiceStatus.overdue ? context.redFgColor : context.orangeFgColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    )
                  else
                    Text(
                      'Fully Paid',
                      style: AppTypography.caption.copyWith(color: context.tealFgColor, fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
          if (hasDue) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton(
                onPressed: onRecordPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
                child: const Text('Record Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
