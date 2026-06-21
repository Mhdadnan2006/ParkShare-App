import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import 'landowner_providers.dart';

class LandownerMessagesTab extends ConsumerStatefulWidget {
  const LandownerMessagesTab({super.key});

  @override
  ConsumerState<LandownerMessagesTab> createState() => _LandownerMessagesTabState();
}

class _LandownerMessagesTabState extends ConsumerState<LandownerMessagesTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: AppTheme.bgPanel,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.secondary,
            labelColor: AppTheme.secondary,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(icon: Icon(Icons.smart_toy_outlined), text: 'ParkBot AI'),
              Tab(icon: Icon(Icons.forum_outlined), text: 'Inbox'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ParkBotChatView(),
          DirectInboxView(),
        ],
      ),
    );
  }
}

class ParkBotChatView extends ConsumerStatefulWidget {
  const ParkBotChatView({super.key});

  @override
  ConsumerState<ParkBotChatView> createState() => _ParkBotChatViewState();
}

class _ParkBotChatViewState extends ConsumerState<ParkBotChatView> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [
    {
      'isBot': true,
      'text': 'Hi! I am ParkBot, your AI Optimization Assistant.\n\nYou can ask me:\n- "Analyze 500 sqft" to optimize layout\n- "Who is parking now?" to view status\n- "My total revenue" to view earnings',
      'timestamp': DateTime.now()
    }
  ];
  bool _isTyping = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _chatMessages.add({'isBot': false, 'text': text, 'timestamp': DateTime.now()});
      _isTyping = true;
    });

    try {
      final repo = ref.read(landownerRepositoryProvider);
      final response = await repo.sendParkBotMessage(text);
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'isBot': true,
            'text': response['reply'] ?? 'I could not process that message.',
            'timestamp': DateTime.now()
          });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chatMessages.add({
            'isBot': true,
            'text': 'Sorry, I encountered an error communicating with the backend chatbot.',
            'timestamp': DateTime.now()
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              final isBot = msg['isBot'] as bool;
              return Align(
                alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isBot ? AppTheme.bgPanel : AppTheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isBot ? Radius.zero : const Radius.circular(16),
                      bottomRight: isBot ? const Radius.circular(16) : Radius.zero,
                    ),
                    border: Border.all(
                      color: isBot ? AppTheme.borderDark : AppTheme.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['text'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('hh:mm a').format(msg['timestamp'] as DateTime),
                        style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isTyping)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondary),
                  ),
                  const SizedBox(width: 8),
                  Text('ParkBot is thinking...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ask ParkBot...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.bgPanel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: AppTheme.borderDark),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: AppTheme.borderDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.secondary,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DirectInboxView extends ConsumerWidget {
  const DirectInboxView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
        error: (err, stack) => Center(
          child: Text('Error loading messages: $err', style: const TextStyle(color: AppTheme.error)),
        ),
        data: (messages) {
          if (messages.isEmpty) {
            return const Center(child: Text('No messages yet.', style: TextStyle(color: AppTheme.textSecondary)));
          }

          return profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppTheme.error))),
            data: (myProfile) {
              final myId = myProfile['id'];

              final Map<int, Map<String, dynamic>> conversations = {};
              for (var msg in messages) {
                final senderId = msg['sender_id'];
                final receiverId = msg['receiver_id'];
                final isMeSender = senderId == myId;
                final otherUserId = isMeSender ? receiverId : senderId;
                final otherUsername = isMeSender ? msg['receiver_username'] : msg['sender_username'];

                final existing = conversations[otherUserId];
                if (existing == null || (DateTime.parse(msg['timestamp']).isAfter(DateTime.parse(existing['timestamp'])))) {
                  conversations[otherUserId] = {
                    'userId': otherUserId,
                    'username': otherUsername,
                    'lastMessage': msg['content'],
                    'timestamp': msg['timestamp'],
                    'unread': !msg['is_read'] && !isMeSender,
                  };
                }
              }

              final chatList = conversations.values.toList();
              chatList.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

              return RefreshIndicator(
                onRefresh: () => ref.refresh(messagesProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chatList.length,
                  itemBuilder: (context, index) {
                    final chat = chatList[index];
                    final username = chat['username'] ?? 'User';
                    final lastMessage = chat['lastMessage'] ?? '';
                    final time = DateTime.parse(chat['timestamp']);
                    final isUnread = chat['unread'] as bool;

                    return Card(
                      color: AppTheme.bgPanel,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.secondary.withOpacity(0.2),
                          child: Text(username[0].toUpperCase(), style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isUnread ? Colors.white : AppTheme.textSecondary,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('hh:mm a').format(time.toLocal()),
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            if (isUnread)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                otherUserId: chat['userId'] as int,
                                otherUsername: username,
                                myId: myId as int,
                              ),
                            ),
                          ).then((_) {
                            ref.invalidate(messagesProvider);
                          });
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatDetailScreen extends ConsumerStatefulWidget {
  final int otherUserId;
  final String otherUsername;
  final int myId;

  const ChatDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUsername,
    required this.myId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _controller.clear();

    try {
      final repo = ref.read(landownerRepositoryProvider);
      await repo.sendMessage(widget.otherUserId, text);
      ref.invalidate(messagesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider);

    final chatMessages = messagesAsync.value?.where((msg) {
      final senderId = msg['sender_id'];
      final receiverId = msg['receiver_id'];
      return (senderId == widget.myId && receiverId == widget.otherUserId) ||
             (senderId == widget.otherUserId && receiverId == widget.myId);
    }).toList() ?? [];

    chatMessages.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(widget.otherUsername),
        backgroundColor: AppTheme.bgPanel,
      ),
      body: Column(
        children: [
          Expanded(
            child: chatMessages.isEmpty
                ? const Center(child: Text('No messages yet.', style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = chatMessages[index];
                      final isMe = msg['sender_id'] == widget.myId;
                      final timestamp = DateTime.parse(msg['timestamp']);

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.secondary : AppTheme.bgPanel,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['content'] ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('hh:mm a').format(timestamp.toLocal()),
                                style: TextStyle(
                                  color: isMe ? Colors.white.withOpacity(0.6) : AppTheme.textSecondary,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.bgPanel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppTheme.borderDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: AppTheme.borderDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.secondary,
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
