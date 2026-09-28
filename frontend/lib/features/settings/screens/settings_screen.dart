import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/property_switcher_modal.dart';
import '../../../state/app_state.dart';
import '../../landing/screens/landing_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onProfileTap;

  const SettingsScreen({
    super.key,
    required this.state,
    required this.onProfileTap,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _autoInvoice;
  late bool _appPushAlerts;
  late bool _whatsAppReminders;
  late bool _overdueEscalation;

  @override
  void initState() {
    super.initState();
    _autoInvoice = widget.state.warden.autoInvoiceCycle;
    _appPushAlerts = widget.state.warden.appPushAlerts;
    _whatsAppReminders = widget.state.warden.whatsAppReminders;
    _overdueEscalation = widget.state.warden.criticalOverdueEscalation;
  }

  void _openPropertySwitcher() {
    showPropertySwitcherModal(context, widget.state);
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('You will need your staff credentials to log back into the Warden Portal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.state.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LandingScreen(appState: widget.state)),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _forceResync() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Synchronizing local database with server...')),
    );
    await widget.state.loadAllData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync completed. All local records updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final warden = widget.state.warden;
        final currentProp = widget.state.currentProperty;
        final currentTheme = widget.state.themeMode;

        return Scaffold(
          backgroundColor: context.backgroundColor,
          appBar: AppBar(
            backgroundColor: context.surfaceColor,
            elevation: 0,
            titleSpacing: 16,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: AppTypography.heading2,
                ),
                Text(
                  'Warden Profile & Property Controls',
                  style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.logout_rounded, color: context.redFgColor, size: 22),
                tooltip: 'Log Out',
                onPressed: _handleLogout,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active Property Card
              const Text('Active Property', style: AppTypography.heading3),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: context.borderColor),
                  boxShadow: context.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: context.primaryTintColor,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentProp.name.isNotEmpty ? currentProp.name : 'HostelGhar PG',
                                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${currentProp.block} • ${currentProp.address}',
                                      style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _openPropertySwitcher,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: context.dividerColor),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPropStat(context, 'Rooms', '${currentProp.totalRooms}'),
                        _buildPropStat(context, 'Total Beds', '${currentProp.totalBeds}'),
                        _buildPropStat(context, 'Occupied', '${currentProp.occupiedBeds}'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Appearance / Theme Switcher
              const Text('Appearance', style: AppTypography.heading3),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: context.borderColor),
                  boxShadow: context.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.primaryTintColor,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Icon(
                            context.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: AppColors.primaryAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Theme',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              Text(
                                'Choose Light, Dark, or match your device setting',
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildThemeOption(
                          context,
                          label: 'Light',
                          icon: Icons.light_mode_rounded,
                          mode: ThemeMode.light,
                          currentMode: currentTheme,
                        ),
                        const SizedBox(width: 8),
                        _buildThemeOption(
                          context,
                          label: 'Dark',
                          icon: Icons.dark_mode_rounded,
                          mode: ThemeMode.dark,
                          currentMode: currentTheme,
                        ),
                        const SizedBox(width: 8),
                        _buildThemeOption(
                          context,
                          label: 'System',
                          icon: Icons.settings_brightness_rounded,
                          mode: ThemeMode.system,
                          currentMode: currentTheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Warden Profile Card
              const Text('Warden Profile', style: AppTypography.heading3),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: context.borderColor),
                  boxShadow: context.cardShadow,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: context.primaryTintColor,
                      child: Text(
                        warden.name.isNotEmpty ? warden.name[0].toUpperCase() : 'W',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            warden.name,
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${warden.role} • ${warden.staffId}',
                            style: AppTypography.caption.copyWith(color: AppColors.primaryAccent, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${warden.phone} • ${warden.email}',
                            style: AppTypography.caption.copyWith(color: context.textMutedColor, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Automation Rules
              const Text('Operations & Notification Rules', style: AppTypography.heading3),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: context.borderColor),
                  boxShadow: context.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildToggleRow(
                      context,
                      'Auto-Bill Monthly Rent',
                      'Automatically generate rent invoices on 1st of month',
                      _autoInvoice,
                      (val) {
                        setState(() => _autoInvoice = val);
                        widget.state.updateWardenSettings(autoInvoiceCycle: val);
                      },
                    ),
                    Divider(height: 1, indent: 14, color: context.dividerColor),
                    _buildToggleRow(
                      context,
                      'Push Alerts',
                      'Receive instant notices for maintenance and checkout requests',
                      _appPushAlerts,
                      (val) {
                        setState(() => _appPushAlerts = val);
                        widget.state.updateWardenSettings(appPushAlerts: val);
                      },
                    ),
                    Divider(height: 1, indent: 14, color: context.dividerColor),
                    _buildToggleRow(
                      context,
                      'WhatsApp Reminders',
                      'Enable one-tap Nepali WhatsApp billing messages',
                      _whatsAppReminders,
                      (val) {
                        setState(() => _whatsAppReminders = val);
                        widget.state.updateWardenSettings(whatsAppReminders: val);
                      },
                    ),
                    Divider(height: 1, indent: 14, color: context.dividerColor),
                    _buildToggleRow(
                      context,
                      'Overdue Rent Escalation',
                      'Highlight overdue balances older than 5 days in red',
                      _overdueEscalation,
                      (val) {
                        setState(() => _overdueEscalation = val);
                        widget.state.updateWardenSettings(criticalOverdueEscalation: val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Data & Storage
              const Text('Offline Database & Storage', style: AppTypography.heading3),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: context.borderColor),
                  boxShadow: context.cardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hive Storage Engine',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        Text(currentProp.databaseSyncStatus, style: AppTypography.caption.copyWith(color: context.tealFgColor)),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: _forceResync,
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: const Text('Resync', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Log Out Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: _handleLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.redFgColor,
                    side: BorderSide(color: context.redFgColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: context.redFgColor),
                      const SizedBox(width: 8),
                      const Text('Log Out of Warden Account', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  'HostelGhar v2.4.0 • Nepal Operations',
                  style: AppTypography.caption.copyWith(color: context.textMutedColor),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
  }) {
    final isSelected = currentMode == mode;
    final activeBg = context.isDarkMode ? AppColors.primaryAccent : AppColors.primary;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: () => widget.state.setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : context.elevatedSurfaceColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isSelected ? activeBg : context.borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : context.textSecondaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : context.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: AppTypography.caption.copyWith(fontSize: 11, color: context.textSecondaryColor)),
      ],
    );
  }

  Widget _buildToggleRow(BuildContext context, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: context.primaryTintColor,
            activeThumbColor: AppColors.primaryAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
