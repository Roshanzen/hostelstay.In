import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/room.dart';
import 'allocate_bed_modal.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final Function(String roomId, String slotId, String name, String phone)? onAllocate;
  final Function(String slotId)? onAllocateSlot;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoomCard({
    super.key,
    required this.room,
    this.onAllocate,
    this.onAllocateSlot,
    this.onEdit,
    this.onDelete,
  });

  void _showAllocateModal(BuildContext context, String slotId) {
    if (onAllocateSlot != null) {
      onAllocateSlot!(slotId);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AllocateBedModal(
        roomNumber: room.roomNumber,
        slotId: slotId,
        onAllocate: (name, phone) {
          onAllocate?.call(room.id, slotId, name, phone);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusBg;
    Color statusColor;
    String statusText;

    if (room.isVacant) {
      statusBg = context.tealTintColor;
      statusColor = context.tealFgColor;
      statusText = 'Vacant (${room.vacantCount})';
    } else if (room.isPartial) {
      statusBg = context.orangeTintColor;
      statusColor = context.orangeFgColor;
      statusText = '${room.occupiedCount}/${room.totalCapacity} Occupied';
    } else {
      statusBg = context.surfaceSecondaryColor;
      statusColor = context.textSecondaryColor;
      statusText = 'Full';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: context.borderColor),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.primaryTintColor,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(
                        Icons.meeting_room_rounded,
                        size: 20,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.roomNumber,
                          style: AppTypography.heading3.copyWith(color: context.textPrimaryColor),
                        ),
                        Text(
                          '${room.sharingType} • ${room.floor}',
                          style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${CurrencyFormatter.format(room.rentAmount)}/bed',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (onEdit != null || onDelete != null) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, size: 18, color: context.textSecondaryColor),
                        padding: EdgeInsets.zero,
                        onSelected: (val) {
                          if (val == 'edit') onEdit?.call();
                          if (val == 'delete') onDelete?.call();
                        },
                        itemBuilder: (ctx) => [
                          if (onEdit != null)
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16, color: context.textPrimaryColor),
                                  const SizedBox(width: 8),
                                  Text('Edit Room', style: TextStyle(fontSize: 13, color: context.textPrimaryColor)),
                                ],
                              ),
                            ),
                          if (onDelete != null)
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 16, color: context.redFgColor),
                                  const SizedBox(width: 8),
                                  Text('Delete Room', style: TextStyle(fontSize: 13, color: context.redFgColor)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: context.dividerColor),

          // Bed Slots List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: room.slots.length,
            separatorBuilder: (context, index) => Divider(height: 1, indent: 48, color: context.dividerColor),
            itemBuilder: (ctx, i) {
              final slot = room.slots[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Bed Slot Icon / Tag
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: slot.isOccupied ? context.surfaceSecondaryColor : context.tealTintColor,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        slot.slotId,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: slot.isOccupied ? context.textSecondaryColor : context.tealFgColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Slot Resident details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                slot.tenantName ?? (slot.isOccupied ? 'Occupied' : 'Bed Available'),
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: slot.isOccupied ? context.textPrimaryColor : context.tealFgColor,
                                ),
                              ),
                              if (slot.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, size: 14, color: AppColors.teal),
                              ],
                            ],
                          ),
                          Text(
                            slot.tenantSubtitle ?? '',
                            style: AppTypography.caption.copyWith(fontSize: 11, color: context.textSecondaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Action
                    if (!slot.isOccupied)
                      InkWell(
                        onTap: () => _showAllocateModal(context, slot.slotId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: const Text(
                            '+ Allocate',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else if (slot.tenantPhone != null && slot.tenantPhone!.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.phone_outlined, size: 18, color: context.textSecondaryColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Contact ${slot.tenantName}: ${slot.tenantPhone}')),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
