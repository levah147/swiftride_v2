// ==================== Updated account_screen.dart ====================
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_dimensions.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../widgets/common/menu_item_widget.dart';
import '../../widgets/common/menu_section_widget.dart';
import '../../widgets/dialogs/logout_dialog.dart';
import '../../widgets/dialogs/delete_account_dialog.dart';

class AccountScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? data}) onNavigate;
 
  const AccountScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  String _selectedLanguage = 'English - GB';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _authService.getCurrentUser();
      setState(() {
        _user = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.failedToLoadProfile}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => LogoutDialog(
        onConfirm: () async {
          await _authService.logout();
          if (mounted) widget.onNavigate('logout');
        },
      ),
    );
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (_) => DeleteAccountDialog(
        onConfirm: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deletion requested'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          AppStrings.account,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _buildMainView(),
    );
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileSection(),
          const SizedBox(height: 20),
          _buildMainMenu(),
          const SizedBox(height: 20),
          _buildSavedPlacesSection(),
          const SizedBox(height: 20),
          _buildRideMenu(),
          const SizedBox(height: 20),
          _buildPreferencesSection(),
          const SizedBox(height: 20),
          _buildBecomeDriverCTA(),
          const SizedBox(height: 30),
          _buildLogoutSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ---------- MAIN VIEW SECTIONS ----------

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            _user?.fullName ?? 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: AppColors.primary, size: 20),
              const SizedBox(width: 4),
              Text(
                '${_user?.rating.toStringAsFixed(2) ?? '0.0'} Rating',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenu() {
    return MenuSectionWidget(items: [
      const MenuItemWidget(icon: Icons.person_outline, title: AppStrings.personalInfo),
      const MenuItemWidget(icon: Icons.family_restroom, title: AppStrings.familyProfile),
      const MenuItemWidget(icon: Icons.security, title: AppStrings.safety),
      const MenuItemWidget(
        icon: Icons.lock_outline,
        title: AppStrings.loginAndSecurity,
      ),
      const MenuItemWidget(
        icon: Icons.privacy_tip_outlined,
        title: AppStrings.privacy,
      ),
    ]);
  }

  Widget _buildSavedPlacesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.savedPlaces,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          MenuSectionWidget(items: [
            const MenuItemWidget(
              icon: Icons.home_outlined,
              title: AppStrings.enterHomeLocation,
            ),
            const MenuItemWidget(
              icon: Icons.work_outline,
              title: AppStrings.enterWorkLocation,
            ),
            const MenuItemWidget(
              icon: Icons.add,
              title: 'Add a place',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildRideMenu() {
    return const MenuSectionWidget(items: [
      MenuItemWidget(icon: Icons.payment, title: AppStrings.payment),
      MenuItemWidget(icon: Icons.local_offer_outlined, title: AppStrings.promotions),
      MenuItemWidget(icon: Icons.history, title: AppStrings.myRides),
      MenuItemWidget(icon: Icons.receipt_long, title: AppStrings.expenseYourRides),
      MenuItemWidget(icon: Icons.support_agent, title: AppStrings.support),
      MenuItemWidget(icon: Icons.info_outline, title: AppStrings.about),
    ]);
  }

  Widget _buildPreferencesSection() {
    return MenuSectionWidget(items: [
      MenuItemWidget(
        icon: Icons.language,
        title: AppStrings.language,
        subtitle: _selectedLanguage,
      ),
      const MenuItemWidget(
        icon: Icons.notifications_outlined,
        title: AppStrings.communicationPreferences,
      ),
      const MenuItemWidget(icon: Icons.calendar_today, title: AppStrings.calendars),
    ]);
  }

  Widget _buildBecomeDriverCTA() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.becomeADriver,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppStrings.earnMoneyOnSchedule,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return MenuSectionWidget(items: [
      MenuItemWidget(
        icon: Icons.logout,
        title: AppStrings.logout,
        onTap: _handleLogout,
      ),
      MenuItemWidget(
        icon: Icons.delete_outline,
        title: AppStrings.deleteAccount,
        isDestructive: true,
        onTap: _handleDeleteAccount,
      ),
    ]);
  }
}