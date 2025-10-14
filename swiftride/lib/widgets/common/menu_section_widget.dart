
// ==================== widgets/common/menu_section_widget.dart ====================
import 'package:flutter/material.dart';

class MenuSectionWidget extends StatelessWidget {
  final List<Widget> items;

  const MenuSectionWidget({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
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
}
