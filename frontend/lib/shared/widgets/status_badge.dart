import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

enum BadgeVariant {
  paid,
  overdue,
  pending,
  vacant,
  full,
  maintenance,
  exitNotice,
  instantSync,
  verified,
  neutral,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.icon,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case BadgeVariant.paid:
      case BadgeVariant.verified:
        bg = context.tealTintColor;
        fg = context.tealFgColor;
        break;
      case BadgeVariant.overdue:
        bg = context.redTintColor;
        fg = context.redFgColor;
        break;
      case BadgeVariant.pending:
      case BadgeVariant.instantSync:
        bg = context.pendingTintColor;
        fg = context.pendingFgColor;
        break;
      case BadgeVariant.vacant:
        bg = context.tealTintColor;
        fg = context.tealFgColor;
        break;
      case BadgeVariant.full:
        bg = context.elevatedSurfaceColor;
        fg = context.textSecondaryColor;
        break;
      case BadgeVariant.maintenance:
        bg = context.redTintColor;
        fg = context.redFgColor;
        break;
      case BadgeVariant.exitNotice:
        bg = context.indigoTintColor;
        fg = context.indigoFgColor;
        break;
      case BadgeVariant.neutral:
        bg = context.elevatedSurfaceColor;
        fg = context.textSecondaryColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.badge.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

