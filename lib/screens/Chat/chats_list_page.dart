import 'package:flutter/material.dart';
import 'package:junction/screens/Chat/chat_page.dart';
import 'package:junction/screens/services/chat_service.dart';
import '../../../widgets/custom_appbar.dart';
import '../../app.dart'; // For SlidePageRoute
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: "Chats"),
      body: StreamBuilder<List<ChatModel>>(
        stream: _chatService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<ChatModel> chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length + 1, // +1 for "Archived Chats" option
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFFEAEAEA),
            ),
            itemBuilder: (context, index) {
              // Show "Archived Chats" option at the end
              if (index == chats.length) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      SlidePageRoute(
                        page: const ArchivedChatsPage(),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.archive,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Archived Chats',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              }
              ChatModel chat = chats[index];
              String otherUserName = chat.sellerId == _chatService.currentUserIdSync
                  ? chat.buyerName
                  : chat.sellerName;

              // Split into first and last name initials
              final nameParts = otherUserName.trim().split(' ');
              String initials = '';
              if (nameParts.isNotEmpty) {
                initials += nameParts.first[0];
                if (nameParts.length > 1) initials += nameParts.last[0];
              }
              initials = initials.toUpperCase();

              // Fallback if initials are empty
              if (initials.isEmpty) {
                initials = otherUserName.isNotEmpty
                    ? otherUserName[0].toUpperCase()
                    : 'U';
              }

              Color avatarColor = _getAvatarColorLight(otherUserName);

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      page: ChatPage(chatId: chat.chatId),
                    ),
                  );
                },
                child: Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('messages')
                        .doc(chat.chatId)
                        .collection('messages')
                        .where('receiverId', isEqualTo: _chatService.currentUserIdSync)
                        .where('isRead', isEqualTo: false)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final hasUnread = snapshot.hasData && 
                          snapshot.data!.docs.isNotEmpty;
                      
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: avatarColor,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  otherUserName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  chat.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: hasUnread ? Colors.black87 : Colors.grey,
                                    fontSize: 14,
                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasUnread) ...[
                                Image.asset(
                                  'assets/orange_dot.png',
                                  width: 10,
                                  height: 10,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                _formatTime(chat.lastMessageTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Soft pastel avatar colors for better readability
  Color _getAvatarColorLight(String name) {
    final colors = [
      const Color(0xFFE0BBE4),
      const Color(0xFFB5EAD7),
      const Color(0xFFFFDAC1),
      const Color(0xFFC7CEEA),
      const Color(0xFFFFF3B0),
      const Color(0xFFFFD6A5),
      const Color(0xFFA0E7E5),
    ];
    return colors[name.hashCode % colors.length];
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 6) {
      return '${difference.inDays ~/ 7}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

/// Page to display archived chats
class ArchivedChatsPage extends StatefulWidget {
  const ArchivedChatsPage({super.key});

  @override
  State<ArchivedChatsPage> createState() => _ArchivedChatsPageState();
}

class _ArchivedChatsPageState extends State<ArchivedChatsPage> {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: "Archived Chats"),
      body: StreamBuilder<List<ChatModel>>(
        stream: _chatService.getArchivedChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          List<ChatModel> chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No archived chats',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFFEAEAEA),
            ),
            itemBuilder: (context, index) {
              ChatModel chat = chats[index];
              String otherUserName = chat.sellerId == _chatService.currentUserIdSync
                  ? chat.buyerName
                  : chat.sellerName;

              // Split into first and last name initials
              final nameParts = otherUserName.trim().split(' ');
              String initials = '';
              if (nameParts.isNotEmpty) {
                initials += nameParts.first[0];
                if (nameParts.length > 1) initials += nameParts.last[0];
              }
              initials = initials.toUpperCase();

              // Fallback if initials are empty
              if (initials.isEmpty) {
                initials = otherUserName.isNotEmpty
                    ? otherUserName[0].toUpperCase()
                    : 'U';
              }

              Color avatarColor = _getAvatarColorLight(otherUserName);

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      page: ChatPage(chatId: chat.chatId),
                    ),
                  );
                },
                child: Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('messages')
                        .doc(chat.chatId)
                        .collection('messages')
                        .where('receiverId', isEqualTo: _chatService.currentUserIdSync)
                        .where('isRead', isEqualTo: false)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final hasUnread = snapshot.hasData && 
                          snapshot.data!.docs.isNotEmpty;
                      
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: avatarColor,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  otherUserName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  chat.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: hasUnread ? Colors.black87 : Colors.grey,
                                    fontSize: 14,
                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasUnread) ...[
                                Image.asset(
                                  'assets/orange_dot.png',
                                  width: 10,
                                  height: 10,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                _formatTime(chat.lastMessageTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Soft pastel avatar colors for better readability
  Color _getAvatarColorLight(String name) {
    final colors = [
      const Color(0xFFE0BBE4),
      const Color(0xFFB5EAD7),
      const Color(0xFFFFDAC1),
      const Color(0xFFC7CEEA),
      const Color(0xFFFFF3B0),
      const Color(0xFFFFD6A5),
      const Color(0xFFA0E7E5),
    ];
    return colors[name.hashCode % colors.length];
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 6) {
      return '${difference.inDays ~/ 7}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
