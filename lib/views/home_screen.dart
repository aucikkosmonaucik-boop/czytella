import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/czytella_provider.dart';
import 'listings_view.dart';
import 'my_shelf_view.dart';
import 'isbn_scanner_view.dart';
import 'chat_list_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget _buildActiveView() {
    switch (_currentIndex) {
      case 0:
        return const ListingsView();
      case 1:
        return const MyShelfView();
      case 2:
        return const IsbnScannerView();
      case 3:
        return const ChatListView();
      default:
        return const ListingsView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CzytellaProvider>();
    final unreadChats = provider.totalUnreadChats;

    return Scaffold(
      body: _buildActiveView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Ogłoszenia',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Moja Półka',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_scanner_outlined),
            label: 'Skaner ISBN',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadChats > 0,
              label: Text('$unreadChats'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadChats > 0,
              label: Text('$unreadChats'),
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Czat',
          ),
        ],
      ),
    );
  }
}
