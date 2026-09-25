enum ProposalStatus {
  pending,
  accepted,
  declined,
}

extension ProposalStatusExtension on ProposalStatus {
  String get label {
    switch (this) {
      case ProposalStatus.pending:
        return 'Oczekuje na odpowiedź';
      case ProposalStatus.accepted:
        return 'Wymiana zaakceptowana! 🎉';
      case ProposalStatus.declined:
        return 'Propozycja odrzucona';
    }
  }
}

class ExchangeProposal {
  final String id;
  final String offeredBookTitle;
  final String? offeredBookCover;
  final String requestedBookTitle;
  final String? proposedLocation;
  final ProposalStatus status;

  ExchangeProposal({
    required this.id,
    required this.offeredBookTitle,
    this.offeredBookCover,
    required this.requestedBookTitle,
    this.proposedLocation,
    this.status = ProposalStatus.pending,
  });

  ExchangeProposal copyWith({
    String? id,
    String? offeredBookTitle,
    String? offeredBookCover,
    String? requestedBookTitle,
    String? proposedLocation,
    ProposalStatus? status,
  }) {
    return ExchangeProposal(
      id: id ?? this.id,
      offeredBookTitle: offeredBookTitle ?? this.offeredBookTitle,
      offeredBookCover: offeredBookCover ?? this.offeredBookCover,
      requestedBookTitle: requestedBookTitle ?? this.requestedBookTitle,
      proposedLocation: proposedLocation ?? this.proposedLocation,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offeredBookTitle': offeredBookTitle,
      'offeredBookCover': offeredBookCover,
      'requestedBookTitle': requestedBookTitle,
      'proposedLocation': proposedLocation,
      'status': status.name,
    };
  }

  factory ExchangeProposal.fromJson(Map<String, dynamic> json) {
    return ExchangeProposal(
      id: json['id'] ?? '',
      offeredBookTitle: json['offeredBookTitle'] ?? '',
      offeredBookCover: json['offeredBookCover'],
      requestedBookTitle: json['requestedBookTitle'] ?? '',
      proposedLocation: json['proposedLocation'],
      status: json['status'] == 'accepted'
          ? ProposalStatus.accepted
          : json['status'] == 'declined'
              ? ProposalStatus.declined
              : ProposalStatus.pending,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final ExchangeProposal? proposal;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    DateTime? timestamp,
    required this.isMe,
    this.proposal,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isMe': isMe,
      'proposal': proposal?.toJson(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isMe: json['isMe'] ?? false,
      proposal: json['proposal'] != null
          ? ExchangeProposal.fromJson(json['proposal'])
          : null,
    );
  }
}

class ChatConversation {
  final String id;
  final String listingId;
  final String bookTitle;
  final String bookAuthor;
  final String? bookCoverUrl;
  final String otherUserId;
  final String otherUserName;
  final String otherUserCity;
  final List<ChatMessage> messages;
  final DateTime updatedAt;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.listingId,
    required this.bookTitle,
    required this.bookAuthor,
    this.bookCoverUrl,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserCity,
    required this.messages,
    DateTime? updatedAt,
    this.unreadCount = 0,
  }) : updatedAt = updatedAt ?? DateTime.now();

  ChatConversation copyWith({
    String? id,
    String? listingId,
    String? bookTitle,
    String? bookAuthor,
    String? bookCoverUrl,
    String? otherUserId,
    String? otherUserName,
    String? otherUserCity,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
    int? unreadCount,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      bookTitle: bookTitle ?? this.bookTitle,
      bookAuthor: bookAuthor ?? this.bookAuthor,
      bookCoverUrl: bookCoverUrl ?? this.bookCoverUrl,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserCity: otherUserCity ?? this.otherUserCity,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  String get lastMessagePreview {
    if (messages.isEmpty) return 'Brak wiadomości';
    final last = messages.last;
    if (last.proposal != null) {
      return '📋 Propozycja wymiany: ${last.proposal!.offeredBookTitle}';
    }
    return last.text;
  }

  String get lastMessageSnippet => lastMessagePreview;

  DateTime get lastActivity =>
      messages.isNotEmpty ? messages.last.timestamp : updatedAt;
}
