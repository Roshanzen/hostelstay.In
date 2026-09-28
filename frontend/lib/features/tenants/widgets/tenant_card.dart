import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/tenant.dart';
import 'tenant_details_sheet.dart';

class TenantCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onCollect;
  final VoidCallback? onCheckout;

  const TenantCard({
    super.key,
    required this.tenant,
    required this.onCollect,
    this.onCheckout,
  });

  void _openDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TenantDetailsSheet(
        tenant: tenant,
        onRecordPayment: onCollect,
        onCheckout: onCheckout,
      ),
    );
  }

  _StatusConfig _resolveStatusConfig(BuildContext context) {
    switch (tenant.paymentStatus) {
      case TenantPaymentStatus.paid:
        return _StatusConfig(
          avatarBg: context.tealTintColor,
          avatarFg: context.tealFgColor,
          statusBg: context.tealTintColor,
          statusFg: context.tealFgColor,
          icon: Icons.check_circle_outline_rounded,
        );
      case TenantPaymentStatus.overdue:
        return _StatusConfig(
          avatarBg: context.redTintColor,
          avatarFg: context.redFgColor,
          statusBg: context.redTintColor,
          statusFg: context.redFgColor,
          icon: Icons.error_outline_rounded,
        );
      case TenantPaymentStatus.pending:
        return _StatusConfig(
          avatarBg: context.pendingTintColor,
          avatarFg: context.pendingFgColor,
          statusBg: context.pendingTintColor,
          statusFg: context.pendingFgColor,
          icon: Icons.schedule_rounded,
        );
      case TenantPaymentStatus.exitNotice:
        return _StatusConfig(
          avatarBg: context.purpleTintColor,
          avatarFg: context.purpleFgColor,
          statusBg: context.purpleTintColor,
          statusFg: context.purpleFgColor,
          icon: Icons.logout_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusConfig = _resolveStatusConfig(context);
    final isOverdue =
        tenant.paymentStatus == TenantPaymentStatus.overdue &&
        tenant.outstandingBalance > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isOverdue
              ? context.redFgColor.withValues(alpha: 0.4)
              : context.borderColor,
          width: isOverdue ? 1.2 : 1.0,
        ),
        boxShadow: context.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => _openDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, statusConfig),
                const SizedBox(height: 10),
                _buildRoomAndInfoBox(context),
                const SizedBox(height: 12),
                _buildFinancialAndActionRow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _StatusConfig config) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: config.avatarBg,
          child: Text(
            tenant.initials,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: config.avatarFg,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      tenant.fullName,
                      style: AppTypography.heading3.copyWith(color: context.textPrimaryColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (tenant.isKycVerified) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: context.tealFgColor,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${tenant.phoneNumber} • ${tenant.organizationOrCollege}',
                style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: config.statusBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (config.icon != null) ...[
                Icon(config.icon, size: 11, color: config.statusFg),
                const SizedBox(width: 3.5),
              ],
              Text(
                tenant.statusLabel,
                style: AppTypography.badge.copyWith(
                  color: config.statusFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoomAndInfoBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceSecondaryColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.meeting_room_outlined,
                    size: 14,
                    color: AppColors.primaryAccent,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${tenant.roomNumber} • Bed ${tenant.bedSlot}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              Text(
                '${tenant.floor} • ${tenant.roomType}',
                style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: tenant.dueSince != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 13,
                            color: context.redFgColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Due since ${tenant.dueSince}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.redFgColor,
                              ),
                            ),
                          ),
                        ],
                      )
                    : tenant.gracePeriodExp != null
                    ? Text(
                        'Grace Period: Exp ${tenant.gracePeriodExp}',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                      )
                    : tenant.checkoutDate != null
                    ? Text(
                        'Checkout: ${tenant.checkoutDate}',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                      )
                    : Text(
                        tenant.organizationOrCollege,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                tenant.checkoutDate != null
                    ? 'Deposit: ${CurrencyFormatter.format(tenant.securityDeposit)}'
                    : 'Joined ${tenant.joinedDate}',
                style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialAndActionRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tenant.paymentStatus == TenantPaymentStatus.paid) ...[
                Text('Monthly Rent', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.format(tenant.monthlyRent),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    if (tenant.nextDueDate != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '• Due ${tenant.nextDueDate}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.tealFgColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ] else if (tenant.paymentStatus ==
                  TenantPaymentStatus.overdue) ...[
                Text(
                  'Outstanding Balance',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.redFgColor,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.format(tenant.outstandingBalance),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.redFgColor,
                      ),
                    ),
                    if (tenant.totalCycleAmount > 0) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '/ ${CurrencyFormatter.format(tenant.totalCycleAmount)}',
                          style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ] else if (tenant.paymentStatus ==
                  TenantPaymentStatus.pending) ...[
                Text('Current Cycle Due', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.format(
                        tenant.outstandingBalance > 0
                            ? tenant.outstandingBalance
                            : tenant.monthlyRent,
                      ),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: context.pendingFgColor,
                      ),
                    ),
                    if (tenant.nextDueDate != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '• Due ${tenant.nextDueDate}',
                          style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ] else ...[
                Text('Exit Settlement', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                const SizedBox(height: 1),
                Text(
                  tenant.exitStatus ?? 'Notice Served',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.purpleFgColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconButton(
              context,
              icon: Icons.phone_outlined,
              tooltip: 'Call resident',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Calling ${tenant.fullName} (${tenant.phoneNumber})...',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            _buildIconButton(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: context.tealFgColor,
              tooltip: 'WhatsApp chat',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Opening WhatsApp with ${tenant.fullName}...',
                    ),
                    backgroundColor: AppColors.teal,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            if (tenant.outstandingBalance > 0)
              ElevatedButton.icon(
                onPressed: onCollect,
                icon: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 13,
                  color: Colors.white,
                ),
                label: const Text(
                  'Collect',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  elevation: 0,
                ),
              )
            else if (tenant.paymentStatus == TenantPaymentStatus.exitNotice)
              OutlinedButton(
                onPressed: () => _openDetails(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.purpleFgColor,
                  side: BorderSide(color: context.purpleFgColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
                child: const Text(
                  'Exit Details',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              )
            else
              OutlinedButton(
                onPressed: () => _openDetails(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.textSecondaryColor,
                  side: BorderSide(color: context.borderColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
                child: const Text(
                  'Details',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.cardColor,
        shape: CircleBorder(
          side: BorderSide(color: context.borderColor),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              icon,
              size: 15,
              color: iconColor ?? context.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusConfig {
  final Color avatarBg;
  final Color avatarFg;
  final Color statusBg;
  final Color statusFg;
  final IconData? icon;

  const _StatusConfig({
    required this.avatarBg,
    required this.avatarFg,
    required this.statusBg,
    required this.statusFg,
    this.icon,
  });
}
