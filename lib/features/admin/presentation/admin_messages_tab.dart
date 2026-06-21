import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import 'admin_providers.dart';

class AdminMessagesTab extends ConsumerStatefulWidget {
  const AdminMessagesTab({super.key});

  @override
  ConsumerState<AdminMessagesTab> createState() => _AdminMessagesTabState();
}

class _AdminMessagesTabState extends ConsumerState<AdminMessagesTab> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedUser = ref.watch(adminSelectedUserChatProvider);
    final messagesAsync = ref.watch(adminMessagesProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
        error: (err, stack) => _buildErrorState(),
        data: (data) {
          final conversations = data['conversations'] as List<dynamic>? ?? [];
          
          if (selectedUser == null) {
            return _buildInboxView(conversations);
          } else {
            final thread = data['thread'] as List<dynamic>? ?? [];
            // Find active conversation details
            final activeConv = conversations.firstWhere(
              (c) => c['userId'].toString() == selectedUser,
              orElse: () => null,
            );
            final String username = activeConv != null ? activeConv['username'] : 'User $selectedUser';
            final String channel = activeConv != null ? activeConv['channel'] : 'support';

            // Trigger scroll to bottom on load
            _scrollToBottom();

            return _buildChatThreadView(selectedUser, username, channel, thread);
          }
        },
      ),
    );
  }

  Widget _buildInboxView(List<dynamic> conversations) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, color: AppTheme.textMuted.withOpacity(0.5), size: 48),
            const SizedBox(height: 16),
            const Text(
              'No Support Conversations',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'User messages and chatbot escalation requests will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conv = conversations[index];
        final bool isUnread = conv['unread'] == true;
        final String channel = conv['channel'] ?? 'support';
        final String lastMsg = conv['lastMessage'] ?? '';
        final String username = conv['username'] ?? '';
        final String userId = conv['userId'].toString();

        String timeStr = '';
        try {
          final dt = DateTime.parse(conv['timestamp']);
          timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } catch (_) {}

        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderDark, width: 0.5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: channel == 'driver' ? AppTheme.secondary.withOpacity(0.15) : AppTheme.accent.withOpacity(0.15),
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'U',
                style: TextStyle(color: channel == 'driver' ? AppTheme.secondary : AppTheme.accent, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              children: [
                Text(
                  username,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                _buildChannelBadge(channel),
                const Spacer(),
                Text(timeStr, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnread ? Colors.white : AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
            onTap: () {
              ref.read(adminSelectedUserChatProvider.notifier).state = userId;
            },
          ),
        );
      },
    );
  }

  Widget _buildChannelBadge(String channel) {
    final Color color = channel == 'driver' ? AppTheme.secondary : AppTheme.accent;
    final String label = channel.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildChatThreadView(String userId, String username, String channel, List<dynamic> thread) {
    return Column(
      children: [
        // Thread Header
        Container(
          color: AppTheme.bgPanel,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  ref.read(adminSelectedUserChatProvider.notifier).state = null;
                },
              ),
              CircleAvatar(
                backgroundColor: channel == 'driver' ? AppTheme.secondary.withOpacity(0.15) : AppTheme.accent.withOpacity(0.15),
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: TextStyle(color: channel == 'driver' ? AppTheme.secondary : AppTheme.accent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Direct Support Channel',
                        style: TextStyle(color: AppTheme.textMuted.withOpacity(0.7), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Message Thread List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: thread.length,
            itemBuilder: (context, index) {
              final msg = thread[index];
              final bool isClient = msg['sender_id'].toString() == userId;
              
              String timeStr = '';
              try {
                final dt = DateTime.parse(msg['timestamp']);
                timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              } catch (_) {}

              return Align(
                alignment: isClient ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isClient ? AppTheme.bgPanel : AppTheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isClient ? 0 : 16),
                      bottomRight: Radius.circular(isClient ? 16 : 0),
                    ),
                    border: Border.all(
                      color: isClient ? AppTheme.borderDark : AppTheme.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['content'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          timeStr,
                          style: TextStyle(color: AppTheme.textMuted.withOpacity(0.6), fontSize: 9),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Text entry field
        Container(
          color: AppTheme.bgPanel,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    filled: true,
                    fillColor: AppTheme.bgDark,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppTheme.borderDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppTheme.secondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppTheme.secondary,
                radius: 22,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: () => _sendMessage(userId),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage(String userId) async {
    final String content = _msgController.text.trim();
    if (content.isEmpty) return;

    _msgController.clear();

    final int? receiverId = int.tryParse(userId);
    if (receiverId == null) return;

    final success = await ref
        .read(adminMessagesControllerProvider.notifier)
        .sendAdminMessage(receiverId, content);

    if (success) {
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message.')),
        );
      }
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 40),
          const SizedBox(height: 12),
          const Text('Failed to load messaging inbox.', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(adminMessagesProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
