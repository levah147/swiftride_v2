// import 'package:bolte/History/RidesScreen.dart';
// import 'package:bolte/Ride/HomeMapScreen.dart';
// import 'package:bolte/account/accout_pages.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class BottomNavBar extends StatefulWidget {
//   const BottomNavBar({super.key});

//   @override
//   State<BottomNavBar> createState() => _BottomNavBarState();
// }

// class _BottomNavBarState extends State<BottomNavBar>
//     with TickerProviderStateMixin {
//   int _currentIndex = 0;
//   late PageController _pageController;
//   late List<AnimationController> _animationControllers;
//   late List<Animation<double>> _scaleAnimations;

//   // Cache pages for better performance
//   late final List<Widget> _pages;

//   @override
//   void initState() {
//     super.initState();
    
//     // Initialize page controller for smooth transitions
//     _pageController = PageController();
    
//     // Initialize pages once
//     _pages = const [
//       HomeMapScreen(),
//       RidesScreen(),
//       AccountScreen(),
//     ];

//     // Initialize animation controllers for each tab
//     _animationControllers = List.generate(
//       3,
//       (index) => AnimationController(
//         duration: const Duration(milliseconds: 200),
//         vsync: this,
//       ),
//     );

//     // Initialize scale animations
//     _scaleAnimations = _animationControllers
//         .map((controller) => Tween<double>(
//               begin: 1.0,
//               end: 1.2,
//             ).animate(CurvedAnimation(
//               parent: controller,
//               curve: Curves.elasticOut,
//             )))
//         .toList();

//     // Start animation for initial selected tab
//     _animationControllers[0].forward();
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     for (var controller in _animationControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   void _onTap(int index) {
//     if (_currentIndex == index) return;

//     // Haptic feedback for better UX
//     HapticFeedback.lightImpact();

//     // Animate to new page
//     _pageController.animateToPage(
//       index,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOutCubic,
//     );

//     // Update animations
//     _animationControllers[_currentIndex].reverse();
//     _animationControllers[index].forward();

//     setState(() {
//       _currentIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: PageView(
//         controller: _pageController,
//         onPageChanged: (index) {
//           HapticFeedback.lightImpact();
//           _animationControllers[_currentIndex].reverse();
//           _animationControllers[index].forward();
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         children: _pages,
//       ),
//       bottomNavigationBar: Container(
//         height: 85, // Reduced height to prevent overflow
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: const BorderRadius.only(
//             topLeft: Radius.circular(24),
//             topRight: Radius.circular(24),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 20,
//               offset: const Offset(0, -5),
//               spreadRadius: 0,
//             ),
//             BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 40,
//               offset: const Offset(0, -10),
//               spreadRadius: 0,
//             ),
//           ],
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildEnhancedNavItem(
//                   icon: Icons.home_rounded,
//                   activeIcon: Icons.home,
//                   label: 'Home',
//                   index: 0,
//                 ),
//                 _buildEnhancedNavItem(
//                   icon: Icons.history_rounded,
//                   activeIcon: Icons.history,
//                   label: 'Rides',
//                   index: 1,
//                 ),
//                 _buildEnhancedNavItem(
//                   icon: Icons.person_outline_rounded,
//                   activeIcon: Icons.person,
//                   label: 'Account',
//                   index: 2,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEnhancedNavItem({
//     required IconData icon,
//     required IconData activeIcon,
//     required String label,
//     required int index,
//   }) {
//     final bool isSelected = _currentIndex == index;
//     final Color primaryColor = const Color(0xFF23AA49);
//     final Color inactiveColor = Colors.grey[600]!;

//     return Expanded(
//       child: GestureDetector(
//         onTap: () => _onTap(index),
//         behavior: HitTestBehavior.opaque,
//         child: AnimatedBuilder(
//           animation: _scaleAnimations[index],
//           builder: (context, child) {
//             return Transform.scale(
//               scale: isSelected ? _scaleAnimations[index].value : 1.0,
//               child: Container(
//                 height: 70, // Fixed height to prevent overflow
//                 padding: const EdgeInsets.symmetric(vertical: 6),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Icon with animated container
//                     AnimatedContainer(
//                       duration: const Duration(milliseconds: 200),
//                       curve: Curves.easeInOutCubic,
//                       padding: const EdgeInsets.all(6), // Reduced padding
//                       decoration: BoxDecoration(
//                         color: isSelected 
//                             ? primaryColor.withOpacity(0.1) 
//                             : Colors.transparent,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: AnimatedSwitcher(
//                         duration: const Duration(milliseconds: 200),
//                         transitionBuilder: (child, animation) {
//                           return ScaleTransition(
//                             scale: animation,
//                             child: child,
//                           );
//                         },
//                         child: Icon(
//                           isSelected ? activeIcon : icon,
//                           key: ValueKey(isSelected ? activeIcon : icon),
//                           color: isSelected ? primaryColor : inactiveColor,
//                           size: 22, // Slightly smaller icon
//                         ),
//                       ),
//                     ),
                    
//                     const SizedBox(height: 2), // Reduced spacing
                    
//                     // Label with animated color and weight
//                     Flexible(
//                       child: AnimatedDefaultTextStyle(
//                         duration: const Duration(milliseconds: 200),
//                         curve: Curves.easeInOutCubic,
//                         style: TextStyle(
//                           fontSize: 11, // Slightly smaller font
//                           color: isSelected ? primaryColor : inactiveColor,
//                           fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
//                           letterSpacing: isSelected ? 0.1 : 0,
//                         ),
//                         child: Text(
//                           label,
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 1,
//                         ),
//                       ),
//                     ),
                    
//                     // Active indicator dot
//                     AnimatedContainer(
//                       duration: const Duration(milliseconds: 200),
//                       curve: Curves.easeInOutCubic,
//                       margin: const EdgeInsets.only(top: 2),
//                       height: 3, // Smaller indicator
//                       width: isSelected ? 16 : 0,
//                       decoration: BoxDecoration(
//                         color: primaryColor,
//                         borderRadius: BorderRadius.circular(1.5),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// // Alternative version with floating action button style (uncomment to use)
// class FloatingBottomNavBar extends StatefulWidget {
//   const FloatingBottomNavBar({super.key});

//   @override
//   State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
// }

// class _FloatingBottomNavBarState extends State<FloatingBottomNavBar> {
//   int _currentIndex = 0;
//   late PageController _pageController;

//   final List<Widget> _pages = const [
//     HomeMapScreen(),
//     RidesScreen(), 
//     AccountScreen(),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController();
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
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
//         children: _pages,
//       ),
//       bottomNavigationBar: Container(
//         margin: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(30),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 20,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(30),
//           child: BottomNavigationBar(
//             currentIndex: _currentIndex,
//             onTap: (index) {
//               _pageController.animateToPage(
//                 index,
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.easeInOut,
//               );
//             },
//             type: BottomNavigationBarType.fixed,
//             backgroundColor: Colors.white,
//             selectedItemColor: const Color(0xFF23AA49),
//             unselectedItemColor: Colors.grey[600],
//             elevation: 0,
//             items: const [
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.home_outlined),
//                 activeIcon: Icon(Icons.home),
//                 label: 'Home',
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.history_outlined),
//                 activeIcon: Icon(Icons.history),
//                 label: 'Rides',
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.person_outline),
//                 activeIcon: Icon(Icons.person),
//                 label: 'Account',
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
