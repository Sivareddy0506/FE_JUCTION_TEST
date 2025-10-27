import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:junction/screens/services/chat_service.dart';
import 'productsold.dart';
import 'user_rating.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  
  const ChatPage({super.key, required this.chatId});
  
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late FocusNode _messageFocusNode;
  
  // Upload progress state
  final bool _isUploading = false;
  final double _uploadProgress = 0.0;
  final String _uploadStatus = '';
  
  // Deal confirmation loading state
  bool _isConfirmingDeal = false;
  
  // Image upload state
  bool _isImageUploading = false;
  double _imageUploadProgress = 0.0;
  String _imageUploadStatus = '';
  
  // Cache for chat data to avoid repeated fetches
  ChatModel? _cachedChatData;
  
  // Track message count to detect new messages
  int _previousMessageCount = 0;
  
  // Track if we've done initial scroll to prevent repeated scrolling
  bool _hasDoneInitialScroll = false;
  
  // Track if user is typing to prevent auto-scroll
  bool _isUserTyping = false;
  
  // Track current scroll position to prevent jumps
  double _currentScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _messageFocusNode = FocusNode();
    
    // Track when user is typing
    _messageController.addListener(() {
      _isUserTyping = _messageController.text.isNotEmpty;
    });
    
    // Track scroll position to prevent jumps
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        _currentScrollPosition = _scrollController.position.pixels;
      }
    });
    
    // Initial scroll to bottom when chat is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
    
    // Scroll to bottom when input gains focus to show latest messages above keyboard
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        // Add a small delay to ensure keyboard animation completes
        Future.delayed(const Duration(milliseconds: 200), () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              // Add extra padding to account for keyboard height
              final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
              final targetPosition = _scrollController.position.maxScrollExtent + (keyboardHeight * 0.5);
              _scrollController.animateTo(
                targetPosition,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        });
      }
    });
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    // Reset flags when disposing
    _hasDoneInitialScroll = false;
    _isUserTyping = false;
    _currentScrollPosition = 0.0;
    super.dispose();
  }

  // Static method that doesn't depend on chatData parameter
  void _sendMessageStatic(String message) async {
    if (message.trim().isEmpty) return;

    // Store the message before clearing
    final messageText = message.trim();
    
    // Clear the controller immediately to provide instant feedback
    _messageController.clear();
    
    // Reset typing flag
    _isUserTyping = false;
    
    // Maintain focus after clearing with a small delay
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_messageFocusNode.canRequestFocus) {
        _messageFocusNode.requestFocus();
      }
    });

    try {
      // Get current chat data once
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();
      
      if (!chatDoc.exists) return;
      
      final chatData = ChatModel.fromFirestore(chatDoc.data()!);
      bool isSeller = chatData.sellerId == _chatService.currentUserId;
      String receiverId = isSeller ? chatData.buyerId : chatData.sellerId;

      await _chatService.sendMessage(
        chatId: widget.chatId,
        receiverId: receiverId,
        message: messageText,
      );
      
      // Scroll to bottom after message is sent - this will be handled by the message count logic
      // No need for additional scrolling here
    } catch (e) {
      // Restore the message if sending failed
      _messageController.text = messageText;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _showImagePickerBottomSheetStatic() async {
    try {
      // Get current chat data once
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();
      
      if (!chatDoc.exists) return;
      
      final chatData = ChatModel.fromFirestore(chatDoc.data()!);
      _showImagePickerBottomSheet(chatData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open image picker: $e')),
      );
    }
  }

  Widget _buildPureInputArea() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey[300]!)),
    ),
    child: SafeArea(
      minimum: const EdgeInsets.only(bottom: 0), // Remove minimum bottom padding
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 16, // No bottom padding when keyboard is visible
        ),
        child: Column(
          children: [
            // Upload progress indicator (if uploading)
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
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    enabled: !_isUploading && !_isConfirmingDeal && !_isImageUploading,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null, // Allow multiple lines
                    minLines: 1, // Start with single line
                    decoration: InputDecoration(
                      hintText: (_isUploading || _isConfirmingDeal || _isImageUploading) 
                          ? 'Processing...' 
                          : 'Write a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: (_isUploading || _isConfirmingDeal || _isImageUploading) 
                        ? null 
                        : (text) {
                            if (text.trim().isNotEmpty) {
                              _sendMessageStatic(text);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: (_isUploading || _isConfirmingDeal || _isImageUploading) 
                      ? null 
                      : _showImagePickerBottomSheetStatic,
                  icon: Icon(
                    Icons.camera_alt_rounded,
                    color: (_isUploading || _isConfirmingDeal || _isImageUploading) 
                        ? Colors.grey 
                        : Colors.black,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: (_isUploading || _isConfirmingDeal || _isImageUploading) 
                      ? Colors.grey 
                      : Colors.black,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: (_isUploading || _isConfirmingDeal || _isImageUploading) 
                        ? null 
                        : () => _sendMessageStatic(_messageController.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildActionButtonsArea(ChatModel chatData) {
  bool isSeller = chatData.sellerId == _chatService.currentUserId;
  
  // Show "product sold" message if deal is locked
  if (chatData.dealStatus == 'locked') {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Container(
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
      ),
    );
  }
  
  // Don't show action buttons if no special status
  if (chatData.dealStatus != 'confirmed' && chatData.dealStatus != 'active') {
    return const SizedBox.shrink();
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      border: Border(
        top: BorderSide(color: Colors.grey[200]!),
        bottom: BorderSide(color: Colors.grey[200]!),
      ),
    ),
    child: Column(
      children: [
        if (chatData.dealStatus == 'confirmed') ...[
          if (isSeller) ...[
            // Seller sees both "Cancel Deal" and "Mark as Sold" buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_isUploading || _isConfirmingDeal) 
                        ? null 
                        : () => _showCancelDealConfirmation(chatData),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      side: BorderSide(
                        color: (_isUploading || _isConfirmingDeal) 
                            ? Colors.grey[300]! 
                            : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Cancel Deal',
                      style: TextStyle(
                        color: (_isUploading || _isConfirmingDeal) 
                            ? Colors.grey 
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isUploading || _isConfirmingDeal) 
                        ? null 
                        : () => _showMarkAsSoldConfirmation(chatData, chatData.orderId ?? ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_isUploading || _isConfirmingDeal) 
                          ? Colors.grey 
                          : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
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
                        : const Text(
                            'Mark as Sold',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Buyer sees "Rate the Seller" button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isUploading || _isConfirmingDeal) 
                    ? null 
                    : () => _navigateToRateSellerScreen(chatData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isUploading || _isConfirmingDeal) 
                      ? Colors.grey 
                      : const Color(0xFFFF6705),

                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Row(
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
        ] else if (chatData.dealStatus == 'active') ...[
          // Both users see "Quote Price" button during active negotiation
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isUploading || _isConfirmingDeal) 
                  ? null 
                  : () => _showQuotePriceBottomSheet(chatData),
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isUploading || _isConfirmingDeal) 
                    ? Colors.grey 
                    : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Quote Price',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

void _showCancelDealConfirmation(ChatModel chatData) {
  // Check if orderId exists
  if (chatData.orderId == null || chatData.orderId!.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cannot cancel: Order ID not found'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            bool isCanceling = false;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cancel Deal?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This will cancel the confirmed deal and return to negotiation.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
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
                        'Locked Price: ₹${chatData.finalPrice?.toStringAsFixed(0) ?? '0'}',
                        style: const TextStyle(
                          color: const Color(0xFFFF6705),

                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order ID: ${chatData.orderId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The deal will return to active negotiation. You can quote a new price.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isCanceling ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Keep Deal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isCanceling ? null : () async {
                          setModalState(() {
                            isCanceling = true;
                          });

                          try {
                            // Call API to cancel deal
                            bool cancelled = await ChatService.cancelDeal(
                              orderId: chatData.orderId!,
                            );

                            if (cancelled) {
                              // Update Firestore - reset to active status
                              await FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(widget.chatId)
                                  .update({
                                'dealStatus': 'active',
                                'finalPrice': null,
                                'orderId': null,
                                'lastMessage': 'Deal cancelled, negotiation resumed',
                                'lastMessageTime': Timestamp.fromDate(DateTime.now()),
                              });

                              // Send system message
                              String systemMessageId = '${DateTime.now().millisecondsSinceEpoch}_cancel';
                              await FirebaseFirestore.instance
                                  .collection('messages')
                                  .doc(widget.chatId)
                                  .collection('messages')
                                  .doc(systemMessageId)
                                  .set({
                                'messageId': systemMessageId,
                                'senderId': 'system',
                                'receiverId': chatData.buyerId,
                                'message': 'Deal has been cancelled by seller. You can continue negotiating.',
                                'timestamp': Timestamp.fromDate(DateTime.now()),
                                'messageType': 'system',
                                'isRead': false,
                              });

                              Navigator.pop(context);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Deal cancelled successfully'),
                                    ],
                                  ),
                                 backgroundColor: const Color(0xFFFF6705),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }

                          } catch (e) {
                            setModalState(() {
                              isCanceling = false;
                            });

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Failed to cancel deal: $e')),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCanceling ? Colors.grey : Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: isCanceling
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Cancel Deal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

  Widget _buildAppBarTitle(ChatModel chatData) {
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

    return Row(
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
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: Colors.white,
    resizeToAvoidBottomInset: true,
    // AppBar with its own StreamBuilder for user info only
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: _cachedChatData != null 
        ? _buildAppBarTitle(_cachedChatData!)
        : StreamBuilder<ChatModel?>(
            stream: _chatService.getChatStream(widget.chatId),
            builder: (context, chatSnapshot) {
              if (!chatSnapshot.hasData) {
                return const Text('Loading...');
              }
              
              _cachedChatData = chatSnapshot.data!;
              return _buildAppBarTitle(chatSnapshot.data!);
            },
          ),
    ),
    body: SafeArea(
      child: Column(
          children: [
            // Messages area with its own StreamBuilder
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessages(widget.chatId),
                builder: (context, messageSnapshot) {
                  // Remove loading state to prevent scroll jumps
                  // if (messageSnapshot.connectionState == ConnectionState.waiting) {
                  //   return const Center(child: CircularProgressIndicator());
                  // }
                  if (messageSnapshot.hasError) {
                    return Center(child: Text('Error: ${messageSnapshot.error}'));
                  }
                
                List<MessageModel> messages = messageSnapshot.data ?? [];
                
                // Scroll to bottom on initial load and when returning to chat
                if (messages.isNotEmpty && _previousMessageCount == 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                    }
                  });
                }
                
                // Preserve scroll position only if user is actively scrolling (not when input gains focus)
                if (_isUserTyping && _currentScrollPosition > 0 && !_messageFocusNode.hasFocus) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(_currentScrollPosition);
                    }
                  });
                }
                
                // Only scroll to bottom if new messages were added (not on initial load) and user is not typing
                if (messages.length > _previousMessageCount && _previousMessageCount > 0 && !_isUserTyping) {
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
                _previousMessageCount = messages.length;
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    MessageModel message = messages[index];
                    // Use cached chat data if available, otherwise fetch it
                    if (_cachedChatData != null) {
                      return _buildMessage(message, _cachedChatData!);
                    } else {
                      return FutureBuilder<ChatModel?>(
                        future: _getChatDataOnce(),
                        builder: (context, chatSnapshot) {
                          if (!chatSnapshot.hasData) return const SizedBox();
                          _cachedChatData = chatSnapshot.data!;
                          return _buildMessage(message, chatSnapshot.data!);
                        },
                      );
                    }
                  },
                );
              },
            ),
          ),
          
          // Action buttons area - use cached data to avoid rebuilds
          if (_cachedChatData != null)
            _buildActionButtonsArea(_cachedChatData!)
          else
            StreamBuilder<ChatModel?>(
              stream: _chatService.getChatStream(widget.chatId),
              builder: (context, chatSnapshot) {
                if (!chatSnapshot.hasData) return const SizedBox.shrink();
                _cachedChatData = chatSnapshot.data!;
                return _buildActionButtonsArea(chatSnapshot.data!);
              },
            ),
          
          // Input area - COMPLETELY STATIC, no StreamBuilder dependency
          _buildPureInputArea(),
        ],
      ),
    ),
  );
}

Future<ChatModel?> _getChatDataOnce() async {
  try {
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();
    
    if (!chatDoc.exists) return null;
    return ChatModel.fromFirestore(chatDoc.data()!);
  } catch (e) {
    return null;
  }
}


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

void _navigateToRateSellerScreen(ChatModel chatData) {
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
                  hintText: 'Enter Final Price',
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
}

void _showImagePickerBottomSheet(ChatModel chatData) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to add a photo',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildImageSourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () => _handleImageSelection(ImageSource.camera, chatData),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageSourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () => _handleImageSelection(ImageSource.gallery, chatData),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildImageSourceOption({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    ),
  );
}

void _handleImageSelection(ImageSource source, ChatModel chatData) async {
  Navigator.pop(context);
  
  final bool isSeller = chatData.sellerId == _chatService.currentUserId;
  String receiverId = isSeller ? chatData.buyerId : chatData.sellerId;

  // Set initial upload state
  setState(() {
    _isImageUploading = true;
    _imageUploadProgress = 0.0;
    _imageUploadStatus = 'Selecting image...';
  });

  try {
    _showImageUploadOverlay();
    
    await _chatService.pickAndSendImageWithProgress(
      chatId: widget.chatId,
      receiverId: receiverId,
      source: source,
      onUploadStart: (status) {
        setState(() {
          _imageUploadStatus = status;
          _imageUploadProgress = 0.0;
        });
      },
      onUploadProgress: (progress) {
        setState(() {
          _imageUploadProgress = progress;
          _imageUploadStatus = 'Uploading... ${(progress * 100).toInt()}%';
        });
      },
      onUploadComplete: () {
        setState(() {
          _isImageUploading = false;
          _imageUploadProgress = 1.0;
          _imageUploadStatus = 'Upload complete';
        });
        Navigator.of(context, rootNavigator: true).pop(); // Close overlay
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Photo sent successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onError: (error) {
        setState(() {
          _isImageUploading = false;
          _imageUploadProgress = 0.0;
          _imageUploadStatus = '';
        });
        Navigator.of(context, rootNavigator: true).pop(); // Close overlay
        
        // Show error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to send photo: $error')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  } catch (e) {
    setState(() {
      _isImageUploading = false;
      _imageUploadProgress = 0.0;
      _imageUploadStatus = '';
    });
    Navigator.of(context, rootNavigator: true).pop(); // Close overlay if still open
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Failed to send image: $e')),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

void _showImageUploadOverlay() {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: StreamBuilder<int>(
          stream: Stream.periodic(const Duration(milliseconds: 100), (i) => i),
          builder: (context, snapshot) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: _imageUploadProgress,
                          strokeWidth: 4,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      ),
                      Text(
                        '${(_imageUploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    _imageUploadStatus,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Please wait while image is uploading...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

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
                   onPressed: _isConfirmingDeal ? null : () => _showConfirmPriceBottomSheet(chatData, price),
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

Future<void> _showConfirmPriceBottomSheet(ChatModel chatData, double price) async { 

  final TextEditingController priceController =
      TextEditingController(text: price.toStringAsFixed(0));
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
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm Deal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Lock this deal at the final price',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                enabled: !_isConfirmingDeal,
                decoration: InputDecoration(
                  hintText: 'Enter Final Price',
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
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isConfirmingDeal
                          ? null
                          : () async {
                              if (priceController.text.isEmpty) return;

                              setModalState(() => _isConfirmingDeal = true);
                              setState(() => _isConfirmingDeal = true);

                              double finalPrice =
                                  double.tryParse(priceController.text.replaceAll(',', '')) ??
                                      price;
                              String receiverId =
                                  isSeller ? chatData.buyerId : chatData.sellerId;

                              try {
                                // Lock deal and get orderId
                                String orderId = await ChatService.lockDeal(
                                  productId: chatData.productId,
                                  buyerId: chatData.buyerId,
                                  finalPrice: finalPrice,
                                );

                                chatData.finalPrice = finalPrice;
                                if (orderId.isNotEmpty) {
                                  chatData.orderId = orderId;
                                  // After locking deal, update Firestore
                                  await _chatService.confirmDeal(
                                    chatId: chatData.chatId,
                                    receiverId: receiverId,
                                    finalPrice: finalPrice,
                                    productId: chatData.productId,
                                    buyerId: chatData.buyerId,
                                    orderId: orderId,
                                  );

                                  // Close price sheet
                                  Navigator.pop(context);

                                  // Open Mark as Sold
                                  _showMarkAsSoldConfirmation(chatData, orderId);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Deal confirmed successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                Navigator.pop(context);
                                setModalState(() => _isConfirmingDeal = false);
                                setState(() => _isConfirmingDeal = false);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to confirm deal: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isConfirmingDeal ? Colors.grey : Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
                          : const Text('Lock Deal', style: TextStyle(color: Colors.white)),
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

void _showMarkAsSoldConfirmation(ChatModel chatData, String orderId) {
  bool isSeller = chatData.sellerId == _chatService.currentUserId;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mark as Sold',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to mark this product as sold?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isConfirmingDeal = false;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() => _isConfirmingDeal = true);

                      try {
                        await _chatService.markAsSold(
                          chatId: chatData.chatId,
                          receiverId: isSeller ? chatData.buyerId : chatData.sellerId,
                          productId: chatData.productId,
                          buyerId: chatData.buyerId,
                          finalPrice: chatData.finalPrice ?? 0,
                          orderId: orderId,
                        );

                        setState(() => _isConfirmingDeal = false);

                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(
                        //     content: Text('Product marked as sold!'),
                        //     backgroundColor: Colors.green,
                        //   ),
                        // );

                        _navigateToProductSoldFlow(chatData);
                      } catch (e) {
                        setState(() => _isConfirmingDeal = false);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to mark as sold: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Mark as Sold'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}





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
                    '${productData['price']}',
                    style: const TextStyle(
                      color: const Color(0xFFFF6705),

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
}