import 'package:flutter/material.dart';
import 'package:junction/screens/Chat/chat_page.dart';
import 'package:junction/screens/services/chat_service.dart';

// import 'firebase_options.dart';

class ChatListPage extends StatelessWidget {
  final ChatService _chatService = ChatService();

  ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              ChatModel chat = chats[index];
              String otherUserName = chat.sellerId == _chatService.currentUserId 
                  ? chat.buyerName 
                  : chat.sellerName;

              // Generate avatar based on name
              String initials = otherUserName.trim().split(' ')
                       .where((name) => name.isNotEmpty)
                        .take(2)
                        .map((name) => name[0])
                        .join()
                        .toUpperCase();

// Fallback for empty names or edge cases
if (initials.isEmpty) {
  initials = otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U';
}
              Color avatarColor = _getAvatarColor(otherUserName);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: avatarColor,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  otherUserName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Text(
                  _formatTime(chat.lastMessageTime),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(chatId: chat.chatId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.purple,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
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