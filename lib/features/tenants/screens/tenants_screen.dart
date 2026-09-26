import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/invoice.dart';
import '../../../models/tenant.dart';
import '../../../shared/widgets/custom_search_bar.dart';
import '../../../state/app_state.dart';
import '../widgets/tenant_card.dart';
import '../widgets/whatsapp_blast_modal.dart';
import '../../billing/widgets/record_payment_modal.dart';
import 'add_tenant_screen.dart';

class TenantsScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onProfileTap;

  const TenantsScreen({
    super.key,
    required this.state,
    required this.onProfileTap,
  });

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTenant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTenantScreen(
          rooms: widget.state.rooms,
          onTenantAdded: (t, {roomId, bedId}) => widget.state.addTenant(t, targetRoomId: roomId, targetBedId: bedId),
        ),
      ),
    );
  }

  void _openWhatsAppBlast(int unpaidCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WhatsappBlastModal(
        unpaidCount: unpaidCount,
      ),
    );
  }

  void _openRecordPayment(Tenant tenant) {
    final matchingInvoice = widget.state.invoices
            .where((i) =>
                (i.tenantId == tenant.id || i.tenantName == tenant.fullName) &&
                i.status != InvoiceStatus.paid)
            .firstOrNull ??
        Invoice(
          id: '',
          tenantId: tenant.id,
          invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          tenantName: tenant.fullName,
          tenantInitials: tenant.initials,
          roomInfo: '${tenant.roomNumber} • ${tenant.bedSlot}',
          status: InvoiceStatus.overdue,
          statusBadgeText: 'Due',
          totalAmount: tenant.outstandingBalance > 0 ? tenant.outstandingBalance : tenant.monthlyRent,
          paidAmount: 0,
          outstandingAmount: tenant.outstandingBalance > 0 ? tenant.outstandingBalance : tenant.monthlyRent,
          dueDate: 'Due',
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordPaymentModal(
        invoice: matchingInvoice,
        onPaymentRecorded: (amount, method, txRef) async {
          await widget.state.recordPayment(
            tenant.id,
            amount,
            method,
            matchingInvoice.id.isNotEmpty ? matchingInvoice.id : null,
            txRef,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final allTenants = widget.state.tenants;
        final filteredTenants = widget.state.filteredTenants;

        final totalCount = allTenants.length;
        final paidCount = allTenants.where((t) => t.outstandingBalance <= 0 || t.paymentStatus == TenantPaymentStatus.paid).length;
        final pendingCount = allTenants.where((t) => t.outstandingBalance > 0 && t.paymentStatus == TenantPaymentStatus.pending).length;
        final overdueCount = allTenants.where((t) => t.outstandingBalance > 0 && t.paymentStatus == TenantPaymentStatus.overdue).length;
        final unpaidCount = allTenants.where((t) => t.outstandingBalance > 0).length;

        final filters = [
          'All ($totalCount)',
          'Overdue ($overdueCount)',
          'Pending ($pendingCount)',
          'Paid ($paidCount)',
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
                  'Tenants',
                  style: AppTypography.heading2.copyWith(color: context.textPrimaryColor),
                ),
                Text(
                  '$totalCount Residents • $unpaidCount Pending Rent',
                  style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.teal, size: 20),
                tooltip: 'Send Payment Reminder Blast',
                onPressed: () => _openWhatsAppBlast(unpaidCount),
              ),
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryAccent, size: 22),
                tooltip: 'Add Tenant',
                onPressed: _openAddTenant,
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
                // Search bar
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search tenant by name, room or phone...',
                  onChanged: (val) => widget.state.setTenantSearchQuery(val),
                ),
                const SizedBox(height: 12),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((opt) {
                      final key = opt.split(' ').first;
                      final isSelected = widget.state.tenantFilter == key;

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
                          onSelected: (_) => widget.state.setTenantFilter(key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Tenants List
                if (filteredTenants.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.people_outline_rounded, size: 48, color: context.textMutedColor),
                        const SizedBox(height: 12),
                        Text(
                          'No tenants found',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try clearing search filters or admit a new tenant.',
                          style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openAddTenant,
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                          label: const Text('Add Tenant'),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredTenants.map(
                    (tenant) => TenantCard(
                      tenant: tenant,
                      onCollect: () => _openRecordPayment(tenant),
                      onCheckout: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await widget.state.checkoutTenant(tenant.id);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('${tenant.fullName} checked out successfully.'),
                            backgroundColor: const Color(0xFF0D9488),
                          ),
                        );
                      },
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
