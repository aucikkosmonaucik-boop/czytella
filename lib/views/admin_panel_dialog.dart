import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/czytella_provider.dart';
import '../models/listing.dart';
import '../widgets/book_cover_widget.dart';

class AdminPanelDialog extends StatefulWidget {
  const AdminPanelDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AdminPanelDialog(),
    );
  }

  @override
  State<AdminPanelDialog> createState() => _AdminPanelDialogState();
}

class _AdminPanelDialogState extends State<AdminPanelDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _listingSearchController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;
  String _userFilter = '';
  String _listingFilter = '';

  Map<String, dynamic> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchController.dispose();
    _listingSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    final provider = context.read<CzytellaProvider>();
    final users = await provider.fetchAdminUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final provider = context.read<CzytellaProvider>();
    final stats = await provider.fetchAdminStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _confirmToggleBlockUser(
      Map<String, dynamic> user, CzytellaProvider provider) async {
    final email = user['email'] as String? ?? '';
    final name = user['name'] as String? ?? 'Użytkownik';
    final isBlocked = user['isBlocked'] == true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
              color: isBlocked ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isBlocked ? 'Odblokować konto?' : 'Zablokować konto?'),
          ],
        ),
        content: Text(
          isBlocked
              ? 'Czy chcesz przywrócić dostęp do konta dla $name ($email)? Użytkownik znów będzie mógł publikować oferty i pisać wiadomości.'
              : 'Czy na pewno chcesz zablokować konto $name ($email)? Użytkownik straci możliwość publikowania ogłoszeń i pisania wiadomości w Czytelli.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isBlocked ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isBlocked ? 'Odblokuj' : 'Zablokuj'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await provider.toggleBlockUser(email);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBlocked
                  ? 'Konto $name zostało pomyślnie odblokowane.'
                  : 'Konto $name zostało zablokowane.',
            ),
            backgroundColor: isBlocked ? Colors.green.shade800 : Colors.red.shade800,
          ),
        );
        _loadUsers();
        _loadStats();
      }
    }
  }

  Future<void> _confirmAdminDeleteListing(
      Listing listing, CzytellaProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('Moderacja: Usunąć ogłoszenie?'),
          ],
        ),
        content: Text(
          'Jako administrator usuniesz ogłoszenie "${listing.book.title}" (wystawił: ${listing.sellerName}) z bazy platformy Czytella. Tej operacji nie można cofnąć.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń z platformy'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await provider.adminDeleteListing(listing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usunięto ogłoszenie "${listing.book.title}".'),
            backgroundColor: Colors.red.shade800,
          ),
        );
        _loadStats();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CzytellaProvider>();
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF141914) : const Color(0xFF1E5128),
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFFFFC107), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel Administratora',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Zarządzanie kontami, moderacja i statystyki',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Zamknij',
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFFFC107),
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.people_alt_outlined, size: 18),
                    text: 'Konta (${_users.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    text: 'Ogłoszenia (${provider.allListings.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.insights_rounded, size: 18),
                    text: 'Statystyki',
                  ),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Zarejestrowane konta & Blokowanie
                _buildUsersTab(context, provider, isDark),

                // TAB 2: Moderacja ogłoszeń
                _buildListingsModerationTab(context, provider, isDark),

                // TAB 3: Statystyki platformy & Baza danych
                _buildStatsTab(context, provider, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: ZARZĄDZANIE KONTAMI I BLOKOWANIE
  // ==========================================
  Widget _buildUsersTab(
      BuildContext context, CzytellaProvider provider, bool isDark) {
    final filtered = _users.where((u) {
      if (_userFilter.isEmpty) return true;
      final q = _userFilter.toLowerCase();
      final name = (u['name'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      final city = (u['city'] as String? ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || city.contains(q);
    }).toList();

    return Column(
      children: [
        // Search & Refresh bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userSearchController,
                  onChanged: (val) => setState(() => _userFilter = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Szukaj konta (imię, email, miasto)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _userFilter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _userSearchController.clear();
                              setState(() => _userFilter = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Odśwież listę kont',
                onPressed: _loadUsers,
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            _userFilter.isEmpty
                                ? 'Brak zarejestrowanych kont w bazie'
                                : 'Nie znaleziono kont dla "$_userFilter"',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final u = filtered[i];
                        final email = u['email'] as String? ?? '';
                        final name = u['name'] as String? ?? 'Czytelnik';
                        final city = u['city'] as String? ?? 'Brak miasta';
                        final isBlocked = u['isBlocked'] == true;
                        final isSuperAdmin = email.toLowerCase() == 'aucikkosmonaucik@gmail.com';
                        final listingsCount = u['listingsCount'] as int? ?? 0;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? (isBlocked
                                    ? Colors.red.shade900.withOpacity(0.2)
                                    : const Color(0xFF1F261F))
                                : (isBlocked
                                    ? Colors.red.shade50
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isBlocked
                                  ? Colors.red.shade300
                                  : (isSuperAdmin
                                      ? const Color(0xFFFFC107)
                                      : (isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade300)),
                              width: isSuperAdmin ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isBlocked
                                    ? Colors.red.shade200
                                    : (isSuperAdmin
                                        ? const Color(0xFFFFC107)
                                        : const Color(0xFF1E5128)),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    color: isSuperAdmin ? Colors.black87 : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (isSuperAdmin)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFC107),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'ADMIN',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        if (isBlocked) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade700,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'ZABLOKOWANY',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.place_outlined,
                                            size: 13, color: Colors.grey.shade600),
                                        const SizedBox(width: 3),
                                        Text(
                                          city,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(Icons.book_outlined,
                                            size: 13, color: Colors.grey.shade600),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Ogłoszeń: $listingsCount',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isSuperAdmin)
                                const Chip(
                                  avatar: Icon(Icons.verified, size: 14, color: Color(0xFF1E5128)),
                                  label: Text('Główny Admin', style: TextStyle(fontSize: 11)),
                                  padding: EdgeInsets.zero,
                                )
                              else
                                FilledButton.tonal(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isBlocked
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    foregroundColor: isBlocked
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () =>
                                      _confirmToggleBlockUser(u, provider),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isBlocked
                                            ? Icons.lock_open_rounded
                                            : Icons.block_rounded,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isBlocked ? 'Odblokuj' : 'Zablokuj',
                                        style: const TextStyle(
                                            fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: MODERACJA WSZYSTKICH OGŁOSZEŃ
  // ==========================================
  Widget _buildListingsModerationTab(
      BuildContext context, CzytellaProvider provider, bool isDark) {
    final theme = Theme.of(context);
    final listings = provider.allListings.where((l) {
      if (_listingFilter.isEmpty) return true;
      final q = _listingFilter.toLowerCase();
      final title = l.book.title.toLowerCase();
      final author = l.book.author.toLowerCase();
      final seller = l.sellerName.toLowerCase();
      final city = l.city.toLowerCase();
      return title.contains(q) ||
          author.contains(q) ||
          seller.contains(q) ||
          city.contains(q);
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _listingSearchController,
                  onChanged: (val) =>
                      setState(() => _listingFilter = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Szukaj ogłoszenia (tytuł, autor, wystawiający)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _listingFilter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _listingSearchController.clear();
                              setState(() => _listingFilter = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Odśwież ogłoszenia',
                onPressed: () => provider.refreshListings(),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: listings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        _listingFilter.isEmpty
                            ? 'Brak ogłoszeń na platformie'
                            : 'Nie znaleziono ogłoszeń dla "$_listingFilter"',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: listings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final l = listings[i];

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F261F) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 44,
                              height: 60,
                              child: BookCoverWidget(
                                book: l.book,
                                width: 44,
                                height: 60,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.book.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  l.book.author,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.person_outline,
                                        size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        l.sellerName,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.primary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.place_outlined,
                                        size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 2),
                                    Text(
                                      l.city,
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.red),
                            tooltip: 'Usuń jako administrator',
                            onPressed: () =>
                                _confirmAdminDeleteListing(l, provider),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: STATYSTYKI PLATFORMY & BAZA DANYCH
  // ==========================================
  Widget _buildStatsTab(
      BuildContext context, CzytellaProvider provider, bool isDark) {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalListings = _stats['totalListings'] ?? provider.allListings.length;
    final totalUsers = _stats['totalUsers'] ?? _users.length;
    final blockedUsers = _stats['blockedUsers'] ?? 0;
    final totalMessages = _stats['totalMessages'] ?? 0;
    final dbConnected = _stats['dbConnected'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Database Status banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dbConnected
                  ? (isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50)
                  : (isDark ? Colors.amber.shade900.withOpacity(0.3) : Colors.amber.shade50),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dbConnected ? Colors.green.shade400 : Colors.amber.shade400,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  dbConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: dbConnected ? Colors.green.shade700 : Colors.amber.shade800,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dbConnected
                            ? 'Baza PostgreSQL na Railway: Połączono'
                            : 'Baza PostgreSQL: Tryb awaryjny (in-memory)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dbConnected
                            ? 'Dane są trwale zapisywane w chmurze Railway PostgreSQL.'
                            : 'Serwer działa lokalnie w pamięci RAM lub baza jest niedostępna.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stat Cards Grid
          Row(
            children: [
              Expanded(
                child: _buildAdminStatCard(
                  title: 'Wszystkie ogłoszenia',
                  value: totalListings.toString(),
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFF1E5128),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAdminStatCard(
                  title: 'Zarejestrowani',
                  value: totalUsers.toString(),
                  icon: Icons.people_alt_rounded,
                  color: Colors.blue.shade700,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAdminStatCard(
                  title: 'Zablokowane konta',
                  value: blockedUsers.toString(),
                  icon: Icons.block_rounded,
                  color: Colors.red.shade700,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAdminStatCard(
                  title: 'Wymienione wiadomości',
                  value: totalMessages.toString(),
                  icon: Icons.chat_bubble_outline_rounded,
                  color: Colors.teal.shade700,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Odśwież statystyki'),
                  onPressed: () {
                    _loadStats();
                    _loadUsers();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F261F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
