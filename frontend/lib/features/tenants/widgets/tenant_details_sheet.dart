import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/tenant.dart';

class TenantDetailsSheet extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onCheckout;

  const TenantDetailsSheet({
    super.key,
    required this.tenant,
    this.onRecordPayment,
    this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: context.primaryTintColor,
                  child: Text(
                    tenant.initials,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryAccent, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(tenant.fullName, style: AppTypography.heading3.copyWith(color: context.textPrimaryColor)),
                          const SizedBox(width: 6),
                          if (tenant.isKycVerified)
                            Icon(Icons.verified_rounded, size: 16, color: context.tealFgColor),
                        ],
                      ),
                      Text(
                        '${tenant.phoneNumber} • ${tenant.email}',
                        style: AppTypography.bodySmall.copyWith(color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: context.textSecondaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: context.dividerColor),
            const SizedBox(height: 12),
            _buildSectionTitle(context, 'Allocation & Lease Details'),
            _buildInfoRow(context, 'Room & Bed', '${tenant.roomNumber} (${tenant.bedSlot}) - ${tenant.floor}'),
            _buildInfoRow(context, 'Room Type', tenant.roomType),
            _buildInfoRow(context, 'Joined Date', tenant.joinedDate),
            _buildInfoRow(context, 'Monthly Rent', CurrencyFormatter.format(tenant.monthlyRent)),
            _buildInfoRow(context, 'Security Deposit', CurrencyFormatter.format(tenant.securityDeposit)),
            _buildInfoRow(context, 'Payment Status', tenant.statusLabel),
            if (tenant.outstandingBalance > 0)
              _buildInfoRow(context, 'Outstanding Balance', CurrencyFormatter.format(tenant.outstandingBalance)),
            const SizedBox(height: 12),
            _buildSectionTitle(context, 'Academic / Professional & KYC'),
            _buildInfoRow(context, 'Organization/College', tenant.organizationOrCollege),
            _buildInfoRow(context, 'ID Document', '${tenant.idType ?? 'Citizenship'} (${tenant.idNumber ?? 'Verified'})'),
            const SizedBox(height: 12),
            _buildSectionTitle(context, 'Guardian & Emergency Contact'),
            _buildInfoRow(context, 'Guardian Name', '${tenant.guardianName ?? 'N/A'} (${tenant.guardianRelation ?? 'Parent'})'),
            _buildInfoRow(context, 'Guardian Phone', tenant.guardianPhone ?? 'N/A'),
            _buildInfoRow(context, 'Permanent Address', tenant.permanentAddress ?? 'N/A'),
            const SizedBox(height: 20),
            if (onRecordPayment != null) ...[
              SizedBox(

                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onRecordPayment?.call();
                  },
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.white),
                  label: const Text('Record Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${tenant.fullName}...')),
                      );
                    },
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call Tenant'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening WhatsApp chat with ${tenant.fullName}...')),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                    label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                  ),
                ),
              ],
            ),
            if (onCheckout != null && tenant.statusLabel != 'Checked Out') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Check Out ${tenant.fullName}?'),
                        content: Text(
                          'Are you sure you want to check out ${tenant.fullName} from ${tenant.roomNumber} (${tenant.bedSlot})? The assigned bed will be released immediately.',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                              onCheckout?.call();
                            },
                            child: const Text('Confirm Checkout', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.logout_rounded, size: 16, color: context.redFgColor),
                  label: Text('Check Out Resident', style: TextStyle(color: context.redFgColor, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.redFgColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textSecondaryColor, letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

