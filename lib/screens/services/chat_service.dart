import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatModel {
  final String chatId;
  final String productId;
  final String sellerId;
  final String buyerId;
  final String sellerName;
  final String buyerName;
  final String productTitle;
  final String productImage;
  final String productPrice;
  final String lastMessage;
  final DateTime lastMessageTime;
  final DateTime createdAt;
  final String dealStatus;
  final double? finalPrice;
  final List<String> participants;

  ChatModel({
    required this.chatId,
    required this.productId,
    required this.sellerId,
    required this.buyerId,
    required this.sellerName,
    required this.buyerName,
    required this.productTitle,
    required this.productImage,
    required this.productPrice,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.createdAt,
    this.dealStatus = 'active',
    this.finalPrice,
    required this.participants,
  });

  factory ChatModel.fromFirestore(Map<String, dynamic> data) {
    return ChatModel(
      chatId: data['chatId'] ?? '',
      productId: data['productId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      buyerName: data['buyerName'] ?? '',
      productTitle: data['productTitle'] ?? '',
      productImage: data['productImage'] ?? '',
      productPrice: data['productPrice'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dealStatus: data['dealStatus'] ?? 'active',
      finalPrice: data['finalPrice']?.toDouble(),
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'productId': productId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'sellerName': sellerName,
      'buyerName': buyerName,
      'productTitle': productTitle,
      'productImage': productImage,
      'productPrice': productPrice,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'dealStatus': dealStatus,
      'finalPrice': finalPrice,
      'participants': participants,
    };
  }
}

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final String messageType;
  final bool isRead;
  final Map<String, dynamic>? priceData;
  final Map<String, dynamic>? productData;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.messageType = 'text',
    this.isRead = false,
    this.priceData,
    this.productData,
  });

  factory MessageModel.fromFirestore(Map<String, dynamic> data) {
    return MessageModel(
      messageId: data['messageId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      messageType: data['messageType'] ?? 'text',
      isRead: data['isRead'] ?? false,
      priceData: data['priceData'],
      productData: data['productData'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'messageType': messageType,
      'isRead': isRead,
      'priceData': priceData,
      'productData': productData,
    };
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<bool> chatExists(String chatId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('chats').doc(chatId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking chat existence: $e');
      return false;
    }
  }

  Future<ChatModel> createChat({
  required String productId,
  required String sellerId,
  required String buyerId,
  required String sellerName,
  required String buyerName,
  required String productTitle,
  required String productImage,
  required String productPrice,
}) async {
  try {
    String chatId = '${productId}_${sellerId}_$buyerId';
    
    // Use set with merge option instead of checking existence
    ChatModel newChat = ChatModel(
      chatId: chatId,
      productId: productId,
      sellerId: sellerId,
      buyerId: buyerId,
      sellerName: sellerName,
      buyerName: buyerName,
      productTitle: productTitle,
      productImage: productImage,
      productPrice: productPrice,
      lastMessage: 'Product shared',
      lastMessageTime: DateTime.now(),
      createdAt: DateTime.now(),
      participants: [sellerId, buyerId],
    );

    // Use merge: true to avoid overwriting existing chats
    await _firestore.collection('chats').doc(chatId).set(
      newChat.toFirestore(), 
      SetOptions(merge: true)
    );

    // Only send product card if this is a new chat
    // Check if there are any messages in this chat
    var messagesSnapshot = await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .limit(1)
        .get();
    
    if (messagesSnapshot.docs.isEmpty) {
      await _sendProductCard(chatId, buyerId, sellerId, {
        'productId': productId,
        'title': productTitle,
        'image': productImage,
        'price': productPrice,
      });
    }

    return newChat;
  } catch (e) {
    throw Exception('Failed to create chat: $e');
  }
}

  Future<void> _sendProductCard(String chatId, String senderId, String receiverId, Map<String, dynamic> productData) async {
    String messageId = DateTime.now().millisecondsSinceEpoch.toString();
    
    MessageModel productMessage = MessageModel(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      message: 'Product shared',
      timestamp: DateTime.now(),
      messageType: 'product_card',
      productData: productData,
    );

    await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set(productMessage.toFirestore());
  }

  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String message,
    String messageType = 'text',
    Map<String, dynamic>? priceData,
  }) async {
    try {
      String messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      MessageModel newMessage = MessageModel(
        messageId: messageId,
        senderId: currentUserId,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
        messageType: messageType,
        priceData: priceData,
      );

      await _firestore
          .collection('messages')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(newMessage.toFirestore());

      // Update last message in chat
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> sendPriceQuote({
    required String chatId,
    required String receiverId,
    required double price,
    required int offerNumber,
  }) async {
    await sendMessage(
      chatId: chatId,
      receiverId: receiverId,
      message: 'Price quoted: ₹${price.toStringAsFixed(0)}',
      messageType: 'price_quote',
      priceData: {
        'price': price,
        'isConfirmed': false,
        'offerNumber': offerNumber,
      },
    );
  }

  Future<void> confirmDeal({
    required String chatId,
    required String receiverId,
    required double finalPrice,
  }) async {
    try {
      // Send deal locked message
      await sendMessage(
        chatId: chatId,
        receiverId: receiverId,
        message: 'Deal locked at ₹${finalPrice.toStringAsFixed(0)}',
        messageType: 'deal_locked',
        priceData: {
          'price': finalPrice,
          'isConfirmed': true,
        },
      );

      // Update chat status
      await _firestore.collection('chats').doc(chatId).update({
        'dealStatus': 'locked',
        'finalPrice': finalPrice,
        'lastMessage': 'Deal locked at ₹${finalPrice.toStringAsFixed(0)}',
        'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      });

      // Send system message for buyer
      String systemMessageId = DateTime.now().millisecondsSinceEpoch.toString() + '_system';
      MessageModel systemMessage = MessageModel(
        messageId: systemMessageId,
        senderId: 'system',
        receiverId: receiverId,
        message: 'Congratulations! Buyer has locked the deal',
        timestamp: DateTime.now(),
        messageType: 'system',
      );

      await _firestore
          .collection('messages')
          .doc(chatId)
          .collection('messages')
          .doc(systemMessageId)
          .set(systemMessage.toFirestore());
    } catch (e) {
      throw Exception('Failed to confirm deal: $e');
    }
  }

  Future<ChatModel?> getChat(String chatId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('chats').doc(chatId).get();
      if (doc.exists) {
        return ChatModel.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting chat: $e');
      return null;
    }
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc.data()))
            .toList());
  }

  Stream<List<ChatModel>> getUserChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromFirestore(doc.data()))
            .toList());
  }

  Future<int> getNextOfferNumber(String chatId) async {
    QuerySnapshot messages = await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .where('messageType', isEqualTo: 'price_quote')
        .get();
    
    return messages.docs.length + 1;
  }
}

// 6. Example usage in your app
/*
// Navigate to product details
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProductDetailsPage(
      productId: 'product_123',
      product: {
        'title': 'Samsung a14 for urgent sale',
        'price': '24000',
        'imageUrl': 'https://example.com/image.jpg',
        'description': 'Lightly used phone in great condition',
        'sellerId': 'seller_123',
        'sellerName': 'Khushi Gupta',
      },
    ),
  ),
);

// Navigate to chat list
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ChatListPage()),
);

// Navigate directly to a chat
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatPage(chatId: 'product123_seller123_buyer123'),
  ),
);
*/