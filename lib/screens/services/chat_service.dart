import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'backend_file_upload_service';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/image_compression.dart';

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
  String? orderId; // Nullable orderId
  final String lastMessage;
  final DateTime lastMessageTime;
  final DateTime createdAt;
  final String dealStatus;
  double? finalPrice;
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
    this.orderId, // Nullable orderId
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
      orderId: data['orderId'], // Nullable orderId
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
      'orderId': orderId, // Nullable orderId
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
  final Map<String, dynamic>? attachmentData;

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
    this.attachmentData
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
      attachmentData: data['attachmentData'],
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
      'attachmentData': attachmentData,
    };
  }
}

class AttachmentModel {
  final String url;
  final String type; // 'image', 'video', 'document'
  final String fileName;
  final int size;
  final int? width;
  final int? height;
  final String? thumbnailUrl;
  
  AttachmentModel({
    required this.url,
    required this.type,
    required this.fileName,
    required this.size,
    this.width,
    this.height,
    this.thumbnailUrl,
  });
  
  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      url: map['url'] ?? '',
      type: map['type'] ?? '',
      fileName: map['fileName'] ?? '',
      size: map['size'] ?? 0,
      width: map['width'],
      height: map['height'],
      thumbnailUrl: map['thumbnailUrl'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type,
      'fileName': fileName,
      'size': size,
      'width': width,
      'height': height,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();

  String get currentUserId => _auth.currentUser?.uid ?? '';
  String orderId = '';

  Future<bool> chatExists(String chatId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('chats').doc(chatId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking chat existence: $e');
      return false;
    }
  }

Stream<ChatModel?> getChatStream(String chatId) {
  return _firestore
      .collection('chats')
      .doc(chatId)
      .snapshots()
      .map((doc) {
        if (doc.exists && doc.data() != null) {
          return ChatModel.fromFirestore(doc.data() as Map<String, dynamic>);
        }
        return null;
      });
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

  Future<Map<String, dynamic>> _uploadImageToBackend({
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      final String fileName = path.basename(imageFile.path);
      final int fileSize = await imageFile.length();
      
      // Upload file to backend
      final String s3Url = await BackendFileUploadService.uploadFile(
        file: imageFile,
        onProgress: onProgress,
      );
      
      return {
        'url': s3Url,
        'type': 'image',
        'fileName': fileName,
        'size': fileSize,
      };
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  
  // Enhanced image picker and sender with backend upload
  Future<void> pickAndSendImage({
    required String chatId,
    required String receiverId,
    required ImageSource source,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 100, // Pick at full quality, we'll compress later
      );
      
      if (pickedFile != null) {
        // Compress image to ensure it's under 5MB
        File? compressedFile = await ImageCompression.compressImageToFit(pickedFile.path);
        
        if (compressedFile == null) {
          throw Exception('Failed to process image. Please try again.');
        }
        
        // Upload image to backend
        final Map<String, dynamic> attachmentData = await _uploadImageToBackend(
          imageFile: compressedFile,
          onProgress: (progress) {
            print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
          },
        );
        
        // Send image message
        await sendMessage(
          chatId: chatId,
          receiverId: receiverId,
          message: 'Photo',
          messageType: 'image',
          attachmentData: attachmentData,
        );
      }
    } catch (e) {
      throw Exception('Failed to send image: $e');
    }
  }
  
  // Enhanced version with progress callbacks for UI
  Future<void> pickAndSendImageWithProgress({
    required String chatId,
    required String receiverId,
    required ImageSource source,
    required Function(String) onUploadStart,
    required Function(double) onUploadProgress,
    required Function() onUploadComplete,
    required Function(String) onError,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 100, // Pick at full quality, we'll compress later
      );
      
      if (pickedFile != null) {
        onUploadStart('Compressing image...');
        
        // Compress image to ensure it's under 5MB
        File? compressedFile = await ImageCompression.compressImageToFit(pickedFile.path);
        
        if (compressedFile == null) {
          onError('Failed to process image. Please try again.');
          return;
        }
        
        onUploadStart('Uploading image...');
        
        // Upload image with progress tracking
        final Map<String, dynamic> attachmentData = await _uploadImageToBackend(
          imageFile: compressedFile,
          onProgress: onUploadProgress,
        );
        
        // Send image message
        await sendMessage(
          chatId: chatId,
          receiverId: receiverId,
          message: 'Photo',
          messageType: 'image',
          attachmentData: attachmentData,
        );
        
        onUploadComplete();
      }
    } catch (e) {
      onError('Failed to send image: $e');
    }
  }

  // Generic file upload method for future use (documents, videos, etc.)
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String fileType, // 'image', 'document', 'video', etc.
    Function(double)? onProgress,
  }) async {
    try {
      File? fileToUpload = file;
      
      // Only compress images, not documents or videos
      if (fileType == 'image') {
        fileToUpload = await ImageCompression.compressImageToFit(file.path);
        if (fileToUpload == null) {
          throw Exception('Failed to compress image. Please try again.');
        }
      } else {
        // For non-image files, check size
        final fileSize = await file.length();
        if (fileSize > ImageCompression.maxFileSize) {
          throw Exception('File size (${ImageCompression.formatFileSize(fileSize)}) exceeds 5MB limit. Please select a smaller file.');
        }
      }
      
      final String fileName = path.basename(fileToUpload.path);
      final int fileSize = await fileToUpload.length();
      
      final String s3Url = await BackendFileUploadService.uploadFile(
        file: fileToUpload,
        onProgress: onProgress,
      );
      
      return {
        'url': s3Url,
        'type': fileType,
        'fileName': fileName,
        'size': fileSize,
      };
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
  
  // Send regular message
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String message,
    String messageType = 'text',
    Map<String, dynamic>? priceData,
    Map<String, dynamic>? attachmentData,
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
        attachmentData: attachmentData,
      );

      await _firestore
          .collection('messages')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(newMessage.toFirestore());

      // Update last message in chat
      String lastMessageText = messageType == 'image' ? '📷 Photo' : message;
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': lastMessageText,
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
        'quotedBy': currentUserId,  // Track who made the quote
      },
    );
  }
Future<String> confirmDeal({
  required String chatId,
  required String receiverId,
  required double finalPrice,
  required String productId,
  required String buyerId,
  required String orderId,
}) async {
  try {
    // Call API and get orderId
    // final String orderId = await _callConfirmDealAPI(
    //   productId: productId,
    //   buyerId: buyerId,
    //   finalPrice: finalPrice,
    // );

    // Send deal locked message
    await sendMessage(
      chatId: chatId,
      receiverId: receiverId,
      message: 'Deal has been locked for ₹${finalPrice.toStringAsFixed(0)}',
      messageType: 'deal_locked',
      priceData: {
        'price': finalPrice,
        'isConfirmed': true,
        'confirmedBy': currentUserId,
      },
    );

    // Update chat
    await _firestore.collection('chats').doc(chatId).update({
      'dealStatus': 'confirmed',
      'finalPrice': finalPrice,
      'lastMessage': 'Deal confirmed at ₹${finalPrice.toStringAsFixed(0)}',
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      'orderId': orderId, // store orderId
    });

    return orderId; // ✅ Return orderId
  } catch (e) {
    throw Exception('Failed to confirm deal: $e');
  }
}

Future<String> _callConfirmDealAPI({
  required String productId,
  required String buyerId,
  required double finalPrice,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');

    final response = await http.post(
      Uri.parse('https://api.junctionverse.com/product/deal-lock'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'productId': productId,
        'buyerId': buyerId,
        'finalPrice': finalPrice,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['orderId']; // ✅ Return orderId from API response
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        'Failed to confirm deal: ${response.statusCode} - ${errorData['error'] ?? 'Unknown error'}'
      );
    }
  } catch (e) {
    throw Exception('API call failed: $e');
  }
}

static Future<bool> cancelDeal({
  required String orderId,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');

    final response = await http.post(
      Uri.parse('https://api.junctionverse.com/product/cancel-deal'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'orderId': orderId,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        'Failed to cancel deal: ${response.statusCode} - ${errorData['error'] ?? 'Unknown error'}'
      );
    }
  } catch (e) {
    throw Exception('API call failed: $e');
  }
}

Future<void> cancelDealInChat(String chatId) async {
  try {
    await _firestore.collection('chats').doc(chatId).update({
      'dealStatus': 'cancelled',
      'lastMessage': 'Deal has been cancelled',
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
    });
  } catch (e) {
    throw Exception('Failed to cancel deal in chat: $e');
  }
}


Future<void> markAsSold({
  required String chatId,
  required String receiverId,
  required String productId,
  required String buyerId,
  required double finalPrice,
  String? orderId, // nullable
}) async {
  try {
    await markProductAsSold(
      productId: productId,
      buyerId: buyerId,
      orderId: orderId, // pass nullable
    );

    await _firestore.collection('chats').doc(chatId).update({
      'dealStatus': 'sold', // ★ FINAL STATUS: product sold
      'lastMessage': 'Product marked as sold',
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
    });

    String systemMessageId = '${DateTime.now().millisecondsSinceEpoch}_sold';
    MessageModel systemMessage = MessageModel(
      messageId: systemMessageId,
      senderId: 'system',
      receiverId: receiverId,
      message: 'Product has been marked as sold. Transaction completed!',
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
    throw Exception('Failed to mark product as sold: $e');
  }
}

static Future<bool> markProductAsSold({
  required String productId,
  required String buyerId,
  String? orderId, // ✅ Added orderId
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');

    // Determine if sold inside Junction (has orderId) or outside
    final bool soldInJunction = orderId != null && orderId.isNotEmpty;
    
    final response = await http.post(
      Uri.parse('https://api.junctionverse.com/product/mark-sold'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        if (soldInJunction) 'orderId': orderId,
        if (!soldInJunction) 'productId': productId,
        'soldInJunction': soldInJunction,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception('Failed to mark product as sold: ${response.statusCode} - ${errorData['error'] ?? errorData['message'] ?? 'Unknown error'}');
    }
  } catch (e) {
    throw Exception('API call failed: $e');
  }
}

static Future<String> lockDeal({
  required String productId,
  required String buyerId,
  required double finalPrice,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');

    final response = await http.post(
      Uri.parse('https://api.junctionverse.com/product/deal-lock'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'productId': productId,
        'buyerId': buyerId,       // ✅ required
        'finalPrice': finalPrice,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['order']['orderId'];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to lock deal: ${response.statusCode} - ${errorData['error'] ?? 'Unknown error'}');
    }
  } catch (e) {
    throw Exception('API call failed: $e');
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

  // Mark all unread messages as read when chat is opened
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      // Get all unread messages where current user is the receiver
      final unreadMessages = await _firestore
          .collection('messages')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      // Batch update all unread messages
      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}

// 6. Example usage in your app
/*
// Navigate to product details
Navigator.push(
  context,
  SlidePageRoute(
    page: ProductDetailsPage(
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
  SlidePageRoute(page: ChatListPage()),
);

// Navigate directly to a chat
Navigator.push(
  context,
  SlidePageRoute(
    page: ChatPage(chatId: 'product123_seller123_buyer123'),
  ),
);
*/