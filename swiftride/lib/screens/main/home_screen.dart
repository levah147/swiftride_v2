// ==================== home_screen.dart ====================
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_dimensions.dart';
import '../../widgets/common/location_item_widget.dart';

class HomeScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? data}) onNavigate;

  const HomeScreen({
    super.key,
    required this.onNavigate,
  }); 

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showPromoBanner = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(),
          if (_showPromoBanner)
            Positioned(
              top: 60,
              left: AppDimensions.paddingLarge,
              right: AppDimensions.paddingLarge,
              child: _buildPromoBanner(),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a3a4a),
            Color(0xFF2f5f76),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.map,
          size: 100,
          color: Colors.white24,
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.local_offer,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '20% off 5 rides',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'View details',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showPromoBanner = false),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusLarge),
          topRight: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppDimensions.spacingSmall),
          _buildHandle(),
          const SizedBox(height: AppDimensions.paddingXLarge),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
            child: Text(
              AppStrings.nextStopAnywhere,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXLarge),
          _buildServiceRow(),
          const SizedBox(height: AppDimensions.paddingXLarge),
          _buildSearchBar(),
          const SizedBox(height: AppDimensions.paddingLarge),
          _buildQuickActions(),
          const SizedBox(height: AppDimensions.paddingXLarge),
          _buildRecentLocations(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: AppDimensions.bottomSheetHandleWidth,
      height: AppDimensions.bottomSheetHandleHeight,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildServiceRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: Row(
        children: [
          _buildServiceCard(
            icon: Icons.directions_car,
            title: AppStrings.rides,
            subtitle: AppStrings.letsGetMoving,
            onTap: () => widget.onNavigate('destination_selection'),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          _buildServiceCard(
            icon: Icons.schedule,
            title: AppStrings.schedule,
            subtitle: AppStrings.bookAhead,
            onTap: () => widget.onNavigate('schedule_ride'),
          ),
          const SizedBox(width: AppDimensions.paddingMedium),
          _buildServiceCard(
            icon: Icons.local_shipping,
            title: AppStrings.swiftSend,
            subtitle: AppStrings.packageDelivery,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: GestureDetector(
        onTap: () => widget.onNavigate('destination_selection'),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white, size: AppDimensions.iconLarge),
              const SizedBox(width: AppDimensions.paddingMedium),
              const Expanded(
                child: Text(
                  AppStrings.whereToQuestion,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, color: Colors.white, size: AppDimensions.iconSmall),
                    SizedBox(width: AppDimensions.paddingSmall),
                    Text(
                      'Later',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: Row(
        children: [
          _buildQuickAction(Icons.home, AppStrings.addHome),
          const SizedBox(width: AppDimensions.paddingMedium),
          _buildQuickAction(Icons.work, AppStrings.addWork),
          const SizedBox(width: AppDimensions.paddingMedium),
          _buildQuickAction(Icons.more_horiz, AppStrings.more),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: AppDimensions.iconSmall),
            const SizedBox(width: AppDimensions.paddingSmall),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLocations() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: Column(
        children: const [
          LocationItemWidget(
            icon: Icons.access_time,
            title: 'Keton Apartments',
            subtitle: '677 Galadimawa - Lokogoma Road, Abuja',
          ),
          LocationItemWidget(
            icon: Icons.access_time,
            title: 'Abuja 900107',
            subtitle: 'Nigeria',
          ),
          LocationItemWidget(
            icon: Icons.access_time,
            title: 'Benue Links',
            subtitle: 'Abuja, Nigeria',
          ),
        ],
      ),
    );
  }
}