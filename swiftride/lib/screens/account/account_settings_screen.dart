// // ==================== screens/account/account_settings_screen.dart ====================
// import 'package:flutter/material.dart';
// import '../../constants/app_strings.dart';
// import '../../constants/app_dimensions.dart';
// import '../../services/auth_service.dart';
// import '../../widgets/common/menu_item_widget.dart';
// import '../../widgets/common/menu_section_widget.dart';
// import '../../widgets/dialogs/logout_dialog.dart';
// import '../../widgets/dialogs/delete_account_dialog.dart';

// class AccountSettingsScreen extends StatefulWidget {
//   const AccountSettingsScreen({super.key});

//   @override
//   State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
// }

// // DEPRECATED: This screen is redundant with `AccountScreen` integrated settings.
// // Keeping temporarily to avoid build failures if any old imports remain.
// // If needed, navigate to `AppRoutes.account` instead and toggle the settings view there.
// class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
//   final AuthService _authService = AuthService();
//   String _selectedLanguage = 'English - GB';

//   Future<void> _handleLogout() async {
//     showDialog(
//       context: context,
//       builder: (context) => LogoutDialog(
//         onConfirm: () async {
//           await _authService.logout();
//           if (mounted) {
//             Navigator.pushNamedAndRemoveUntil(
//               context,
//               '/auth',
//               (route) => false,
//             );
//           }
//         },
//       ),
//     );
//   }

//   Future<void> _handleDeleteAccount() async {
//     showDialog(
//       context: context,
//       builder: (context) => DeleteAccountDialog(
//         onConfirm: () {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Account deletion requested'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Redirect users of this deprecated screen back to the Account tab.
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         Navigator.of(context).pushReplacementNamed(AppRoutes.account);
//       }
//     });

//     return const SizedBox.shrink();
//   }
// }
