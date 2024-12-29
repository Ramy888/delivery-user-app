import 'package:animations/animations.dart';
import 'package:eb3at/Screens/my_orders.dart';
import 'package:eb3at/Screens/user_profile_page.dart';
import 'package:flutter/material.dart';
import '../Utils/shared_prefs.dart';
import 'home_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late String userEmail;
  late PageController _pageController;
  late AnimationController _animationController;

  // Define theme colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF64B5F6);

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Orders'),
    _NavItem(icon: Icons.person, label: 'Profile'),
    _NavItem(icon: Icons.info_rounded, label: 'About'),
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _initialize() async {
    userEmail = (await SharedPreferenceHelper().getUserEmail())!;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    HomePage(),
    MyOrdersPage(),
    UserProfilePage(),
    const AboutPage(),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: PageTransitionSwitcher(
                transitionBuilder: (child, animation, secondaryAnimation) {
                  return FadeThroughTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    child: child,
                  );
                },
                child: _pages[_currentIndex],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onPageChanged,
          items: _navItems.map((item) {
            return BottomNavigationBarItem(
              icon: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Icon(
                    item.icon,
                    size: _currentIndex == _navItems.indexOf(item) ? 28 : 24,
                  );
                },
              ),
              label: item.label,
            );
          }).toList(),
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _navItems[_currentIndex].label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const Spacer(),
          CircleAvatar(
            backgroundColor: accentColor.withOpacity(0.2),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              color: primaryColor,
              onPressed: () {},
            ),
          ),
          SizedBox(width: 5,),
          CircleAvatar(
            backgroundColor: accentColor.withOpacity(0.2),
            child: IconButton(
              icon: const Icon(Icons.person_rounded),
              color: primaryColor,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          // Add your settings content here
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          // Add your about content here
        ],
      ),
    );
  }
}
