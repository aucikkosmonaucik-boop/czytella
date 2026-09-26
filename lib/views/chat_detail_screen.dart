import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../models/user_book.dart';
import '../providers/czytella_provider.dart';
import '../widgets/safe_exchange_badge.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatConversation conversation;
  final bool isEmbedded;

  const ChatDetailScreen({
    super.key,
    required this.conversation,
    this.isEmbedded = false,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(CzytellaProvider provider, {String? text, ExchangeProposal? proposal}) {
    final messageText = (text ?? _textController.text).trim();
    if (messageText.isEmpty && proposal == null) return;

    provider.sendMessage(
      widget.conversation.id,
      messageText,
      proposal: proposal,
    );

    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CzytellaProvider>();

    // Retrieve live conversation from provider to reflect new messages
    final liveConv = provider.conversations.firstWhere(
      (c) => c.id == widget.conversation.id,
      orElse: () => widget.conversation,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        titleSpacing: widget.isEmbedded ? 16 : 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                liveConv.otherUserName.substring(0, 1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    liveConv.otherUserName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${liveConv.otherUserCity} • Czytella Czat',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Colors.teal),
            tooltip: 'Zasady bezpieczeństwa',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => const Padding(
                  padding: EdgeInsets.all(20),
                  child: SafeExchangeBadge(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Usuń tę rozmowę',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Usunąć rozmowę?'),
                  content: const Text(
                      'Czy na pewno chcesz usunąć tę konwersację z listy wiadomości?'),
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
              if (confirm == true && context.mounted) {
                provider.deleteConversation(liveConv.id);
                if (!widget.isEmbedded) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned Context Book Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border(bottom: BorderSide(color: Colors.amber.shade200)),
            ),
            child: Row(
              children: [
                if (liveConv.bookCoverUrl != null)
                  Container(
                    width: 26,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey.shade300,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      liveConv.bookCoverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.book, size: 16),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dotyczy oferty: ${liveConv.bookTitle}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '🔒 Bezpieczna wymiana — nie podawaj numeru telefonu ani FB',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.brown.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Message Bubbles List
          Expanded(
            child: liveConv.messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Rozpocznij rozmowę z ${liveConv.otherUserName}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Wpisz wiadomość poniżej, aby bezpośrednio ustalić szczegóły.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: liveConv.messages.length,
                    itemBuilder: (context, index) {
                      final message = liveConv.messages[index];
                      return _buildMessageItem(
                          context, provider, message, liveConv);
                    },
                  ),
          ),

          // Chat Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Propose exchange icon button
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Colors.teal),
                    tooltip: 'Zaproponuj wymianę książek',
                    onPressed: () => _openProposalDialog(context, provider),
                  ),
                  const SizedBox(width: 4),

                  // Message field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Napisz wiadomość (bezpiecznie w Czytelli)...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor:
                            theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(provider),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Send button
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, size: 18, color: Colors.white),
                      onPressed: () => _sendMessage(provider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    CzytellaProvider provider,
    ChatMessage msg,
    ChatConversation liveConv,
  ) {
    final theme = Theme.of(context);

    // System message
    if (msg.senderId == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 13, color: Colors.teal),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isMe = msg.isMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                msg.senderName.substring(0, 1),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // If message contains structured exchange proposal
                if (msg.proposal != null)
                  _buildProposalCard(
                      context, provider, msg.proposal!, liveConv, isMe),

                // Text Bubble
                if (msg.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe
                          ? theme.colorScheme.primary
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 2),

                // Timestamp
                Text(
                  DateFormat('HH:mm').format(msg.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(
    BuildContext context,
    CzytellaProvider provider,
    ExchangeProposal prop,
    ChatConversation liveConv,
    bool isMe,
  ) {
    Color statusColor;
    switch (prop.status) {
      case ProposalStatus.accepted:
        statusColor = Colors.green;
        break;
      case ProposalStatus.declined:
        statusColor = Colors.red;
        break;
      case ProposalStatus.pending:
        statusColor = Colors.orange;
        break;
    }

    return Container(
      width: 260,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horizontal_circle,
                  color: Colors.teal, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Propozycja wymiany',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 14),
          Text(
            'Oferowana książka:',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          Text(
            '📚 ${prop.offeredBookTitle}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'W zamian za:',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          Text(
            '📖 ${prop.requestedBookTitle}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          if (prop.proposedLocation != null &&
              prop.proposedLocation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '📍 Miejsce spotkania: ${prop.proposedLocation}',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade800),
            ),
          ],
          const SizedBox(height: 10),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              prop.status.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),

          // If pending and not me (or for testing), allow accept
          if (prop.status == ProposalStatus.pending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      provider.updateProposalStatus(
                        liveConv.id,
                        prop.id,
                        ProposalStatus.accepted,
                      );
                      provider.sendMessage(
                        liveConv.id,
                        'Super, zgadzam się na tę wymianę! Do zobaczenia na miejscu spotkania.',
                      );
                    },
                    child: const Text('Akceptuj',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      provider.updateProposalStatus(
                        liveConv.id,
                        prop.id,
                        ProposalStatus.declined,
                      );
                    },
                    child: const Text('Odrzuć',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openProposalDialog(BuildContext context, CzytellaProvider provider) {
    final userBooks = provider.userBooks;

    if (userBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Dodaj najpierw książki do swojej półki, aby móc zaproponować wymianę.'),
        ),
      );
      return;
    }

    UserBook selected = userBooks.first;
    final locCtrl = TextEditingController(text: 'Kawiarnia / Stacja Metra');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Zaproponuj wymianę książek'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Wybierz książkę ze swojej półki:'),
              const SizedBox(height: 8),
              DropdownButton<UserBook>(
                isExpanded: true,
                value: selected,
                items: userBooks
                    .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(b.book.title,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selected = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(
                  labelText: 'Proponowane bezpieczne miejsce spotkania',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                final proposal = ExchangeProposal(
                  id: 'prop_${DateTime.now().millisecondsSinceEpoch}',
                  offeredBookTitle:
                      '${selected.book.title} (${selected.book.author})',
                  offeredBookCover: selected.book.coverUrl,
                  requestedBookTitle: widget.conversation.bookTitle,
                  proposedLocation: locCtrl.text.trim(),
                );
                _sendMessage(
                  provider,
                  text: '',
                  proposal: proposal,
                );
              },
              child: const Text('Wyślij propozycję'),
            ),
          ],
        ),
      ),
    );
  }
}
