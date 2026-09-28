import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class WhatsappBlastModal extends StatefulWidget {
  final int unpaidCount;

  const WhatsappBlastModal({super.key, required this.unpaidCount});

  @override
  State<WhatsappBlastModal> createState() => _WhatsappBlastModalState();
}

class _WhatsappBlastModalState extends State<WhatsappBlastModal> {
  bool _includePaymentLink = true;
  bool _includeQr = true;
  bool _notifyParents = false;
  final _customMessage = TextEditingController(
    text: 'Dear Resident, kindly clear your pending hostel rent to avoid late surcharge of रु 100/day.',
  );

  @override
  void dispose() {
    _customMessage.dispose();
    super.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.tealTintColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.send_rounded, color: context.tealFgColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WhatsApp Rent Broadcast', style: AppTypography.heading3.copyWith(color: context.textPrimaryColor)),
                        Text('Targeting ${widget.unpaidCount} Pending / Overdue Residents', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
                      ],
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
            Text('Broadcast Message Template', style: AppTypography.caption.copyWith(color: context.textSecondaryColor)),
            const SizedBox(height: 6),
            TextField(
              controller: _customMessage,
              maxLines: 4,
              style: TextStyle(fontSize: 12.5, color: context.textPrimaryColor),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _includePaymentLink,
              title: Text('Include personalized payment reminder link', style: TextStyle(fontSize: 12, color: context.textPrimaryColor)),
              onChanged: (v) => setState(() => _includePaymentLink = v ?? true),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _includeQr,
              title: Text('Attach Hostel QR code image', style: TextStyle(fontSize: 12, color: context.textPrimaryColor)),
              onChanged: (v) => setState(() => _includeQr = v ?? true),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _notifyParents,
              title: Text('Also copy emergency guardian WhatsApp for >7d overdue', style: TextStyle(fontSize: 12, color: context.textPrimaryColor)),
              onChanged: (v) => setState(() => _notifyParents = v ?? false),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('WhatsApp Blast dispatched to ${widget.unpaidCount} recipients!'),
                      backgroundColor: const Color(0xFF0D9488),
                    ),
                  );
                },
                icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                label: Text('Send WhatsApp Blast (${widget.unpaidCount})', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

