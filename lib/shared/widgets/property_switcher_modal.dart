import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../state/app_state.dart';
import '../../models/property.dart';

void showPropertySwitcherModal(BuildContext context, AppState state) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.surfaceColor,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ctx.primaryTintColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Switch Assigned Property',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ctx.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: ctx.textSecondaryColor),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Select a branch to switch real-time occupancy, rooms, and billing registers.',
              style: TextStyle(fontSize: 11.5, color: ctx.textSecondaryColor),
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: ctx.borderColor),
            const SizedBox(height: 8),
            if (state.availableProperties.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No additional branches currently assigned to this warden account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: ctx.textSecondaryColor),
                  ),
                ),
              )
            else
              ...state.availableProperties.map((Property p) {
                final isCurrent = p.id == state.currentProperty.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? ctx.primaryTintColor : ctx.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent ? AppColors.primaryAccent : ctx.borderColor,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primary.withValues(alpha: 0.16)
                            : ctx.elevatedSurfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.apartment_rounded,
                        color: isCurrent ? AppColors.primaryAccent : ctx.textSecondaryColor,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: isCurrent
                                  ? (ctx.isDarkMode ? AppColors.darkOrangeText : const Color(0xFF9A3412))
                                  : ctx.textPrimaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.primary.withValues(alpha: 0.18) : ctx.indigoTintColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.block.isNotEmpty ? p.block : 'MAIN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isCurrent ? ctx.orangeFgColor : ctx.indigoFgColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${p.address} • ${p.totalBeds} Beds',
                      style: TextStyle(fontSize: 10.5, color: ctx.textSecondaryColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.check_circle_rounded, color: ctx.tealFgColor, size: 22)
                        : Icon(Icons.chevron_right_rounded, color: ctx.textMutedColor, size: 20),
                    onTap: () {
                      Navigator.pop(ctx);
                      state.switchProperty(p);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to ${p.name} (${p.block})'),
                          backgroundColor: const Color(0xFF0D9488),
                        ),
                      );
                    },
                  ),
                );
              }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}


