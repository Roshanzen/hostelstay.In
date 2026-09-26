import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/room.dart';
import '../../../backend/core/api_client.dart';

class AddRoomModal extends StatefulWidget {
  final Function(Room room) onRoomAdded;
  final Room? initialRoom;

  const AddRoomModal({
    super.key,
    required this.onRoomAdded,
    this.initialRoom,
  });

  @override
  State<AddRoomModal> createState() => _AddRoomModalState();
}

class _AddRoomModalState extends State<AddRoomModal> {
  late final TextEditingController _roomNumController;
  late final TextEditingController _rentController;
  String _selectedFloor = '1st Floor';
  String _sharingType = '2-Sharing AC';
  int _capacity = 2;
  bool _hasAc = true;
  bool _hasBalcony = true;
  bool _hasAttachedBath = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final r = widget.initialRoom;
    _roomNumController = TextEditingController(text: r != null ? r.roomNumber.replaceAll('Room ', '') : '');
    _rentController = TextEditingController(text: r != null ? r.rentAmount.round().toString() : '');
    if (r != null) {
      _selectedFloor = r.floor;
      _capacity = r.totalCapacity;
      _sharingType = r.sharingType;
      _hasAc = r.amenities.contains('AC');
      _hasBalcony = r.amenities.contains('Balcony');
      _hasAttachedBath = r.amenities.contains('Attached Bath');
    }
  }

  @override
  void dispose() {
    _roomNumController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    final roomNumber = _roomNumController.text.trim();
    if (roomNumber.isEmpty) {
      setState(() => _errorMessage = 'Please enter room number (e.g. 101, A)');
      return;
    }

    final rent = double.tryParse(_rentController.text.trim());
    if (rent == null || rent <= 0) {
      setState(() => _errorMessage = 'Please enter a valid monthly rent');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final List<String> amenities = [];
    if (_hasAc) amenities.add('AC');
    if (_hasBalcony) amenities.add('Balcony');
    if (_hasAttachedBath) amenities.add('Attached Bath');

    final slots = List.generate(
      _capacity,
      (index) => RoomSlot(
        slotId: String.fromCharCode(65 + index),
        isOccupied: false,
        tenantName: 'Bed Available',
        tenantSubtitle: 'Ready for immediate move-in',
      ),
    );

    final room = Room(
      id: widget.initialRoom?.id ?? 'r-${DateTime.now().millisecondsSinceEpoch}',
      roomNumber: roomNumber.startsWith('Room ') ? roomNumber : 'Room $roomNumber',
      floor: _selectedFloor,
      sharingType: _sharingType,
      rentAmount: rent,
      totalCapacity: _capacity,
      slots: slots,
      amenities: amenities,
    );

    try {
      await widget.onRoomAdded(room);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.initialRoom != null ? '${room.roomNumber} updated successfully' : '${room.roomNumber} added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          if (e is ApiException) {
            if (e.errors != null && e.errors!.containsKey('room_number')) {
              _errorMessage = 'Room $roomNumber already exists in this property.';
            } else {
              _errorMessage = e.message;
            }
          } else {
            _errorMessage = e.toString().replaceAll('Exception: ', '');
          }
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
                      child: const Icon(Icons.add_home_rounded, color: AppColors.primaryAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.initialRoom != null ? 'Edit Room' : 'Add New Room',
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
            Text('Room Number *', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _roomNumController,
              decoration: const InputDecoration(hintText: 'e.g. 203'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Floor', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFloor,
                        dropdownColor: context.cardColor,
                        items: ['Ground Floor', '1st Floor', '2nd Floor', '3rd Floor']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f, style: TextStyle(fontSize: 13, color: context.textPrimaryColor))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedFloor = v!),
                        decoration: const InputDecoration(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Capacity (Beds)', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: _capacity,
                        dropdownColor: context.cardColor,
                        items: [1, 2, 3, 4]
                            .map((c) => DropdownMenuItem(value: c, child: Text('$c Beds', style: TextStyle(fontSize: 13, color: context.textPrimaryColor))))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _capacity = v!;
                            _sharingType = '$_capacity-Sharing ${_hasAc ? 'AC' : 'Non-AC'}';
                          });
                        },
                        decoration: const InputDecoration(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Monthly Rent Per Bed (₹) *', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _rentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'e.g. 11000'),
            ),
            const SizedBox(height: 14),
            Text('Room Amenities', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('AC'),
                  selected: _hasAc,
                  onSelected: (v) => setState(() => _hasAc = v),
                ),
                FilterChip(
                  label: const Text('Balcony'),
                  selected: _hasBalcony,
                  onSelected: (v) => setState(() => _hasBalcony = v),
                ),
                FilterChip(
                  label: const Text('Attached Bath'),
                  selected: _hasAttachedBath,
                  onSelected: (v) => setState(() => _hasAttachedBath = v),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.redTintColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.redFgColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: context.redFgColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(fontSize: 12, color: context.redFgColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.initialRoom != null ? 'Save Changes' : 'Save Room', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

