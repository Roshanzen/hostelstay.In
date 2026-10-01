import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../state/app_state.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../rooms/screens/rooms_screen.dart';
import '../../tenants/screens/tenants_screen.dart';
import '../../billing/screens/billing_screen.dart';
import '../../maintenance/screens/maintenance_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../authentication/screens/login_screen.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  final AppState appState;

  const MainScaffold({super.key, this.initialIndex = 0, required this.appState});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    widget.appState.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) {
      if (!widget.appState.isLoggedIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen(appState: widget.appState)),
          (route) => false,
        );
        return;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        state: widget.appState,
        onProfileTap: () => setState(() => _currentIndex = 5),
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      RoomsScreen(
        state: widget.appState,
        onProfileTap: () => setState(() => _currentIndex = 5),
      ),
      TenantsScreen(
        state: widget.appState,
        onProfileTap: () => setState(() => _currentIndex = 5),
      ),
      BillingScreen(
        state: widget.appState,
        onProfileTap: () => setState(() => _currentIndex = 5),
      ),
      MaintenanceScreen(
        state: widget.appState,
        onProfileTap: () => setState(() => _currentIndex = 5),
      ),
      SettingsScreen(
        state: widget.appState,
        onProfileTap: () => setState(() => _currentIndex = 5),
      ),
    ];

    return ResponsiveLayout(
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border(top: BorderSide(color: context.borderColor)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
                  _buildNavItem(1, Icons.bed_outlined, Icons.bed_rounded, 'Rooms'),
                  _buildNavItem(2, Icons.people_outline_rounded, Icons.people_rounded, 'Tenants'),
                  _buildNavItem(3, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Billing'),
                  _buildNavItem(4, Icons.build_outlined, Icons.build_rounded, 'Maintenance'),
                  _buildNavItem(5, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final primaryColor = context.isDarkMode ? AppColors.primaryAccent : AppColors.primary;
    final unselectedColor = context.textSecondaryColor;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : outlineIcon,
              size: 22,
              color: isSelected ? primaryColor : unselectedColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.badge.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primaryColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
