import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';

import 'package:junction/screens/services/chat_service.dart';
import 'productsold.dart';
import 'user_rating.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  
  const ChatPage({Key? key, required this.chatId}) : super(key: key);
  
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // ★ REMOVED: ChatModel? _chatData; (now comes from StreamBuilder)
  // ★ REMOVED: bool _isSeller = false; (now computed in StreamBuilder)
  
  // Upload progress state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  
  // Deal confirmation loading state
  bool _isConfirmingDeal = false;

  @override
  void initState() {
    super.initState();
    // ★ REMOVED: _loadChatData(); (no longer needed)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // ★ UPDATED: All methods now receive chatData as parameter instead of using _chatData
  void _sendMessage(String message, ChatModel chatData) async {
    if (message.trim().isEmpty) return;

    bool isSeller = chatData.sellerId == _chatService.currentUserId;
    String receiverId = isSeller ? chatData.buyerId : chatData.sellerId;

    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        receiverId: receiverId,
        message: message.trim(),
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Widget _buildInputArea(ChatModel chatData) {
  bool isSeller = chatData.sellerId == _chatService.currentUserId;

  if (chatData.dealStatus == 'locked') {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Product has been sold',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  return Column(
    children: [
      // Upload progress indicator
      if (_isUploading) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: _uploadProgress,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _uploadStatus,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      minHeight: 3,
                    ),
                  ],
                ),
              ),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],

      if (chatData.dealStatus == 'confirmed') ...[
        if (isSeller) ...[
          // Seller sees "Mark as Sold" button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isUploading || _isConfirmingDeal) ? null : () => _showMarkAsSoldConfirmation(chatData),
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isUploading || _isConfirmingDeal) 
                    ? Colors.grey 
                    : const Color(0xFF2D2D2D),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isConfirmingDeal
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Mark as Sold',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ] else ...[
          // Buyer sees "Rate the Seller" button when deal is confirmed
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isUploading || _isConfirmingDeal) ? null : () => _navigateToRateSellerScreen(chatData),
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isUploading || _isConfirmingDeal) 
                    ? Colors.grey 
                    : Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isConfirmingDeal
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.star, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Rate the Seller',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ] else if (chatData.dealStatus == 'active') ...[
        // Both users see "Quote Price" button during active negotiation
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isUploading || _isConfirmingDeal) ? null : () => _showQuotePriceBottomSheet(chatData),
            style: ElevatedButton.styleFrom(
              backgroundColor: (_isUploading || _isConfirmingDeal) ? Colors.grey : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Quote Price',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],

      // Message input row
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !_isUploading && !_isConfirmingDeal,
              decoration: InputDecoration(
                hintText: (_isUploading || _isConfirmingDeal) ? 'Processing...' : 'Write a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
              ),
              onSubmitted: (_isUploading || _isConfirmingDeal) ? null : (text) => _sendMessage(text, chatData),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: (_isUploading || _isConfirmingDeal) ? null : () => _showImagePickerBottomSheet(chatData),
            icon: Icon(
              Icons.camera_alt,
              color: (_isUploading || _isConfirmingDeal) ? Colors.grey : Colors.black,
            ),
          ),
          CircleAvatar(
            backgroundColor: (_isUploading || _isConfirmingDeal) ? Colors.grey : Colors.black,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: (_isUploading || _isConfirmingDeal) ? null : () =>
                  _sendMessage(_messageController.text, chatData),
            ),
          ),
        ],
      ),
    ],
  );
}

void _navigateToRateSellerScreen(ChatModel chatData) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => ReviewScreen(
        ratedUserId: chatData.sellerId,    // Buyer rates the seller
        ratedById: chatData.buyerId,       // Rating given by buyer
        fromProductSold: false,            // false because buyer is rating
      ),
    ),
  );
}

  void _showQuotePriceBottomSheet(ChatModel chatData) async {
    final TextEditingController priceController = TextEditingController();
    bool isSeller = chatData.sellerId == _chatService.currentUserId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quote Your Price',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the price you want to offer for this product',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '₹ 23,500',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (priceController.text.isNotEmpty) {
                            double price = double.tryParse(
                              priceController.text.replaceAll(',', ''),
                            ) ?? 0;
                            if (price > 0) {
                              int offerNumber = await _chatService.getNextOfferNumber(widget.chatId);
                              String receiverId = isSeller ? chatData.buyerId : chatData.sellerId;
                              await _chatService.sendPriceQuote(
                                chatId: widget.chatId,
                                receiverId: receiverId,
                                price: price,
                                offerNumber: offerNumber,
                              );
                              Navigator.pop(context);
                              _scrollToBottom();
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Send Quote',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMarkAsSoldConfirmation(ChatModel chatData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) => Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mark as Sold',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will mark the product as sold and complete the transaction.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chatData.productTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Final Price: ₹${chatData.finalPrice?.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buyer: ${chatData.buyerName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isConfirmingDeal ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isConfirmingDeal ? null : () async {
                            setModalState(() {
                              _isConfirmingDeal = true;
                            });
                            setState(() {
                              _isConfirmingDeal = true;
                            });

                            try {
                              await _chatService.markAsSold(
                                chatId: widget.chatId,
                                receiverId: chatData.buyerId,
                                productId: chatData.productId,
                                buyerId: chatData.buyerId,
                                finalPrice: chatData.finalPrice ?? 0,
                              );

                              Navigator.pop(context);
                              _navigateToProductSoldFlow(chatData);

                            } catch (e) {
                              setModalState(() {
                                _isConfirmingDeal = false;
                              });
                              setState(() {
                                _isConfirmingDeal = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to mark as sold: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isConfirmingDeal 
                                ? Colors.grey 
                                : const Color(0xFF2D2D2D),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isConfirmingDeal
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.check, color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Mark as Sold',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (!_isConfirmingDeal) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: Colors.orange[700],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This action cannot be undone. The product will be marked as sold.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToProductSoldFlow(ChatModel chatData) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProductSoldScreen(
          productName: chatData.productTitle,
          ratedUserId: chatData.buyerId,
          ratedById: chatData.sellerId,
          fromProductSold: true,
        ),
      ),
    );

    // Timer(const Duration(seconds: 3), () {
    //   if (mounted) {
    //     Navigator.pushReplacement(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => ReviewScreen(
    //           ratedUserId: chatData.buyerId,
    //           ratedById: chatData.sellerId,
    //           fromProductSold: true,
    //         ),
    //       ),
    //     );
    //   }
    // });
  }

  void _showImagePickerBottomSheet(ChatModel chatData) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Image',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImageSourceButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera, chatData),
              ),
              _buildImageSourceButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () => _pickImage(ImageSource.gallery, chatData),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

Widget _buildImageSourceButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            icon,
            size: 30,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    ),
  );
}

void _pickImage(ImageSource source, ChatModel chatData) async {
  Navigator.pop(context);
  
  final bool isSeller = chatData.sellerId == _chatService.currentUserId;
  String receiverId = isSeller ? chatData.buyerId : chatData.sellerId;

  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sending image...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
    
    await _chatService.pickAndSendImage(
      chatId: widget.chatId,
      receiverId: receiverId,
      source: source,
    );
    
    Navigator.pop(context);
    _scrollToBottom();
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send image: $e')),
    );
  }
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

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) {
      return DateFormat('dd/MM').format(time);
    } else {
      return DateFormat('HH:mm').format(time);
    }
  }

  // ★ MAIN BUILD METHOD: Using StreamBuilder for real-time updates
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatModel?>(
      stream: _chatService.getChatStream(widget.chatId),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (chatSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: ${chatSnapshot.error}')),
          );
        }

        if (!chatSnapshot.hasData || chatSnapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat not found')),
            body: const Center(child: Text('Chat not found')),
          );
        }

        final ChatModel chatData = chatSnapshot.data!;
        final bool isSeller = chatData.sellerId == _chatService.currentUserId;
        final String otherUserName = isSeller ? chatData.buyerName : chatData.sellerName;
        
        // Safe initials generation
        String initials = otherUserName.trim().split(' ')
            .where((name) => name.isNotEmpty)
            .take(2)
            .map((name) => name[0])
            .join()
            .toUpperCase();

        if (initials.isEmpty) {
          initials = otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U';
        }

        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple,
                  radius: 16,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  otherUserName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: _chatService.getMessages(widget.chatId),
                    builder: (context, messageSnapshot) {
                      if (messageSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (messageSnapshot.hasError) {
                        return Center(child: Text('Error: ${messageSnapshot.error}'));
                      }
                      List<MessageModel> messages = messageSnapshot.data ?? [];
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          MessageModel message = messages[index];
                          return _buildMessage(message, chatData);
                        },
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: SafeArea(
                    minimum: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildInputArea(chatData), // ★ Automatically updates when chatData changes
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ★ UPDATED: Message builder now receives chatData
  Widget _buildMessage(MessageModel message, ChatModel chatData) {
    bool isMe = message.senderId == _chatService.currentUserId;
    switch (message.messageType) {
      case 'product_card':
        return _buildProductCard(message);
      case 'price_quote':
        return _buildPriceQuoteMessage(message, isMe, chatData);
      case 'deal_locked':
        return _buildDealLockedMessage(message, isMe);
      case 'system':
        return _buildSystemMessage(message);
      case 'image':
        return _buildImageMessage(message, isMe);
      default:
        return _buildRegularMessage(message, isMe, chatData);
    }
  }

  // ★ UPDATED: Message builders now receive chatData parameter
  Widget _buildPriceQuoteMessage(MessageModel message, bool isMe, ChatModel chatData) {
    final priceData = message.priceData;
    if (priceData == null) return const SizedBox();

    double price = priceData['price']?.toDouble() ?? 0;
    int offerNumber = priceData['offerNumber'] ?? 1;
    bool isConfirmed = priceData['isConfirmed'] ?? false;
    String quotedBy = priceData['quotedBy'] ?? '';

    String quoteAuthor;
    if (quotedBy == chatData.sellerId) {
      quoteAuthor = chatData.sellerName;
    } else {
      quoteAuthor = chatData.buyerName;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Text(
              quoteAuthor,
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple[300],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.black : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Offer $offerNumber by $quoteAuthor',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                if (!isMe && !isConfirmed && chatData.dealStatus == 'active') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isConfirmingDeal ? null : () => _showConfirmPriceBottomSheet(price, chatData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isConfirmingDeal ? Colors.grey : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isConfirmingDeal
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Confirm',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

void _showConfirmPriceBottomSheet(double price, ChatModel chatData) {
  final TextEditingController priceController = TextEditingController(
    text: price.toStringAsFixed(0),
  );
  bool isSeller = chatData.sellerId == _chatService.currentUserId;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirm Deal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lock this deal at the final price',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  enabled: !_isConfirmingDeal,
                  decoration: InputDecoration(
                    hintText: '₹ 23,000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isConfirmingDeal ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isConfirmingDeal ? null : () async {
                          if (priceController.text.isNotEmpty) {
                            setModalState(() {
                              _isConfirmingDeal = true;
                            });
                            setState(() {
                              _isConfirmingDeal = true;
                            });

                            try {
                              double finalPrice = double.tryParse(
                                priceController.text.replaceAll(',', ''),
                              ) ?? price;
                              String receiverId = isSeller ? chatData.buyerId : chatData.sellerId;

                              await _chatService.confirmDeal(
                                chatId: widget.chatId,
                                receiverId: receiverId,
                                finalPrice: finalPrice,
                                productId: chatData.productId,
                                buyerId: chatData.buyerId,
                              );

                              // Reset loading state
                              _isConfirmingDeal = false;
                              setModalState(() {});
                              setState(() {});

                              Navigator.pop(context);
                              _scrollToBottom();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Deal confirmed successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                            } catch (e) {
                              setModalState(() {
                                _isConfirmingDeal = false;
                              });
                              setState(() {
                                _isConfirmingDeal = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to confirm deal: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isConfirmingDeal ? Colors.grey : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isConfirmingDeal
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Lock Deal',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
                if (!_isConfirmingDeal) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This will lock the deal and mark the product as sold',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  void _navigateBuyerToReviewScreen(ChatModel chatData) {
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewScreen(
              ratedUserId: chatData.sellerId,
              ratedById: chatData.buyerId,
              fromProductSold: false,
            ),
          ),
        );
      }
    });
  }

  // Existing message builders with chatData parameter
  Widget _buildRegularMessage(MessageModel message, bool isMe, ChatModel chatData) {
    bool isSeller = chatData.sellerId == _chatService.currentUserId;
    String otherUserName = isSeller ? chatData.buyerName : chatData.sellerName;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Text(
              otherUserName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple[300],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isMe ? Colors.black : Colors.grey[300],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                _formatMessageTime(message.timestamp),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all,
                  size: 12,
                  color: Colors.grey,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(MessageModel message) {
    final productData = message.productData;
    if (productData == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  productData['image'] ?? '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Electronics',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      productData['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${productData['price']}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
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

  Widget _buildImageMessage(MessageModel message, bool isMe) {
    final attachmentData = message.attachmentData;
    if (attachmentData == null) return const SizedBox();

    String imageUrl = attachmentData['url'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () => _showFullScreenImage(imageUrl),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                _formatMessageTime(message.timestamp),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all,
                  size: 12,
                  color: Colors.grey,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(MessageModel message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.message,
              style: TextStyle(
                color: Colors.green[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealLockedMessage(MessageModel message, bool isMe) {
    final priceData = message.priceData;
    if (priceData == null) return const SizedBox();

    double price = priceData['price']?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Deal Locked',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatMessageTime(message.timestamp),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 50),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}