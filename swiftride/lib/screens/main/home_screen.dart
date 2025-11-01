import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:swiftride/models/location.dart';
import '../../constants/colors.dart';
import '../../constants/app_dimensions.dart';
import '../../models/vehicle_type.dart';
import '../../services/location_service.dart';
import '../../services/ride_service.dart';
import '../rides_booking/ride_options_screen.dart';

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
  bool _isLoadingVehicles = true;
  bool _isLoadingRecent = true;
  String _currentCity = 'Makurdi';
  
  // Draggable bottom sheet
  late AnimationController _bottomSheetController;
  final DraggableScrollableController _scrollController = DraggableScrollableController();
  
  // Dynamic data from API
  List<VehicleType> _availableVehicles = [];
  List<Map<String, dynamic>> _recentLocations = [];
  VehicleType? _selectedVehicle;
  String? _homeAddress;
  String? _workAddress;

  // Services
  final LocationService _locationService = LocationService();
  final RideService _rideService = RideService();

  @override
  void initState() {
    super.initState();
    _initializeBottomSheet();
    _initializeScreen();
  }

  void _initializeBottomSheet() {
    _bottomSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bottomSheetController.forward();
  }

  Future<void> _initializeScreen() async {
    // Load everything in parallel
    await Future.wait([
      _getCurrentLocation(),
      _loadAvailableVehicles(),
      _loadRecentLocations(),
      _loadSavedPlaces(),
    ]);
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoadingLocation = true);

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Move camera
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );

      // Detect city (will use geocoding in production)
      await _detectCity(position);
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        _showError('Could not get location');
      }
    }
  }

  Future<void> _detectCity(Position position) async {
    // TODO: Use Geocoding API to get actual city name
    // For now, default to Makurdi
    setState(() {
      _currentCity = 'Makurdi';
    });
    
    // Reload vehicles for detected city
    await _loadAvailableVehicles();
  }

  Future<void> _loadAvailableVehicles() async {
    try {
      setState(() => _isLoadingVehicles = true);

      // TODO: Call your API
      // GET /api/vehicle-types?city=Makurdi&lat=X&lon=Y
      
      // Mock API call for now
      await Future.delayed(const Duration(milliseconds: 500));
      
      // In production, replace with:
      // final response = await ApiClient.instance.get(
      //   '/vehicle-types',
      //   queryParams: {
      //     'city': _currentCity,
      //     if (_currentPosition != null) ...{
      //       'lat': _currentPosition!.latitude.toString(),
      //       'lon': _currentPosition!.longitude.toString(),
      //     }
      //   },
      // );
      
      if (!mounted) return;

      // For testing, use static data based on city
      final vehicles = VehicleTypes.getVehiclesForCity(_currentCity);
      
      setState(() {
        _availableVehicles = vehicles.where((v) => v.available).toList();
        _isLoadingVehicles = false;
      });
    } catch (e) {
      debugPrint('Vehicles load error: $e');
      if (mounted) {
        setState(() {
          _availableVehicles = [];
          _isLoadingVehicles = false;
        });
      }
    }
  }

  Future<void> _loadRecentLocations() async {
    try {
      setState(() => _isLoadingRecent = true);

      // Call API to get recent locations
      final response = await _locationService.getRecentLocations();
      
      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        setState(() {
          _recentLocations = response.data!.map((location) {
            return {
              'id': location.id,
              'title': location.address.split(',').first,
              'subtitle': location.address,
              'latitude': location.latitude,
              'longitude': location.longitude,
            };
          }).toList();
          _isLoadingRecent = false;
        });
      } else {
        // No recent locations yet
        setState(() {
          _recentLocations = [];
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      debugPrint('Recent locations error: $e');
      if (mounted) {
        setState(() {
          _recentLocations = [];
          _isLoadingRecent = false;
        });
      }
    }
  }

  Future<void> _loadSavedPlaces() async {
    try {
      // TODO: Call API to get saved places
      // GET /api/locations/saved/
      
      final response = await _locationService.getSavedLocations();
      
      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        for (var place in response.data!) {
          if (place.type == 'home') {
            setState(() => _homeAddress = place.address);
          } else if (place.type == 'work') {
            setState(() => _workAddress = place.address);
          }
        }
      }
    } catch (e) {
      debugPrint('Saved places error: $e');
    }
  }

  void _bookRide(Map<String, dynamic> destination) {
    // Navigate directly to ride options with selected destination
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideOptionsScreen(
          from: 'Current Location',
          to: destination['title'] ?? destination['subtitle'],
          isScheduled: false,
          city: _currentCity,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
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
          // Google Map (takes 70% of screen)
          _buildMap(),
          
          // Top gradient overlay
          _buildTopGradient(),
          
          // Recenter button
          _buildRecenterButton(),
          
          // Draggable bottom sheet (starts at 30% of screen)
          _buildDraggableBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7, // 70% for map
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : const LatLng(7.7304, 8.5378), // Makurdi
          zoom: 15,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          // Dark map style
          _mapController?.setMapStyle('''
            [
              {
                "elementType": "geometry",
                "stylers": [{"color": "#1d2c4d"}]
              },
              {
                "elementType": "labels.text.fill",
                "stylers": [{"color": "#8ec3b9"}]
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
                  markerId: const MarkerId('current'),
                  position: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                ),
              }
            : {},
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 150,
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
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: GestureDetector(
              onTap: () {
                // TODO: Show city picker
              },
              child: Container(
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
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _currentCity,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return Positioned(
      right: AppDimensions.paddingLarge,
      bottom: MediaQuery.of(context).size.height * 0.35,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.my_location, color: AppColors.primary),
          onPressed: _getCurrentLocation,
        ),
      ),
    );
  }

  Widget _buildDraggableBottomSheet() {
    return DraggableScrollableSheet(
      controller: _scrollController,
      initialChildSize: 0.35, // Starts at 35% of screen
      minChildSize: 0.35,
      maxChildSize: 0.9, // Can expand to 90%
      builder: (context, scrollController) {
        return Container(
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
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
                child: _buildSearchBar(),
              ),
              
              const SizedBox(height: 20),
              
              // Vehicle selector (only if vehicles loaded and available)
              if (_isLoadingVehicles)
                const Center(child: CircularProgressIndicator())
              else if (_availableVehicles.isNotEmpty)
                _buildVehicleSelector(),
              
              const SizedBox(height: 20),
              
              // Quick actions (Home/Work)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
                child: _buildQuickActions(),
              ),
              
              const SizedBox(height: 20),
              
              // Recent locations (only if exists)
              if (_isLoadingRecent)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_recentLocations.isNotEmpty)
                _buildRecentLocations(),
              
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => widget.onNavigate('destination_selection'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
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
              child: const Icon(Icons.search, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Where are you going?',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
          child: Text(
            'Available Rides',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
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
                  setState(() => _selectedVehicle = vehicle);
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? vehicle.color.withOpacity(0.15) 
                        : AppColors.surface,
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
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.home_outlined,
            label: _homeAddress?.split(',').first ?? 'Add Home',
            onTap: () {
              if (_homeAddress != null) {
                // Book ride to home directly
                _bookRide({
                  'title': 'Home',
                  'subtitle': _homeAddress!,
                });
              } else {
                // Navigate to add home
                // TODO: Implement add home screen
                _showError('Please add your home address in settings');
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.work_outline,
            label: _workAddress?.split(',').first ?? 'Add Work',
            onTap: () {
              if (_workAddress != null) {
                // Book ride to work directly
                _bookRide({
                  'title': 'Work',
                  'subtitle': _workAddress!,
                });
              } else {
                // Navigate to add work
                _showError('Please add your work address in settings');
              }
            },
          ),
        ),
      ],
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
            Icon(icon, color: AppColors.textPrimary, size: 18),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Show all recent locations
                },
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
          itemCount: _recentLocations.length > 3 ? 3 : _recentLocations.length,
          itemBuilder: (context, index) {
            final location = _recentLocations[index];
            return _buildLocationItem(
              title: location['title'] ?? '',
              subtitle: location['subtitle'] ?? '',
              onTap: () => _bookRide(location),
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
      borderRadius: BorderRadius.circular(12),
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
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

extension on RecentLocation {
  get id => null;
} 