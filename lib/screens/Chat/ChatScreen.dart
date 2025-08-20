import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String productOwnerId; // The ID of the product owner
  final String productImageUrl;
  final String productPrice;
  final String productCategory;
  final String currentUserId; // The ID of the currently logged-in user

  const ChatScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.productOwnerId,
    required this.productImageUrl,
    required this.productPrice,
    required this.productCategory,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _chatId; // Unique ID for this product-based conversation

  @override
  void initState() {
    super.initState();
    _generateChatId();
    _ensureChatDocumentExists();
  }

  // Generates a consistent chat ID based on product and participant UIDs
  void _generateChatId() {
    // Sort UIDs to ensure consistent chat ID regardless of who initiated
    List<String> participants = [widget.currentUserId, widget.productOwnerId];
    participants.sort(); // Sorts alphabetically

    _chatId = '${widget.productId}_${participants[0]}_${participants[1]}';
    print('Generated Chat ID: $_chatId');
  }

  // Ensures the main chat document exists in Firestore.
  // This document will hold metadata about the chat.
  Future<void> _ensureChatDocumentExists() async {
    if (_chatId == null) return;

    final chatDocRef = _firestore.collection('chats').doc(_chatId);
    final chatDoc = await chatDocRef.get();

    if (!chatDoc.exists) {
      // Create the chat document with initial metadata
      await chatDocRef.set({
        'productId': widget.productId,
        'ownerId': widget.productOwnerId,
        'buyerId': widget.currentUserId,
        'productName': widget.productName,
        'productImageUrl': widget.productImageUrl,
        'productPrice': widget.productPrice, // Store price for initial card
        'productCategory': widget.productCategory, // Store category for initial card
        'lastMessage': '', // Initialize last message
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Created new chat document: $_chatId');

      // Send the initial product card message as the 'owner' (or whichever user is designated to send it first)
      // For simplicity, let's say the current user (buyer) sends it implicitly on opening a new chat.
      await _sendProductCardMessage();
    }
  }

  // Sends a regular text message
  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty && _chatId != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final messageText = _controller.text;
        _controller.clear(); // Clear immediately for better UX

        await _firestore.collection('chats').doc(_chatId).collection('messages').add({
          'type': 'text',
          'text': messageText,
          'senderId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        // Update last message in the main chat document for chat list display
        await _firestore.collection('chats').doc(_chatId).update({
          'lastMessage': messageText,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Sends the custom product card message (typically sent once when chat starts or explicitly)
  Future<void> _sendProductCardMessage() async {
    if (_chatId != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('chats').doc(_chatId).collection('messages').add({
          'type': 'product_card',
          'senderId': user.uid, // The user initiating the chat sends this card
          'timestamp': FieldValue.serverTimestamp(),
          'productDetails': {
            'productId': widget.productId,
            'productName': widget.productName,
            'price': widget.productPrice,
            'category': widget.productCategory,
            'imageUrl': widget.productImageUrl,
          },
        });
        // Update last message in the main chat document
        await _firestore.collection('chats').doc(_chatId).update({
          'lastMessage': 'Product details shared',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Sends a 'Quote Price' action message
  Future<void> _sendQuotePriceAction() async {
    if (_chatId != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('chats').doc(_chatId).collection('messages').add({
          'type': 'quote_price_action',
          'senderId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        // Update last message in the main chat document
        await _firestore.collection('chats').doc(_chatId).update({
          'lastMessage': 'Quote price requested',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser; // Get current user in build method
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('You must be signed in to chat.')),
      );
    }

    // Determine the display name for the chat header
    final chatParticipantId = currentUser.uid == widget.productOwnerId ? widget.currentUserId : widget.productOwnerId;
        // In a real app, you would fetch the actual user's display name from your backend or a 'users' collection.

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Text(
                chatParticipantId.substring(0, 2).toUpperCase(), // Display initials
                style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              chatParticipantId, // Placeholder for other participant's name
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('chats')
                        .doc(_chatId)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No messages yet.'));
                      }

                      final messages = snapshot.data!.docs;
                      return ListView.builder(
                        reverse: true, // Show newest messages at the bottom
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final messageData = messages[index].data() as Map<String, dynamic>;
                          final messageType = messageData['type'];
                          final senderId = messageData['senderId'];
                          final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();
                          final isMe = senderId == currentUser.uid;

                          Widget messageWidget;

                          // Dynamically render message widgets based on 'type'
                          switch (messageType) {
                            case 'text':
                              messageWidget = ChatBubble(
                                text: messageData['text'],
                                isMe: isMe,
                                timestamp: timestamp,
                              );
                              break;
                            case 'product_card':
                              messageWidget = ProductCardMessage(
                                productDetails: messageData['productDetails'],
                                isMe: isMe,
                                timestamp: timestamp,
                              );
                              break;
                            case 'quote_price_action':
                              messageWidget = QuotePriceButton(
                                isMe: isMe,
                                timestamp: timestamp,
                                onPressed: () {
                                  // Handle quote price action, e.g., show a dialog to enter price
                                  print('Quote Price button pressed from message!');
                                },
                              );
                              break;
                            default:
                              messageWidget = ChatBubble(
                                text: 'Unsupported message type: $messageType',
                                isMe: isMe,
                                timestamp: timestamp,
                              );
                          }

                          return messageWidget;
                        },
                      );
                    },
                  ),
          ),
          // Quote Price button (as per screenshot, typically at the bottom of the chat)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _sendQuotePriceAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50), // Full width button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.deepPurple),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Quote Price',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Message input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: () {
                      // Handle attachment
                      print('Attachment button pressed');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
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

// --- Custom Message Widgets (Reused from previous code) ---

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime? timestamp;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isMe ? Colors.deepPurple[100] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Max width for bubble
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.deepPurple[900] : Colors.black,
              ),
            ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  DateFormat('hh:mm a').format(timestamp!),
                  style: TextStyle(
                    color: isMe ? Colors.deepPurple[600] : Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProductCardMessage extends StatelessWidget {
  final Map<String, dynamic> productDetails;
  final bool isMe;
  final DateTime? timestamp;

  const ProductCardMessage({
    super.key,
    required this.productDetails,
    required this.isMe,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85, // Wider for card
        ),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  productDetails['imageUrl'] ?? 'https://placehold.co/600x400',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(child: Text('Product Image N/A')),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productDetails['category'] ?? 'Category',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      productDetails['productName'] ?? 'Product Name',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${productDetails['price'] ?? '0'}',
                      style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    if (timestamp != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('hh:mm a').format(timestamp!),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuotePriceButton extends StatelessWidget {
  final bool isMe;
  final DateTime? timestamp;
  final VoidCallback onPressed;

  const QuotePriceButton({
    super.key,
    required this.isMe,
    this.timestamp,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center, // This button is always centered as per screenshot
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 40), // Adjust size as needed
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.deepPurple),
                ),
                elevation: 2,
              ),
              child: const Text('Quote Price'),
            ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  DateFormat('hh:mm a').format(timestamp!),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
