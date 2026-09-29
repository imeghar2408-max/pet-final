import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../widgets/empty_state_view.dart';

class ChatMessageVm {
  final String senderId;
  final String text;
  final DateTime sentAt;

  ChatMessageVm({
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessageVm.fromJson(Map<String, dynamic> json) => ChatMessageVm(
        senderId: json['senderId'],
        text: json['text'],
        sentAt: DateTime.parse(json['sentAt']),
      );
}

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String otherPartyName;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.otherPartyName,
  });

  factory ChatScreen.fromBooking(Booking booking) {
    return ChatScreen(
      bookingId: booking.id,
      otherPartyName: booking.otherPartyName ?? 'Caregiver',
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late BookingSocket _socket;
  final List<ChatMessageVm> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _myId;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final me = await UserApiService().getMe();
    if (me != null && mounted) {
      setState(() => _myId = me['id']);
    }

    _socket = BookingSocket(
      baseUrl: ApiConfig.baseUrl,
      namespace: 'chat',
      bookingId: widget.bookingId,
    );

    _socket.socket.on('connect', (_) {
      if (mounted) setState(() => _isConnected = true);
    });

    _socket.socket.on('disconnect', (_) {
      if (mounted) setState(() => _isConnected = false);
    });

    _socket.socket.on('message:new', (data) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessageVm.fromJson(data));
        });
        _scrollToBottom();
      }
    });
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

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _myId == null) return;

    _socket.socket.emit('message:send', {
      'bookingId': widget.bookingId,
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
    return Scaffold(
      backgroundColor: PetColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherPartyName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PetColors.dark),
            ),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: _isConnected ? PetColors.success : PetColors.darkLight,
                ),
                const SizedBox(width: 4),
                Text(
                  _isConnected ? 'Connected' : 'Connecting...',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _isConnected ? PetColors.success : PetColors.darkLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? EmptyStateView(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Start conversation',
                    description:
                        'Coordinate pickup, ask updates, or send special care reminders to ${widget.otherPartyName}.',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isMe = m.senderId == _myId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.76,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? PetColors.primary : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                            ),
                            border: isMe ? null : Border.all(color: PetColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isMe ? Colors.white : PetColors.dark,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                DateFormat('h:mm a').format(m.sentAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white.withOpacity(0.75) : PetColors.darkLight,
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: PetColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: PetColors.borderSubtle,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: PetColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _send,
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
}
