import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class AllocateBedModal extends StatefulWidget {
  final String roomNumber;
  final String slotId;
  final Function(String name, String phone) onAllocate;

  const AllocateBedModal({
    super.key,
    required this.roomNumber,
    required this.slotId,
    required this.onAllocate,
  });

  @override
  State<AllocateBedModal> createState() => _AllocateBedModalState();
}

class _AllocateBedModalState extends State<AllocateBedModal> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter tenant name')),
      );
      return;
    }
    widget.onAllocate(name, phone.isEmpty ? '+91 98700 00000' : phone);
    Navigator.pop(context);
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Allocate ${widget.roomNumber}', style: AppTypography.heading3.copyWith(color: context.textPrimaryColor)),
                  Text('Assigning Bed ${widget.slotId}', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: context.textSecondaryColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Tenant Full Name *', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'e.g. Aryan Malhotra'),
          ),
          const SizedBox(height: 12),
          Text('Phone Number', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '+91 98712 34567'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
              child: const Text('Confirm & Allocate Bed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

