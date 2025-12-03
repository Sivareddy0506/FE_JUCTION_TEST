import 'package:flutter/material.dart';
import 'package:junction/screens/Chat/chat_page.dart';
import 'package:junction/screens/services/chat_service.dart';
import '../../../widgets/custom_appbar.dart';
import '../../app.dart'; // For SlidePageRoute

class ChatListPage extends StatelessWidget {
  final ChatService _chatService = ChatService();

  ChatListPage({super.key});

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
                  child: Row(
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
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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
