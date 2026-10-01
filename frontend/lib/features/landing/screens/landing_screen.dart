import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../authentication/screens/login_screen.dart';
import '../../../state/app_state.dart';

class LandingScreen extends StatefulWidget {
  final AppState? appState;

  const LandingScreen({super.key, this.appState});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  String _selectedLanguage = 'EN';
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = widget.appState ?? AppState();
  }

  @override
  void dispose() {
    // IMPORTANT: Do NOT call _appState.dispose() here!
    // LandingScreen passes _appState to LoginScreen and MainScaffold.
    // Disposing it here when routes are popped would dispose the active AppState!
    super.dispose();
  }

  void _navigateToLogin() async {
    await _appState.completeOnboarding();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(appState: _appState)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNepali = _selectedLanguage == 'NE';

    return ResponsiveLayout(
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.surfaceColor,
          elevation: 0,
          titleSpacing: 16,
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNepali ? 'हस्टेलघर' : 'HostelGhar',
                    style: AppTypography.heading3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    isNepali ? 'वार्डेन पोर्टल' : 'Warden Portal',
                    style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: context.elevatedSurfaceColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageButton(context, 'EN', 'EN'),
                  _buildLanguageButton(context, 'NE', 'नेपाली'),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: context.borderColor),
                    boxShadow: context.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.tealTintColor,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          isNepali ? 'नेपालको पहिलो डिजिटल वार्डेन प्रणाली' : 'NEPAL-FIRST WARDEN PLATFORM',
                          style: AppTypography.badge.copyWith(
                            color: context.tealFgColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isNepali
                            ? 'सजिलो, भरपर्दो र पूर्ण डिजिटल हस्टेल व्यवस्थापन'
                            : 'Hostel & PG Operations\nManaged with Simplicity',
                        style: AppTypography.heading1.copyWith(
                          color: context.textPrimaryColor,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isNepali
                            ? 'कोठा, ओछ्यान, भाडा, बिल, नागरिकता प्रमाणीकरण र गुनासो व्यवस्थापन एकै ठाउँबाट गर्नुहोस्।'
                            : 'Real-time room occupancy, tenant citizenship verification, eSewa/Khalti billing, and offline sync in one unified system.',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.textSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  isNepali ? 'मुख्य सुविधाहरू' : 'Key Operations',
                  style: AppTypography.heading2,
                ),
                const SizedBox(height: 12),

                // Feature grid / cards
                _buildFeatureTile(
                  context,
                  icon: Icons.meeting_room_rounded,
                  iconColor: AppColors.primaryAccent,
                  iconBg: context.primaryTintColor,
                  title: isNepali ? 'कोठा तथा ओछ्यान व्यवस्थापन' : 'Beds & Occupancy Tracking',
                  description: isNepali
                      ? 'प्रत्येक कोठा र ओछ्यानको तत्काल खाली/भरिएको स्थिति।'
                      : 'Live visual slots for single, 2-sharing, 3-sharing, and 4-sharing units.',
                ),
                const SizedBox(height: 10),
                _buildFeatureTile(
                  context,
                  icon: Icons.payments_rounded,
                  iconColor: context.tealFgColor,
                  iconBg: context.tealTintColor,
                  title: isNepali ? 'नेपाली बिलिङ तथा भाडा खाता' : 'Nepali Rent & Utility Invoicing',
                  description: isNepali
                      ? 'रकम रु. मा हिसाब, बिल जारी, eSewa/Khalti/Cash भुक्तानी रेकर्ड।'
                      : 'NPR invoicing, overdue alerts, security deposits, and multi-channel reconciliation.',
                ),
                const SizedBox(height: 10),
                _buildFeatureTile(
                  context,
                  icon: Icons.badge_rounded,
                  iconColor: context.indigoFgColor,
                  iconBg: context.indigoTintColor,
                  title: isNepali ? 'नागरिकता तथा विद्यार्थी विवरण' : 'Citizenship & Tenant Records',
                  description: isNepali
                      ? 'नागरिकता नं., अभिभावक सम्पर्क, आपतकालीन नम्बर पूर्ण सुरक्षित।'
                      : 'National ID/Citizenship verification, emergency contacts, and check-in logs.',
                ),
                const SizedBox(height: 10),
                _buildFeatureTile(
                  context,
                  icon: Icons.sync_rounded,
                  iconColor: context.orangeFgColor,
                  iconBg: context.orangeTintColor,
                  title: isNepali ? 'अफलाइन काम गर्ने प्रविधि' : 'Offline-First Reliability',
                  description: isNepali
                      ? 'इन्टरनेट नभए पनि निर्धक्क काम गर्नुहोस्, नेट आउँदा आफैँ सिंक हुन्छ।'
                      : 'Data saves locally instantly and synchronizes smoothly with your database.',
                ),

                const SizedBox(height: 32),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _navigateToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          isNepali ? 'वार्डेन लगइन गर्नुहोस्' : 'Sign in as Warden',
                          style: AppTypography.button,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),
                Center(
                  child: Text(
                    'HostelGhar v2.4.0 • Nepal Operations Standard',
                    style: AppTypography.caption.copyWith(color: context.textMutedColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, String code, String label) {
    final isSelected = _selectedLanguage == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? context.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 2),
          boxShadow: isSelected ? context.cardShadow : null,
        ),
        child: Text(
          label,
          style: AppTypography.badge.copyWith(
            color: isSelected ? context.textPrimaryColor : context.textSecondaryColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(color: context.textSecondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
