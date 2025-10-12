// import 'package:flutter/material.dart';
// import '../constants/colors.dart';
// import 'home_screen.dart';
// import 'rides_screen.dart';
// import 'account_screen.dart';

// /// Main wrapper widget that handles persistent bottom navigation
// /// This ensures the navigation bar remains visible and functional across all screens
// class MainAppWrapper extends StatefulWidget {
//   const MainAppWrapper({super.key});

//   @override
//   State<MainAppWrapper> createState() => _MainAppWrapperState();
// }

// class _MainAppWrapperState extends State<MainAppWrapper> {
//   int _currentIndex = 0;
//   final PageController _pageController = PageController();

//   // List of screens corresponding to bottom navigation tabs
//   final List<Widget> _screens = [
//     const HomeScreen(),
//     const RidesScreen(), 
//     const AccountScreen(),
//   ];

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   void _onTabSelected(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
    
//     // Animate to the selected page
//     _pageController.animateToPage(
//       index,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: PageView(
//         controller: _pageController,
//         onPageChanged: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         children: _screens,
//       ),
      
//       // Persistent bottom navigation bar
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.black,
//           border: Border(
//             top: BorderSide(
//               color: Colors.grey[800]!,
//               width: 0.5,
//             ),
//           ),
//         ),
//         child: BottomNavigationBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           type: BottomNavigationBarType.fixed,
//           currentIndex: _currentIndex,
//           onTap: _onTabSelected,
//           selectedItemColor: Colors.white,
//           unselectedItemColor: Colors.grey[600],
//           selectedLabelStyle: const TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 12,
//           ),
//           unselectedLabelStyle: const TextStyle(
//             fontWeight: FontWeight.normal,
//             fontSize: 12,
//           ),
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(Icons.home),
//               label: 'Home',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.calendar_today),
//               label: 'Rides',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(Icons.person),
//               label: 'Account',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }