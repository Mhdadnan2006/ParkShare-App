import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import 'driver_providers.dart';
import '../domain/booking.dart';

class DriverMessagesTab extends ConsumerWidget {
  const DriverMessagesTab({super.key});

  void _showNewChatSheet(BuildContext context, WidgetRef ref, int myId, List<Booking> bookings) {
    final Map<int, String> landowners = {};
    for (var booking in bookings) {
      final spot = booking.spot;
      if (spot.owner > 0 && spot.owner != myId) {
        landowners[spot.owner] = spot.ownerName.isNotEmpty ? spot.ownerName : 'Landowner #${spot.owner}';
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgPanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final allContacts = [
          {'id': 1, 'name': 'Admin Support', 'isSupport': true},
          ...landowners.entries.map((e) => {'id': e.key, 'name': e.value, 'isSupport': false}),
        ];

        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Start a New Chat',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: allContacts.isEmpty
                    ? const Center(child: Text('No contacts available.', style: TextStyle(color: AppTheme.textMuted)))
                    : ListView.builder(
                        itemCount: allContacts.length,
                        itemBuilder: (context, index) {
                          final contact = allContacts[index];
                          final id = contact['id'] as int;
                          final name = contact['name'] as String;
                          final isSupport = contact['isSupport'] as bool;

                          return Card(
                            color: AppTheme.bgDark.withOpacity(0.5),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSupport
                                    ? AppTheme.warning.withOpacity(0.2)
                                    : AppTheme.primaryBlue.withOpacity(0.2),
                                child: Icon(
                                  isSupport ? Icons.admin_panel_settings : Icons.person,
                                  color: isSupport ? AppTheme.warning : AppTheme.primaryBlue,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                isSupport ? 'Help & Tech Support' : 'Parking Spot Landowner',
                                style: const TextStyle(color: AppTheme.textMuted),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DriverChatDetailScreen(
                                      otherUserId: id,
                                      otherUsername: name,
                                      myId: myId,
                                    ),
                                  ),
                                ).then((_) {
                                  ref.invalidate(driverMessagesProvider);
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(driverMessagesProvider);
    final profileAsync = ref.watch(driverProfileProvider);
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      floatingActionButton: profileAsync.when(
        data: (profile) => FloatingActionButton.extended(
          backgroundColor: AppTheme.primaryBlue,
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          label: const Text('New Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () => _showNewChatSheet(context, ref, profile['id'] as int, bookingsAsync.value ?? []),
        ),
        loading: () => null,
        error: (_, __) => null,
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
        error: (err, stack) => Center(
          child: Text('Error loading messages: $err', style: const TextStyle(color: AppTheme.error)),
        ),
        data: (messages) {
          if (messages.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No support messages yet.\nTap "New Chat" to start a conversation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
              ),
            );
          }

          return profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
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
                onRefresh: () => ref.refresh(driverMessagesProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chatList.length,
                  itemBuilder: (context, index) {
                    final chat = chatList[index];
                    final username = chat['username'] ?? 'Support Team';
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
                          backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                          child: Text(username[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isUnread ? Colors.white : AppTheme.textMuted,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('hh:mm a').format(time.toLocal()),
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                            if (isUnread)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DriverChatDetailScreen(
                                otherUserId: chat['userId'] as int,
                                otherUsername: username,
                                myId: myId as int,
                              ),
                            ),
                          ).then((_) {
                            ref.invalidate(driverMessagesProvider);
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

class DriverChatDetailScreen extends ConsumerStatefulWidget {
  final int otherUserId;
  final String otherUsername;
  final int myId;

  const DriverChatDetailScreen({
    super.key,
    required this.otherUserId,
    required this.otherUsername,
    required this.myId,
  });

  @override
  ConsumerState<DriverChatDetailScreen> createState() => _DriverChatDetailScreenState();
}

class _DriverChatDetailScreenState extends ConsumerState<DriverChatDetailScreen> {
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
      final success = await ref.read(driverMessageControllerProvider.notifier).sendMessage(widget.otherUserId, text);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message'), backgroundColor: AppTheme.error),
        );
      }
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
    final messagesAsync = ref.watch(driverMessagesProvider);

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
                ? const Center(child: Text('No messages yet.', style: TextStyle(color: AppTheme.textMuted)))
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
                            color: isMe ? AppTheme.primaryBlue : AppTheme.bgPanel,
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
                                  color: isMe ? Colors.white.withOpacity(0.6) : AppTheme.textMuted,
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
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
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
                        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryBlue,
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
