import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/theme.dart';

class ChatMessageVm {
  final String senderId;
  final String text;
  final DateTime sentAt;
  ChatMessageVm({required this.senderId, required this.text, required this.sentAt});

  factory ChatMessageVm.fromJson(Map<String, dynamic> json) => ChatMessageVm(
        senderId: json['senderId'] ?? '',
        text: json['text'] ?? '',
        sentAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : (json['sentAt'] != null ? DateTime.parse(json['sentAt']) : DateTime.now()),
      );
}

class ChatScreen extends StatefulWidget {
  final Booking booking;
  const ChatScreen({super.key, required this.booking});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiClient(baseUrl: ApiConfig.baseUrl);
  late BookingSocket _socket;
  final _messages = <ChatMessageVm>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? _myId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final me = await _api.post('/auth/me');
      _myId = me.data['id'];

      _socket = BookingSocket(
        baseUrl: ApiConfig.baseUrl,
        namespace: 'chat',
        bookingId: widget.booking.id,
      );

      _socket.socket.on('message:new', (data) {
        if (!mounted) return;
        setState(() {
          _messages.add(ChatMessageVm.fromJson(data));
        });
        _scrollToBottom();
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _myId == null) return;
    _socket.socket.emit('message:send', {
      'bookingId': widget.booking.id,
      'senderId': _myId,
      'text': text,
    });
    _controller.clear();
  }

  @override
  void dispose() {
    _socket.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = widget.booking.otherPartyName ?? 'Pet Owner';

    return Scaffold(
      backgroundColor: ProviderTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ownerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              '${widget.booking.serviceType.label} · ${widget.booking.petName ?? "Pet"}',
              style: const TextStyle(fontSize: 12, color: ProviderTheme.textMuted),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chat_bubble_outline, size: 40, color: ProviderTheme.textSubtle),
                                const SizedBox(height: 12),
                                Text(
                                  'Send a message to $ownerName',
                                  style: const TextStyle(fontSize: 14, color: ProviderTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            final isMe = m.senderId == _myId;
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe ? ProviderTheme.sagePrimary : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isMe ? null : Border.all(color: ProviderTheme.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.text,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : ProviderTheme.charcoal,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('h:mm a').format(m.sentAt),
                                      style: TextStyle(
                                        color: isMe ? Colors.white70 : ProviderTheme.textSubtle,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: ProviderTheme.border)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: ProviderTheme.sagePrimary),
                          onPressed: _send,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
