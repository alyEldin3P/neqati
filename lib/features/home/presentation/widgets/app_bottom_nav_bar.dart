import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../../core/presentation/widgets/app_text.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isAdmin;

  const AppBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.deepTeal,
        unselectedItemColor: AppColors.lightText,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        items: isAdmin
            ? _adminNavItems()
            : _userNavItems(),
      ),
    );
  }

  List<BottomNavigationBarItem> _userNavItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'الرئيسية',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.qr_code_scanner),
        label: 'مسح',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.card_giftcard),
        label: 'الهدايا',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'الملف الشخصي',
      ),
    ];
  }

  List<BottomNavigationBarItem> _adminNavItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'لوحة التحكم',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people),
        label: 'المستخدمين',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.qr_code),
        label: 'الرموز',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'الإعدادات',
      ),
    ];
  }
}
