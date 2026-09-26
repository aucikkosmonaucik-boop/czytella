import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../providers/czytella_provider.dart';
import '../widgets/safe_exchange_badge.dart';
import 'chat_detail_screen.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  String? _selectedConversationId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CzytellaProvider>();
    final conversations = provider.conversations;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    // Default select first conversation on desktop if none selected
    if (isDesktop && _selectedConversationId == null && conversations.isNotEmpty) {
      _selectedConversationId = conversations.first.id;
    }

    if (isDesktop) {
      ChatConversation? selectedConv;
      if (_selectedConversationId != null && conversations.isNotEmpty) {
        selectedConv = conversations.firstWhere(
          (c) => c.id == _selectedConversationId,
          orElse: () => conversations.first,
        );
      }

      return Scaffold(
        body: Row(
          children: [
            // Left pane: Chat list
            Container(
              width: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Wiadomości i czaty',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E5128),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SafeExchangeBadge(),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildConversationList(
                      context,
                      theme,
                      provider,
                      conversations,
                      isDesktop: true,
                    ),
                  ),
                ],
              ),
            ),

            // Right pane: Active conversation
            Expanded(
              child: selectedConv != null
                  ? ChatDetailScreen(
                      conversation: selectedConv,
                      isEmbedded: true,
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              conversations.isEmpty
                                  ? 'Brak aktywnych rozmów'
                                  : 'Wybierz rozmowę z listy po lewej',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            if (conversations.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Gdy napiszesz do innego czytelnika w sprawie ogłoszenia książki,\nrozmowa pojawi się tutaj.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    // Mobile layout
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wiadomości',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SafeExchangeBadge(),
          ),
          Expanded(
            child: _buildConversationList(
              context,
              theme,
              provider,
              conversations,
              isDesktop: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(
    BuildContext context,
    ThemeData theme,
    CzytellaProvider provider,
    List<ChatConversation> conversations, {
    required bool isDesktop,
  }) {
    if (conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 14),
              const Text(
                'Brak aktywnych rozmów',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gdy znajdziesz interesującą książkę w ogłoszeniach, kliknij "Napisz na czacie", aby bezpiecznie dogadać wymianę.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final conv = conversations[index];
        final hasUnread = conv.unreadCount > 0;
        final isSelected = isDesktop && conv.id == _selectedConversationId;

        return Container(
          color: isSelected ? const Color(0xFFEAF4EA) : Colors.transparent,
          child: ListTile(
            selected: isSelected,
            onTap: () {
              provider.markConversationAsRead(conv.id);
              if (isDesktop) {
                setState(() => _selectedConversationId = conv.id);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ChatDetailScreen(conversation: conv),
                  ),
                );
              }
            },
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isSelected
                      ? const Color(0xFF1E5128)
                      : theme.colorScheme.primaryContainer,
                  child: Text(
                    conv.otherUserName.substring(0, 1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    conv.otherUserName,
                    style: TextStyle(
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatTime(conv.lastActivity),
                  style: TextStyle(
                    fontSize: 11,
                    color: hasUnread
                        ? theme.colorScheme.primary
                        : Colors.grey.shade500,
                    fontWeight:
                        hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.menu_book,
                        size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        conv.bookTitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  conv.lastMessageSnippet,
                  style: TextStyle(
                    fontSize: 12,
                    color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                    fontWeight:
                        hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasUnread)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E5128),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${conv.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade500),
                  tooltip: 'Opcje',
                  onSelected: (val) async {
                    if (val == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Usunąć rozmowę?'),
                          content: Text('Czy na pewno chcesz usunąć rozmowę z użytkownikiem ${conv.otherUserName}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Anuluj'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Usuń'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        provider.deleteConversation(conv.id);
                        if (_selectedConversationId == conv.id) {
                          setState(() => _selectedConversationId = null);
                        }
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Usuń rozmowę', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} d';
    } else {
      return DateFormat('d MMM', 'pl').format(dt);
    }
  }
}
