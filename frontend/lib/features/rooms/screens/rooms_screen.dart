import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/room.dart';
import '../../../shared/widgets/custom_search_bar.dart';
import '../../../state/app_state.dart';
import '../../tenants/screens/add_tenant_screen.dart';
import '../widgets/room_card.dart';
import '../widgets/add_room_modal.dart';

class RoomsScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onProfileTap;

  const RoomsScreen({
    super.key,
    required this.state,
    required this.onProfileTap,
  });

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddRoom() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddRoomModal(
        onRoomAdded: (newRoom) => widget.state.addRoom(newRoom),
      ),
    );
  }

  void _openEditRoom(Room room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddRoomModal(
        initialRoom: room,
        onRoomAdded: (updatedRoom) => widget.state.updateRoom(updatedRoom),
      ),
    );
  }

  void _confirmDeleteRoom(Room room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${room.roomNumber}?'),
        content: Text('Are you sure you want to delete ${room.roomNumber}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.state.deleteRoom(room.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${room.roomNumber} deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete room: $e'),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openAllocateBed(Room room, String slotId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddTenantScreen(
          rooms: widget.state.rooms,
          initialRoom: room,
          initialBedSlot: slotId,
          onTenantAdded: (tenant, {roomId, bedId}) {
            return widget.state.addTenant(tenant, targetRoomId: roomId, targetBedId: bedId);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final rooms = widget.state.filteredRooms;
        final totalRooms = widget.state.rooms.length;
        final totalBeds = widget.state.rooms.fold(0, (sum, r) => sum + r.totalCapacity);
        final occupiedBeds = widget.state.rooms.fold(0, (sum, r) => sum + r.occupiedCount);
        final vacantBeds = (totalBeds - occupiedBeds).clamp(0, totalBeds);
        final fullRooms = widget.state.rooms.where((r) => r.isFull).length;
        final partialRooms = widget.state.rooms.where((r) => r.isPartial).length;
        final vacantRooms = widget.state.rooms.where((r) => r.isVacant).length;

        final filterOptions = [
          'All Rooms',
          'Vacant',
          'Partial',
          'Full',
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
                  'Rooms',
                  style: AppTypography.heading2.copyWith(color: context.textPrimaryColor),
                ),
                Text(
                  'Total $totalRooms • Vacant $vacantBeds beds ($occupiedBeds/$totalBeds occupied)',
                  style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, color: AppColors.primaryAccent, size: 26),
                  tooltip: 'Add Room',
                  onPressed: _openAddRoom,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
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
                // Search bar
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search room number (e.g. 101, 202)...',
                  onChanged: (val) => widget.state.setRoomSearchQuery(val),
                ),
                const SizedBox(height: 12),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions.map((opt) {
                      final isSelected = widget.state.roomFilter == opt;
                      String countLabel = '';
                      if (opt == 'All Rooms') countLabel = ' ($totalRooms)';
                      if (opt == 'Vacant') countLabel = ' ($vacantRooms)';
                      if (opt == 'Partial') countLabel = ' ($partialRooms)';
                      if (opt == 'Full') countLabel = ' ($fullRooms)';

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            '$opt$countLabel',
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
                          onSelected: (_) => widget.state.setRoomFilter(opt),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Rooms List
                if (rooms.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.meeting_room_outlined, size: 48, color: context.textMutedColor),
                        const SizedBox(height: 12),
                        Text(
                          'No rooms match your filter',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try clearing your search query or add a new room.',
                          style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openAddRoom,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Room'),
                        ),
                      ],
                    ),
                  )
                else
                  ...rooms.map(
                    (room) => RoomCard(
                      room: room,
                      onAllocateSlot: (slotId) => _openAllocateBed(room, slotId),
                      onEdit: () => _openEditRoom(room),
                      onDelete: () => _confirmDeleteRoom(room),
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
