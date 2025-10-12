import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Security Section
            _buildMenuSection([
              _buildMenuItem(Icons.security, 'Login & security'),
              _buildMenuItem(Icons.privacy_tip_outlined, 'Privacy'),
            ]),
            
            const SizedBox(height: 30),
            
            // Saved Places Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saved places',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuSection([
                    _buildMenuItem(Icons.home_outlined, 'Enter home location'),
                    _buildMenuItem(Icons.work_outline, 'Enter work location'),
                    _buildMenuItem(Icons.add, 'Add a place'),
                  ]),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // App Settings Section
            _buildMenuSection([
              _buildMenuItem(Icons.language, 'Language', subtitle: 'English - GB'),
              _buildMenuItem(Icons.notifications_outlined, 'Communication preferences'),
              _buildMenuItem(Icons.calendar_today, 'Calendars'),
            ]),
            
            const SizedBox(height: 50),
            
            // Account Actions Section
            _buildMenuSection([
              _buildMenuItem(Icons.logout, 'Log out', isDestructive: false),
              _buildMenuItem(Icons.delete_outline, 'Delete account', isDestructive: true),
            ]),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    String? subtitle,
    bool isDestructive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? Colors.red : Colors.white,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDestructive ? Colors.red : Colors.white,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[600],
            size: 16,
          ),
        ],
      ),
    );
  }
}
