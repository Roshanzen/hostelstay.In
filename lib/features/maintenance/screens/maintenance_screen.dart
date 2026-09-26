import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/room.dart';
import '../../../shared/widgets/custom_search_bar.dart';
import '../../../state/app_state.dart';
import '../../../backend/models/ticket.dart' as db_ticket;

class MaintenanceScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onProfileTap;

  const MaintenanceScreen({
    super.key,
    required this.state,
    required this.onProfileTap,
  });

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateTicket() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateTicketModal(
        rooms: widget.state.rooms,
        onCreated: ({
          required String title,
          required String category,
          required String priority,
          String? roomId,
          double? cost,
          String? description,
        }) async {
          await widget.state.addMaintenanceTicket(
            title: title,
            category: category,
            priority: priority,
            roomId: roomId,
            cost: cost,
            description: description,
          );
        },
      ),
    );
  }

  void _openTicketDetails(db_ticket.TicketModel ticket, String roomLabel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TicketDetailsSheet(
        ticket: ticket,
        roomLabel: roomLabel,
        onUpdated: (status, costIncurred, description) async {
          await widget.state.updateMaintenanceTicketStatus(
            ticket.id,
            status,
            costIncurred: costIncurred,
            description: description,
          );
        },
      ),
    );
  }

  String _resolveRoomLabel(String roomId) {
    if (roomId.isEmpty) return 'Common Area';
    final matched = widget.state.rooms.where((r) => r.id == roomId || r.roomNumber == roomId).firstOrNull;
    if (matched != null) return matched.roomNumber;
    return roomId.startsWith('Room ') ? roomId : 'Room $roomId';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final allTickets = widget.state.tickets;

        final openCount = allTickets.where((t) => t.status == db_ticket.TicketStatus.open || t.status == db_ticket.TicketStatus.inProgress).length;
        final resolvedCount = allTickets.where((t) => t.status == db_ticket.TicketStatus.resolved).length;
        final urgentCount = allTickets.where((t) => t.priority == db_ticket.TicketPriority.high || t.priority == db_ticket.TicketPriority.critical).length;

        final tickets = allTickets.where((t) {
          if (_selectedFilter == 'Open' && t.status != db_ticket.TicketStatus.open) return false;
          if (_selectedFilter == 'In Progress' && t.status != db_ticket.TicketStatus.inProgress) return false;
          if (_selectedFilter == 'Resolved' && t.status != db_ticket.TicketStatus.resolved) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final roomLbl = _resolveRoomLabel(t.roomId).toLowerCase();
            return t.title.toLowerCase().contains(q) ||
                t.category.name.toLowerCase().contains(q) ||
                roomLbl.contains(q) ||
                (t.description?.toLowerCase().contains(q) ?? false);
          }
          return true;
        }).toList();

        final filters = ['All', 'Open', 'In Progress', 'Resolved'];

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
                  'Maintenance',
                  style: AppTypography.heading2.copyWith(color: context.textPrimaryColor),
                ),
                Text(
                  '$openCount Open • $resolvedCount Resolved • $urgentCount Urgent',
                  style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.primaryAccent, size: 26),
                tooltip: 'New Ticket',
                onPressed: _openCreateTicket,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 4),
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
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search ticket title, room, or category...',
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((opt) {
                      final isSelected = _selectedFilter == opt;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            opt,
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
                          onSelected: (_) => setState(() => _selectedFilter = opt),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (tickets.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.build_circle_outlined, size: 48, color: context.textMutedColor),
                        const SizedBox(height: 12),
                        Text(
                          'No maintenance tickets',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to log a repair or maintenance request.',
                          style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openCreateTicket,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Ticket'),
                        ),
                      ],
                    ),
                  )
                else
                  ...tickets.map(
                    (ticket) {
                      final roomLabel = _resolveRoomLabel(ticket.roomId);
                      return InkWell(
                        onTap: () => _openTicketDetails(ticket, roomLabel),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(color: context.borderColor),
                            boxShadow: context.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _priorityColor(ticket.priority),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Icon(
                                  _priorityIcon(ticket.priority),
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ticket.title,
                                      style: AppTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${ticket.category.name.toUpperCase()} • $roomLabel${(ticket.costIncurred ?? 0) > 0 ? ' • ${CurrencyFormatter.format(ticket.costIncurred!)}' : ''}',
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 11,
                                        color: context.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(ticket.status),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _statusLabel(ticket.status),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _priorityColor(db_ticket.TicketPriority priority) {
    switch (priority) {
      case db_ticket.TicketPriority.high:
      case db_ticket.TicketPriority.critical:
        return AppColors.red;
      case db_ticket.TicketPriority.low:
        return AppColors.teal;
      default:
        return AppColors.orange;
    }
  }

  IconData _priorityIcon(db_ticket.TicketPriority priority) {
    switch (priority) {
      case db_ticket.TicketPriority.high:
      case db_ticket.TicketPriority.critical:
        return Icons.priority_high_rounded;
      case db_ticket.TicketPriority.low:
        return Icons.arrow_downward_rounded;
      default:
        return Icons.remove_red_eye_rounded;
    }
  }

  Color _statusColor(db_ticket.TicketStatus status) {
    switch (status) {
      case db_ticket.TicketStatus.resolved:
        return AppColors.teal;
      case db_ticket.TicketStatus.inProgress:
        return AppColors.orange;
      case db_ticket.TicketStatus.closed:
        return AppColors.textMuted;
      default:
        return AppColors.red;
    }
  }

  String _statusLabel(db_ticket.TicketStatus status) {
    switch (status) {
      case db_ticket.TicketStatus.resolved:
        return 'Resolved';
      case db_ticket.TicketStatus.inProgress:
        return 'In Progress';
      case db_ticket.TicketStatus.closed:
        return 'Cancelled';
      default:
        return 'Open';
    }
  }
}

class _CreateTicketModal extends StatefulWidget {
  final List<Room> rooms;
  final Future<void> Function({
    required String title,
    required String category,
    required String priority,
    String? roomId,
    double? cost,
    String? description,
  }) onCreated;

  const _CreateTicketModal({
    required this.rooms,
    required this.onCreated,
  });

  @override
  State<_CreateTicketModal> createState() => _CreateTicketModalState();
}

class _CreateTicketModalState extends State<_CreateTicketModal> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _costController = TextEditingController();
  String _selectedCategory = 'Plumbing';
  String _selectedPriority = 'Medium';
  String? _selectedRoomId;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _categories = ['Plumbing', 'Electrical', 'Cleaning', 'Other'];
  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    if (widget.rooms.isNotEmpty) {
      _selectedRoomId = widget.rooms.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter an issue title.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final cost = double.tryParse(_costController.text.trim());
      await widget.onCreated(
        title: title,
        category: _selectedCategory.toLowerCase(),
        priority: _selectedPriority.toLowerCase(),
        roomId: _selectedRoomId,
        cost: cost,
        description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance ticket created!'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
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
                      child: const Icon(Icons.build_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('New Maintenance Ticket', style: AppTypography.heading3),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.redTintColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.redFgColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: context.redFgColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const Text('Issue Title *', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Leaking tap in washroom'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Room / Location', style: AppTypography.caption),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedRoomId,
                        isExpanded: true,
                        dropdownColor: context.cardColor,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Common Area', style: TextStyle(fontSize: 13)),
                          ),
                          ...widget.rooms.map(
                            (r) => DropdownMenuItem<String?>(
                              value: r.id,
                              child: Text(r.roomNumber, style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedRoomId = v),
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
                      const Text('Category', style: AppTypography.caption),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        dropdownColor: context.cardColor,
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v!),
                        decoration: const InputDecoration(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Priority Level', style: AppTypography.caption),
            const SizedBox(height: 6),
            Row(
              children: _priorities.map((p) {
                final isSel = _selectedPriority == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPriority = p),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primaryDark : context.surfaceSecondaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : context.textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Text('Estimated / Repair Cost (₹)', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0 (Optional)'),
            ),
            const SizedBox(height: 12),
            const Text('Description / Notes', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Additional details about the repair...'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetailsSheet extends StatefulWidget {
  final db_ticket.TicketModel ticket;
  final String roomLabel;
  final Future<void> Function(String status, double? costIncurred, String? description) onUpdated;

  const _TicketDetailsSheet({
    required this.ticket,
    required this.roomLabel,
    required this.onUpdated,
  });

  @override
  State<_TicketDetailsSheet> createState() => _TicketDetailsSheetState();
}

class _TicketDetailsSheetState extends State<_TicketDetailsSheet> {
  late String _status;
  late final TextEditingController _costController;
  late final TextEditingController _descController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.ticket.status == db_ticket.TicketStatus.resolved
        ? 'resolved'
        : widget.ticket.status == db_ticket.TicketStatus.inProgress
            ? 'inProgress'
            : widget.ticket.status == db_ticket.TicketStatus.closed
                ? 'cancelled'
                : 'open';
    _costController = TextEditingController(
      text: (widget.ticket.costIncurred ?? 0) > 0 ? widget.ticket.costIncurred!.round().toString() : '',
    );
    _descController = TextEditingController(text: widget.ticket.description ?? '');
  }

  @override
  void dispose() {
    _costController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final cost = double.tryParse(_costController.text.trim());
      await widget.onUpdated(_status, cost, _descController.text.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket updated successfully!'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ticket: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = [
      {'value': 'open', 'label': 'Open'},
      {'value': 'inProgress', 'label': 'In Progress'},
      {'value': 'resolved', 'label': 'Resolved'},
      {'value': 'cancelled', 'label': 'Cancelled'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.ticket.title, style: AppTypography.heading3),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.ticket.category.name.toUpperCase()} • ${widget.roomLabel} • Logged ${DateFormat('dd MMM yyyy').format(widget.ticket.createdAt)}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Update Status', style: AppTypography.caption),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statusOptions.map((opt) {
                final isSel = _status == opt['value'];
                return GestureDetector(
                  onTap: () => setState(() => _status = opt['value']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primaryDark : context.surfaceSecondaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      opt['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : context.textSecondaryColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text('Repair Cost Incurred (₹)', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0'),
            ),
            const SizedBox(height: 14),
            const Text('Resolution Notes / Description', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Add technician notes or resolution details...'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Ticket Updates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
