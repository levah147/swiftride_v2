import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/rides_screen.dart';
// Import your destination selection screen when you have it
// import 'screens/destination_selection_screen.dart';

void main() {
  runApp(const SwiftRideApp());
}

class SwiftRideApp extends StatelessWidget {
  const SwiftRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwiftRide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2f5f76),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      
      // Define named routes
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/rides': (context) => const RidesScreen(),
        // Add this when you create the screen
        // '/destination-selection': (context) => const DestinationSelectionScreen(),
      },
      
      // Handle routes with arguments
      onGenerateRoute: (settings) {
        // Handle destination selection with arguments
        if (settings.name == '/destination-selection') {
          final args = settings.arguments as Map<String, dynamic>?;
          
          // For now, return a placeholder screen until you create the actual one
          return MaterialPageRoute(
            builder: (context) => DestinationSelectionPlaceholder(
              pickup: args?['pickup'] as String?,
              destination: args?['destination'] as String?,
              pickupLat: args?['pickupLat'] as double?,
              pickupLng: args?['pickupLng'] as double?,
              destinationLat: args?['destinationLat'] as double?,
              destinationLng: args?['destinationLng'] as double?,
            ),
          );
          
          // When you have the actual screen, replace above with:
          /*
          return MaterialPageRoute(
            builder: (context) => DestinationSelectionScreen(
              initialPickup: args?['pickup'] as String?,
              initialDestination: args?['destination'] as String?,
              pickupLat: args?['pickupLat'] as double?,
              pickupLng: args?['pickupLng'] as double?,
              destinationLat: args?['destinationLat'] as double?,
              destinationLng: args?['destinationLng'] as double?,
            ),
          );
          */
        }
        
        return null;
      },
      
      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: const Text('Error', style: TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Route not found: ${settings.name}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                      '/splash',
                      (route) => false,
                    ),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Temporary placeholder screen - Replace this with your actual DestinationSelectionScreen
class DestinationSelectionPlaceholder extends StatelessWidget {
  final String? pickup;
  final String? destination;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;

  const DestinationSelectionPlaceholder({
    super.key,
    this.pickup,
    this.destination,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Destination',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Color(0xFF2f5f76), size: 64),
              const SizedBox(height: 24),
              const Text(
                'Destination Selection Screen',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (pickup != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, color: Color(0xFF2f5f76), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup Location',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pickup!,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (destination != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF2f5f76), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Destination',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              destination!,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                'This is a placeholder screen.\nCreate your actual DestinationSelectionScreen.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}