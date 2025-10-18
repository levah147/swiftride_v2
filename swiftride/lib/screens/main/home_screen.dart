import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/colors.dart';
import '../../constants/app_dimensions.dart';
import '../../models/vehicle_type.dart';

class HomeScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? data}) onNavigate;

  const HomeScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String _currentCity = 'Makurdi'; // Default to Makurdi
  late AnimationController _bottomSheetController;
  late Animation<double> _bottomSheetAnimation;
  
  // Available vehicles based on location
  List<VehicleType> _availableVehicles = [];
  VehicleType? _selectedVehicle;

  // Recent locations (will come from API)
  final List<Map<String, String>> _recentLocations = [
    {
      'title': 'Keton Apartments',
      'subtitle': '677 Galadimawa - Lokogoma Road',
    },
    {
      'title': 'Wurukum Market',
      'subtitle': 'Makurdi, Benue State',
    },
    {
      'title': 'Modern Market',
      'subtitle': 'High Level, Makurdi',
    },
  ];

  // Saved places
  String? _homeAddress;
  String? _workAddress;

  @override
  void initState() {
    super.initState();
    _initializeBottomSheet();
    _getCurrentLocation();
    _loadAvailableVehicles();
  }

  void _initializeBottomSheet() {
    _bottomSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bottomSheetAnimation = CurvedAnimation(
      parent: _bottomSheetController,
      curve: Curves.easeOut,
    );
    _bottomSheetController.forward();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );

      // Detect city (mock for now - will use Geocoding in production)
      _detectCity(position);
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  void _detectCity(Position position) {
    // TODO: Use Geocoding to get actual city
    // For now, default to Makurdi
    // In production: Use geocoding package to reverse geocode
    setState(() {
      _currentCity = 'Makurdi';
    });
  }

  void _loadAvailableVehicles() {
    // TODO: Fetch from API based on location
    // GET /api/vehicle-types?city=Makurdi
    
    // Mock data for Makurdi (all vehicles available)
    setState(() {
      _availableVehicles = [
        VehicleType(
          id: 'bike',
          name: 'Bike',
          description: 'Fast & affordable',
          icon: Icons.two_wheeler,
          color: const Color(0xFFFF6B35),
          basePrice: 200,
          pricePerKm: 50,
          estimatedTime: '5 min',
        ),
        VehicleType(
          id: 'keke',
          name: 'Keke',
          description: 'Comfortable tricycle',
          icon: Icons.electric_rickshaw,
          color: const Color(0xFFFFC107),
          basePrice: 300,
          pricePerKm: 70,
          estimatedTime: '7 min',
        ),
        VehicleType(
          id: 'car',
          name: 'Car',
          description: 'Private comfortable ride',
          icon: Icons.directions_car,
          color: AppColors.primary,
          basePrice: 500,
          pricePerKm: 100,
          estimatedTime: '8 min',
        ),
        VehicleType(
          id: 'suv',
          name: 'SUV',
          description: 'Premium spacious ride',
          icon: Icons.airport_shuttle,
          color: AppColors.secondary,
          basePrice: 800,
          pricePerKm: 150,
          estimatedTime: '10 min',
        ),
      ];
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _bottomSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          _buildMap(),
          
          // Top gradient overlay
          _buildTopGradient(),
          
          // Recenter button
          _buildRecenterButton(),
          
          // Bottom sheet
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(7.7304, 8.5378), // Makurdi coordinates
        zoom: 15,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        // Apply dark theme to map
        _mapController?.setMapStyle('''
          [
            {
              "elementType": "geometry",
              "stylers": [{"color": "#1d2c4d"}]
            },
            {
              "elementType": "labels.text.fill",
              "stylers": [{"color": "#8ec3b9"}]
            },
            {
              "elementType": "labels.text.stroke",
              "stylers": [{"color": "#1a3646"}]
            }
          ]
        ''');
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      markers: _currentPosition != null
          ? {
              Marker(
                markerId: const MarkerId('current_location'),
                position: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
              ),
            }
          : {},
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundPrimary.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
              vertical: AppDimensions.paddingMedium,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentCity,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return Positioned(
      right: AppDimensions.paddingLarge,
      bottom: MediaQuery.of(context).size.height * 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.my_location,
            color: AppColors.primary,
          ),
          onPressed: _getCurrentLocation,
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_bottomSheetAnimation),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Search bar
              _buildSearchBar(),
              
              const SizedBox(height: 24),
              
              // Vehicle selector
              _buildVehicleSelector(),
              
              const SizedBox(height: 24),
              
              // Quick actions
              _buildQuickActions(),
              
              const SizedBox(height: 24),
              
              // Recent locations
              _buildRecentLocations(),
              
              const SizedBox(height: 100),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Where are you going?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Now',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildVehicleSelector() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
        itemCount: _availableVehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _availableVehicles[index];
          final isSelected = _selectedVehicle?.id == vehicle.id;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedVehicle = vehicle;
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? vehicle.color.withOpacity(0.15) : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? vehicle.color : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    vehicle.icon,
                    color: isSelected ? vehicle.color : AppColors.textSecondary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vehicle.name,
                    style: TextStyle(
                      color: isSelected ? vehicle.color : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.home_outlined,
              label: _homeAddress ?? 'Add Home',
              onTap: () {
                // TODO: Navigate to add/edit home
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.work_outline,
              label: _workAddress ?? 'Add Work',
              onTap: () {
                // TODO: Navigate to add/edit work
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.textPrimary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLocations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
          child: Text(
            'Recent',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
          itemCount: _recentLocations.length,
          itemBuilder: (context, index) {
            final location = _recentLocations[index];
            return _buildLocationItem(
              title: location['title']!,
              subtitle: location['subtitle']!,
              onTap: () {
                // TODO: Navigate to destination with this location prefilled
                widget.onNavigate('destination_selection', data: location);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocationItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.history,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}