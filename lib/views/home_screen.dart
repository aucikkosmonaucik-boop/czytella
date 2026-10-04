import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/czytella_provider.dart';
import '../models/listing.dart';
import '../services/api_service.dart';
import 'listing_detail_screen.dart';
import 'listings_view.dart';
import 'my_shelf_view.dart';
import 'isbn_scanner_view.dart';
import 'chat_list_view.dart';
import 'create_listing_dialog.dart';
import '../widgets/apk_download_dialog.dart';
import 'auth_dialog.dart';
import 'user_profile_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _deepLinkHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialDeepLink();
    });
  }

  Future<void> _handleInitialDeepLink() async {
    if (_deepLinkHandled) return;
    try {
      final uri = Uri.base;
      String? listingId = uri.queryParameters['listing'] ?? uri.queryParameters['id'];

      if (listingId == null || listingId.isEmpty) {
        final segments = uri.pathSegments;
        if (segments.length >= 2 &&
            (segments[0] == 'ogloszenie' ||
             segments[0] == 'listing' ||
             segments[0] == 'ksiazka')) {
          listingId = segments[1];
        }
      }

      if (listingId == null || listingId.trim().isEmpty) return;
      _deepLinkHandled = true;

      final provider = context.read<CzytellaProvider>();

      if (!provider.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 400));
      }

      Listing? targetListing;
      try {
        targetListing = provider.allListings.firstWhere(
          (l) => l.id == listingId,
        );
      } catch (_) {
        targetListing = await ApiService.fetchListingById(listingId);
      }

      if (targetListing != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ListingDetailScreen(listing: targetListing!),
          ),
        );
      }
    } catch (e) {
      debugPrint('Deep link error: $e');
    }
  }

  Widget _buildActiveView() {
    switch (_currentIndex) {
      case 0:
        return ListingsView(
          onNavigate: (index) => setState(() => _currentIndex = index),
        );
      case 1:
        return const MyShelfView();
      case 2:
        return const IsbnScannerView();
      case 3:
        return const ChatListView();
      default:
        return ListingsView(
          onNavigate: (index) => setState(() => _currentIndex = index),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final provider = context.watch<CzytellaProvider>();
    final unreadChats = provider.totalUnreadChats;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: isDesktop
          ? PreferredSize(
              preferredSize: const Size.fromHeight(66),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor, width: 1.5),
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1300),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            // Logo & Branding
                            InkWell(
                              onTap: () => setState(() => _currentIndex = 0),
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/logo.png',
                                    width: 28,
                                    height: 28,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.menu_book_rounded,
                                      size: 26,
                                      color: isDark
                                          ? const Color(0xFF86E875)
                                          : const Color(0xFF1E5128),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Czytella',
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? const Color(0xFF86E875)
                                              : const Color(0xFF1E5128),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      if (screenWidth >= 1200)
                                        Text(
                                          'Wymiana i sprzedaż książek',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Right-aligned Navigation & Action controls
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Desktop Navigation Pills
                                    _buildDesktopNavButton(
                                      index: 0,
                                      icon: Icons.explore_outlined,
                                      activeIcon: Icons.explore,
                                      label: 'Ogłoszenia',
                                      count: provider.allListings.length,
                                    ),
                                    const SizedBox(width: 4),
                                    _buildDesktopNavButton(
                                      index: 1,
                                      icon: Icons.auto_stories_outlined,
                                      activeIcon: Icons.auto_stories,
                                      label: 'Moja Półka',
                                      count: provider.userBooks.length,
                                    ),
                                    const SizedBox(width: 4),
                                    _buildDesktopNavButton(
                                      index: 2,
                                      icon: Icons.qr_code_scanner,
                                      activeIcon: Icons.qr_code_scanner,
                                      label: 'Skaner ISBN',
                                    ),
                                    const SizedBox(width: 4),
                                    _buildDesktopNavButton(
                                      index: 3,
                                      icon: Icons.chat_bubble_outline,
                                      activeIcon: Icons.chat_bubble,
                                      label: 'Czat',
                                      badgeCount: unreadChats,
                                    ),

                                    const SizedBox(width: 10),

                                    // Mobile APK button
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF1E5128),
                                        side: const BorderSide(
                                            color: Color(0xFF2E7D32),
                                            width: 1.3),
                                        backgroundColor:
                                            Colors.green.shade50.withOpacity(0.6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      icon: const Icon(Icons.android_rounded,
                                          size: 17, color: Color(0xFF1E5128)),
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Pobierz APK',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E5128),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'v1.0',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      onPressed: () =>
                                          ApkDownloadDialog.show(context),
                                    ),

                                    const SizedBox(width: 10),

                                    // "+ Dodaj ogłoszenie" button
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: isDark
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFF1E5128),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text(
                                        'Dodaj ogłoszenie',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (!provider.isAuthenticated) {
                                          final loggedIn =
                                              await AuthDialog.show(context);
                                          if (loggedIn != true ||
                                              !context.mounted) {
                                            return;
                                          }
                                        }
                                        if (!context.mounted) {
                                          return;
                                        }
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          useSafeArea: true,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.vertical(
                                                    top: Radius.circular(24)),
                                          ),
                                          builder: (ctx) =>
                                              const CreateListingDialog(),
                                        );
                                      },
                                    ),

                                    const SizedBox(width: 6),

                                    // Dark / Light Theme Toggle Button
                                    IconButton(
                                      icon: Icon(
                                        provider.themeMode == ThemeMode.dark
                                            ? Icons.light_mode_rounded
                                            : Icons.dark_mode_outlined,
                                        size: 20,
                                        color: provider.themeMode == ThemeMode.dark
                                            ? Colors.amber
                                            : const Color(0xFF1E5128),
                                      ),
                                      tooltip: provider.themeMode == ThemeMode.dark
                                          ? 'Przełącz na motyw jasny'
                                          : 'Przełącz na motyw ciemny',
                                      onPressed: () => provider.toggleTheme(),
                                    ),

                                    const SizedBox(width: 6),

                                    // User Account Button
                                    if (provider.isAuthenticated)
                                      InkWell(
                                        onTap: () => UserProfileDialog.show(
                                          context,
                                          onNavigateToShelf: () =>
                                              setState(() => _currentIndex = 1),
                                          onNavigateToListings: () =>
                                              setState(() => _currentIndex = 0),
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1E3520)
                                                : Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: isDark
                                                    ? const Color(0xFF2E5E33)
                                                    : Colors.green.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: isDark
                                                    ? const Color(0xFF2E7D32)
                                                    : const Color(0xFF1E5128),
                                                child: Text(
                                                  provider
                                                      .currentUser!.initials,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 100),
                                                child: Text(
                                                  provider.currentUser!.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 12,
                                                    color: isDark
                                                        ? const Color(0xFF86E875)
                                                        : const Color(0xFF1E5128),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Icon(
                                                  Icons.arrow_drop_down,
                                                  size: 16,
                                                  color: isDark
                                                      ? const Color(0xFF86E875)
                                                      : const Color(0xFF1E5128)),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isDark
                                              ? const Color(0xFF86E875)
                                              : const Color(0xFF1E5128),
                                          side: BorderSide(
                                              color: isDark
                                                  ? const Color(0xFF4E9F3D)
                                                  : Colors.grey.shade400),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        icon: const Icon(
                                            Icons.person_outline_rounded,
                                            size: 16),
                                        label: const Text(
                                          'Zaloguj się',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        onPressed: () =>
                                            AuthDialog.show(context),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1300 : double.infinity,
          ),
          child: _buildActiveView(),
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
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

  Widget _buildDesktopNavButton({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int? count,
    int? badgeCount,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF243B26) : const Color(0xFFD6E8D5))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: (badgeCount != null && badgeCount > 0),
              label: Text('$badgeCount'),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 19,
                color: isSelected
                    ? (isDark ? const Color(0xFF86E875) : const Color(0xFF1E5128))
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? const Color(0xFF86E875) : const Color(0xFF1E5128))
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF2E7D32) : const Color(0xFF1E5128))
                      : (isDark ? const Color(0xFF28352A) : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey.shade200 : Colors.grey.shade800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
