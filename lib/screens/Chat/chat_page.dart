import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/form_text.dart';
import '../../widgets/app_button.dart';

import 'package:junction/screens/services/chat_service.dart';
import 'productsold.dart';
import 'user_rating.dart';
import '../../app.dart';
import '../profile/user_profile.dart';
import '../profile/others_profile.dart';
import '../../utils/error_handler.dart';

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
  
  // Button disabling and error handling
  final bool _isConfirmButtonDisabled = false;
  Timer? _confirmButtonTimer;
  String? _errorMessage;
  DateTime? _nextQuoteAllowedAt;
  
  // Track if user is typing to prevent auto-scroll
  bool _isUserTyping = false;
  
  // Track current scroll position to prevent jumps
  double _currentScrollPosition = 0.0;
  
  // Product status
  String? _productStatus;
  Timer? _statusPollingTimer; // Timer for polling product status
  DateTime? _pollingStartTime; // Track when polling started
  String? _lastFetchedProductId; // Track last fetched productId to prevent redundant calls
  bool _isFetchingProductStatus = false; // Prevent concurrent fetches
  
  // Report user state
  static const List<Map<String, String>> _reportReasonOptions = [
    {'code': 'SCAM', 'label': 'Scam / Fraud'},
    {'code': 'SPAM', 'label': 'Spam'},
    {'code': 'INAPPROPRIATE', 'label': 'Inappropriate behavior'},
    {'code': 'MISLEADING', 'label': 'Misleading information'},
    {'code': 'OTHER', 'label': 'Other'},
  ];
  String? _selectedReportReasonCode;
  final TextEditingController _reportNotesController = TextEditingController();
  bool _isSubmittingReport = false;
  bool _isChatBlocked = false; // Track if chat is blocked after reporting
  Timer? _blockStatusPollingTimer; // Timer for polling block status
  String? _peerUserId; // Store peer user ID for block checking

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
    
    // Mark messages as read immediately when chat opens (non-blocking)
    _chatService.markMessagesAsRead(widget.chatId);
    
    // Fetch product status asynchronously (non-blocking)
    _fetchProductStatus();
    
    // Check block status immediately when entering chat (no delay)
    _startBlockStatusPolling();
  }
  
  /// Start periodic polling to check if chat is blocked
  void _startBlockStatusPolling() {
    // Extract peer user ID from chatId directly (format: productId_sellerId_buyerId)
    _extractPeerUserIdFromChatId();
    
    if (_peerUserId == null || _peerUserId!.isEmpty) {
      // If peer ID not available yet, try again in 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _startBlockStatusPolling();
      });
      return;
    }
    
    // Check immediately first
    _checkBlockStatus();
    
    // Then poll every 30 seconds
    _blockStatusPollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isChatBlocked) {
        _checkBlockStatus();
      } else {
        timer.cancel();
      }
    });
  }
  
  /// Extract peer user ID directly from chatId (format: productId_sellerId_buyerId)
  void _extractPeerUserIdFromChatId() {
    try {
      final parts = widget.chatId.split('_');
      
      if (parts.length >= 3) {
        final currentUserId = _chatService.currentUserIdSync;
        final sellerId = parts[1];
        final buyerId = parts[2];
        
        // Determine which one is the peer (the other user)
        // If current user is the seller, peer is buyer; otherwise peer is seller
        _peerUserId = (currentUserId == sellerId) ? buyerId : sellerId;
      }
    } catch (e) {
      debugPrint('[BlockCheck] Error extracting peer ID: $e');
    }
  }
  
  /// Update peer user ID from cached chat data (backup method)
  void _updatePeerUserId() {
    if (_cachedChatData != null) {
      final currentUserId = _chatService.currentUserIdSync;
      // If current user is the seller, peer is buyer; otherwise peer is seller
      final newPeerUserId = _cachedChatData!.sellerId == currentUserId
          ? _cachedChatData!.buyerId
          : _cachedChatData!.sellerId;
      
      // If peer ID just became available, check block status immediately
      if (_peerUserId == null && newPeerUserId.isNotEmpty) {
        _peerUserId = newPeerUserId;
        _checkBlockStatus(); // Immediate check
      } else {
        _peerUserId = newPeerUserId;
      }
    }
  }
  
  /// Check if current user is blocked by or has blocked the peer user
  Future<void> _checkBlockStatus() async {
    if (_peerUserId == null || _isChatBlocked) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('https://api.junctionverse.com/user/check-block/$_peerUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final isBlocked = data['isBlocked'] == true;
        
        if (isBlocked && mounted) {
          setState(() {
            _isChatBlocked = true;
          });
          
          // Cancel polling timer since we found a block
          _blockStatusPollingTimer?.cancel();
          
          // Show notification
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This chat has been blocked. You can no longer message this user.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[BlockCheck] Error: $e');
      // Silently fail - don't interrupt user experience
    }
  }
  
  Future<String?> _fetchProductStatus() async {
    try {
      // Wait for cached chat data to be available (from preload)
      // This avoids making an extra Firestore query here
      if (_cachedChatData == null) {
        // If cache is still null, wait a bit for preload to complete
        await Future.delayed(const Duration(milliseconds: 100));
        if (_cachedChatData == null) {
          // Still null after wait, try one more fetch
          final chatDoc = await FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .get();
          if (chatDoc.exists && mounted) {
            setState(() {
              _cachedChatData = ChatModel.fromFirestore(chatDoc.data() as Map<String, dynamic>);
            });
          } else {
            return null;
          }
        }
      }
      
      // Ensure we have productId before making API call
      if (_cachedChatData == null || _cachedChatData!.productId.isEmpty) {
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return null;
      
      final response = await http.get(
        Uri.parse('https://api.junctionverse.com/product/${_cachedChatData!.productId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String newStatus = data['status']?.toString() ?? '';
        // Only update state if status actually changed
        if (mounted && _productStatus != newStatus) {
          setState(() {
            _productStatus = newStatus;
          });
        }
        return newStatus;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching product status: $e');
      return null;
    }
  }
  
  void _startStatusPolling() {
    // Cancel any existing timer
    _statusPollingTimer?.cancel();
    
    // Record polling start time
    _pollingStartTime = DateTime.now();
    
    // Start polling every 2 seconds
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        _statusPollingTimer = null;
        return;
      }
      
      // Safety check: Stop polling after 30 seconds to prevent infinite polling
      if (_pollingStartTime != null) {
        final elapsed = DateTime.now().difference(_pollingStartTime!);
        if (elapsed.inSeconds > 30) {
          timer.cancel();
          _statusPollingTimer = null;
          _pollingStartTime = null;
          debugPrint('Chat polling timeout reached (30s). Stopping status polling.');
          return;
        }
      }
      
      final String? status = await _fetchProductStatus();
      
      // Stop polling if product is confirmed as sold
      if (status == 'Sold') {
        timer.cancel();
        _statusPollingTimer = null;
        _pollingStartTime = null;
        debugPrint('Product status confirmed as Sold. Stopping polling.');
        
        // Force a rebuild to update UI
        if (mounted) {
          setState(() {});
        }
      }
    });
  }
  
  void _stopStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = null;
    _pollingStartTime = null;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    // Clean up timers
    _confirmButtonTimer?.cancel();
    _statusPollingTimer?.cancel(); // Cancel polling timer on dispose
    _blockStatusPollingTimer?.cancel(); // Cancel block status polling timer
    // Reset flags when disposing
    _hasDoneInitialScroll = false;
    _isUserTyping = false;
    _currentScrollPosition = 0.0;
    super.dispose();
  }

  // Static method that doesn't depend on chatData parameter
  void _sendMessageStatic(String message) async {
    if (message.trim().isEmpty) return;
    
    // Check if chat is blocked before sending
    if (_isChatBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This chat is blocked. You cannot send messages.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

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
      bool isSeller = chatData.sellerId == _chatService.currentUserIdSync;
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
      ErrorHandler.showErrorSnackBar(context, e);
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
      ErrorHandler.showErrorSnackBar(context, e);
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
            
            // Show blocked message if chat is blocked
            if (_isChatBlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This chat is blocked. You cannot send messages to this user.',
                        style: TextStyle(color: Colors.red[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      enabled: !_isUploading && !_isConfirmingDeal && !_isImageUploading && !_isChatBlocked,
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null, // Allow multiple lines
                      minLines: 1, // Start with single line
                      decoration: InputDecoration(
                        hintText: (_isUploading || _isConfirmingDeal || _isImageUploading) 
                            ? 'Processing...' 
                            : (_isChatBlocked ? 'Chat is blocked' : 'Write a message...'),
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
                    onSubmitted: (_isUploading || _isConfirmingDeal || _isImageUploading || _isChatBlocked) 
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
                  onPressed: (_isUploading || _isConfirmingDeal || _isImageUploading || _isChatBlocked) 
                      ? null 
                      : _showImagePickerBottomSheetStatic,
                  icon: Icon(
                    Icons.camera_alt_rounded,
                    color: (_isUploading || _isConfirmingDeal || _isImageUploading || _isChatBlocked) 
                        ? Colors.grey 
                        : Colors.black,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: (_isUploading || _isConfirmingDeal || _isImageUploading || _isChatBlocked) 
                      ? Colors.grey 
                      : Colors.black,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: (_isUploading || _isConfirmingDeal || _isImageUploading || _isChatBlocked) 
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
  // If chat is blocked, don't show any action buttons
  if (_isChatBlocked) {
    return const SizedBox.shrink();
  }
  
  final String currentUserId = _chatService.currentUserIdSync;
  final bool isSeller = currentUserId.isNotEmpty && chatData.sellerId == currentUserId;
  final bool isBuyer = currentUserId.isNotEmpty && chatData.buyerId == currentUserId;

  // Removed excessive debug print - only log when values actually change (optional, can be removed entirely)
  // debugPrint('Chat Action Buttons - Deal Status: ${chatData.dealStatus}, Product Status: $_productStatus, Is Seller: $isSeller, Is Buyer: $isBuyer');

  // Check if this buyer purchased the product (orderId exists means this buyer purchased it)
  final bool thisBuyerPurchased = chatData.orderId != null && chatData.orderId!.isNotEmpty;
  final bool buyerPurchased = isBuyer && thisBuyerPurchased;

  // Determine product status - prioritize dealStatus from Firestore as source of truth
  // If dealStatus is 'active', the deal is NOT locked, allowing quotes and negotiations
  final String productStatus = _productStatus ??
      (chatData.dealStatus == 'sold' ? 'Sold' :
       (chatData.dealStatus == 'locked' || chatData.dealStatus == 'confirmed')
          ? 'Locked'
          : 'For Sale');
  final bool isProductSold = productStatus == 'Sold';
  
  // Deal is locked ONLY if dealStatus is 'locked' or 'confirmed' (not 'active')
  // When dealStatus is 'active', users can quote/negotiate regardless of backend product status
  final bool isProductLocked = !isProductSold &&
      (chatData.dealStatus == 'locked' || chatData.dealStatus == 'confirmed');

  // Show product status badge and buttons if product is sold or locked
  if (isProductSold || isProductLocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          // Product status badge - prioritize Sold over Locked
          if (isProductSold)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.orange[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Product is Sold',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else if (isProductLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Product Deal is Locked',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons based on product status and user role
          if (isProductSold) ...[
            // Product is sold - show rating buttons
            if (isSeller && thisBuyerPurchased)
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Rate the Buyer',
                  onPressed: () => _navigateToRateBuyerScreen(chatData),
                  backgroundColor: const Color(0xFFFF6705),
                  textColor: Colors.white,
                ),
              )
            else if (buyerPurchased)
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Rate the Seller',
                  onPressed: () => _navigateToRateSellerScreen(chatData),
                  backgroundColor: const Color(0xFFFF6705),
                  textColor: Colors.white,
                ),
              ),
          ] else if (isProductLocked) ...[
            if (isSeller) ...[
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel Deal',
                      onPressed: (_isUploading || _isConfirmingDeal)
                          ? null
                          : () => _showCancelDealConfirmation(chatData),
                      backgroundColor: Colors.white,
                      borderColor: const Color(0xFF262626),
                      textColor: const Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Mark as Sold',
                      onPressed: (_isUploading || _isConfirmingDeal || isProductSold)
                          ? null
                          : () => _showMarkAsSoldConfirmation(chatData, chatData.orderId ?? ''),
                      backgroundColor: (_isConfirmingDeal || isProductSold)
                          ? Colors.grey
                          : Colors.black,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ] else if (buyerPurchased) ...[
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel Deal',
                      onPressed: (_isUploading)
                          ? null
                          : () => _showCancelDealConfirmation(chatData),
                      backgroundColor: Colors.white,
                      borderColor: const Color(0xFF262626),
                      textColor: const Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Rate the Seller',
                      onPressed: (_isUploading)
                          ? null
                          : () => _navigateToRateSellerScreen(chatData),
                      backgroundColor: const Color(0xFFFF6705),
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  if (!isProductSold && !isProductLocked && chatData.dealStatus != 'confirmed' && chatData.dealStatus != 'active') {
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
        if (chatData.dealStatus == 'confirmed' && !isProductSold) ...[
          if (isSeller) ...[
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel Deal',
                    onPressed: (_isUploading || _isConfirmingDeal)
                        ? null
                        : () => _showCancelDealConfirmation(chatData),
                    backgroundColor: Colors.white,
                    borderColor: const Color(0xFF262626),
                    textColor: const Color(0xFF262626),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: _isConfirmingDeal ? 'Confirming...' : 'Mark as Sold',
                    onPressed: (_isUploading || _isConfirmingDeal || isProductSold)
                        ? null
                        : () => _showMarkAsSoldConfirmation(chatData, chatData.orderId ?? ''),
                    backgroundColor: (_isConfirmingDeal || isProductSold)
                        ? Colors.grey
                        : Colors.black,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ] else if (buyerPurchased) ...[
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel Deal',
                    onPressed: (_isUploading)
                        ? null
                        : () => _showCancelDealConfirmation(chatData),
                    backgroundColor: Colors.white,
                    borderColor: const Color(0xFF262626),
                    textColor: const Color(0xFF262626),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Rate the Seller',
                    onPressed: (_isUploading)
                        ? null
                        : () => _navigateToRateSellerScreen(chatData),
                    backgroundColor: const Color(0xFFFF6705),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ] else if (chatData.dealStatus == 'active') ...[
          AppButton(
            label: 'Quote Price',
            onPressed: (_isUploading || _isConfirmingDeal)
                ? null
                : () => _showQuotePriceBottomSheet(chatData),
            backgroundColor: Colors.white,
            borderColor: Colors.black,
            textColor: Colors.black,
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
                          color: Color(0xFFFF6705),

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
                      child: AppButton(
                        label: 'Keep Deal',
                        onPressed: isCanceling ? null : () => Navigator.pop(context),
                        backgroundColor: Colors.white,
                        borderColor: const Color(0xFF262626),
                        textColor: const Color(0xFF262626),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: isCanceling ? 'Canceling...' : 'Cancel Deal',
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
                              final bool isSellerCancelling = chatData.sellerId == _chatService.currentUserIdSync;
                              // Update Firestore - reset to active status
                              await FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(widget.chatId)
                                  .update({
                                'dealStatus': 'active',
                                'finalPrice': null,
                                'orderId': null,
                                'lastMessage': isSellerCancelling
                                    ? 'Deal cancelled by seller. Back to negotiation.'
                                    : 'Deal cancelled by buyer. Back to negotiation.',
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
                                'receiverId': isSellerCancelling ? chatData.buyerId : chatData.sellerId,
                                'message': isSellerCancelling
                                    ? 'Deal has been cancelled by seller. You can continue negotiating.'
                                    : 'Deal has been cancelled by buyer. You can continue negotiating.',
                                'timestamp': Timestamp.fromDate(DateTime.now()),
                                'messageType': 'system',
                                'isRead': false,
                              });

                              // Close modal first
                              if (mounted) {
                                Navigator.pop(context);
                              }

                              // Reset all state and force refresh
                              if (mounted) {
                                setState(() {
                                  _productStatus = null; // Clear status to force fetch from backend
                                  _cachedChatData = null; // Force refresh chat data
                                  _isConfirmingDeal = false;
                                  _nextQuoteAllowedAt = null;
                                });
                                
                                // Fetch latest product status from backend
                                await _fetchProductStatus();
                                
                                // Force UI rebuild after a brief delay to ensure StreamBuilder has updated
                                await Future.delayed(const Duration(milliseconds: 500));
                                if (mounted) {
                                  setState(() {});
                                }
                              }

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text('Deal cancelled successfully. You can now quote again.'),
                                      ],
                                    ),
                                   backgroundColor: const Color(0xFFFF6705),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            } else {
                              setModalState(() {
                                isCanceling = false;
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to cancel deal. Please try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }

                          } catch (e) {
                            setModalState(() {
                              isCanceling = false;
                            });

                            Navigator.pop(context);
                            ErrorHandler.showErrorSnackBar(context, e);
                          }
                        },
                        backgroundColor: isCanceling ? Colors.grey : Colors.red,
                        textColor: Colors.white,
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
    final bool isSeller = chatData.sellerId == _chatService.currentUserIdSync;
    final String otherUserId = isSeller ? chatData.buyerId : chatData.sellerId;
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
    return GestureDetector(
      onTap: () {
        if (otherUserId == _chatService.currentUserIdSync) {
          Navigator.push(context, SlidePageRoute(page: const UserProfilePage()));
        } else {
          Navigator.push(context, SlidePageRoute(page: OthersProfilePage(userId: otherUserId)));
        }
      },
      child: Row(
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
      title: StreamBuilder<ChatModel?>(
        stream: _chatService.getChatStream(widget.chatId),
        builder: (context, chatSnapshot) {
          if (!chatSnapshot.hasData) {
            return const Text('Loading...');
          }
          
          _cachedChatData = chatSnapshot.data!;
          _updatePeerUserId(); // Update peer user ID when chat data is available
          return _buildAppBarTitle(chatSnapshot.data!);
        },
      ),
      actions: [
        StreamBuilder<ChatModel?>(
          stream: _chatService.getChatStream(widget.chatId),
          builder: (context, chatSnapshot) {
            if (!chatSnapshot.hasData) return const SizedBox.shrink();
            final chatData = chatSnapshot.data!;
            final currentUserId = _chatService.currentUserIdSync;
            // If current user is the seller, peer is buyer; otherwise peer is seller
            final peerUserId = chatData.sellerId == currentUserId
                ? chatData.buyerId
                : chatData.sellerId;
            return IconButton(
              icon: const Icon(Icons.flag_outlined, color: Colors.black),
              onPressed: () => _openReportUserBottomSheet(peerUserId, chatData),
              tooltip: 'Report user',
            );
          },
        ),
      ],
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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
                          const SizedBox(height: 16),
                          Text(
                            ErrorHandler.getErrorMessage(messageSnapshot.error),
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                
                List<MessageModel> messages = messageSnapshot.data ?? [];
                
                // Deduplicate product cards - keep only the first one for each unique productId
                // This prevents duplicate product cards from showing in the chat
                Map<String, MessageModel> seenProductCards = {};
                Set<String> seenMessageIds = {}; // Also deduplicate by messageId for any duplicate messages
                List<MessageModel> deduplicatedMessages = [];
                
                for (var message in messages) {
                  // First check if we've seen this exact messageId (should never happen, but safety check)
                  if (seenMessageIds.contains(message.messageId)) {
                    continue; // Skip duplicate message
                  }
                  seenMessageIds.add(message.messageId);
                  
                  if (message.messageType == 'product_card') {
                    // Use productId from productData as unique key to prevent same product showing twice
                    String? productId = message.productData?['productId']?.toString();
                    String uniqueKey = productId ?? message.messageId;
                    
                    if (!seenProductCards.containsKey(uniqueKey)) {
                      seenProductCards[uniqueKey] = message;
                      deduplicatedMessages.add(message);
                    }
                    // Skip duplicate product cards with same productId
                  } else {
                    deduplicatedMessages.add(message);
                  }
                }
                
                messages = deduplicatedMessages;
                
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
                
                // Render messages - use cached chat data if available, otherwise wait for stream
                if (_cachedChatData == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    MessageModel message = messages[index];
                    // Use cached chat data
                    return _buildMessage(message, _cachedChatData!);
                  },
                );
              },
            ),
          ),
          
          // Action buttons area - always use StreamBuilder to get real-time updates
          StreamBuilder<ChatModel?>(
            stream: _chatService.getChatStream(widget.chatId),
            builder: (context, chatSnapshot) {
              if (!chatSnapshot.hasData) {
                // Use cached data if stream hasn't loaded yet
                if (_cachedChatData != null) {
                  return _buildActionButtonsArea(_cachedChatData!);
                }
                return const SizedBox.shrink();
              }
              final newChatData = chatSnapshot.data!;
              
              // Only update cache and fetch status if data actually changed
              final dataChanged = _cachedChatData == null ||
                  _cachedChatData!.dealStatus != newChatData.dealStatus ||
                  _cachedChatData!.orderId != newChatData.orderId ||
                  _cachedChatData!.finalPrice != newChatData.finalPrice ||
                  _cachedChatData!.productId != newChatData.productId;
              
              if (dataChanged) {
                _cachedChatData = newChatData;
                
                // Only fetch product status if productId changed and not already fetching
                if (newChatData.productId.isNotEmpty && 
                    newChatData.productId != _lastFetchedProductId &&
                    !_isFetchingProductStatus) {
                  _lastFetchedProductId = newChatData.productId;
                  _isFetchingProductStatus = true;
                  // Don't await - let it run in background
                  _fetchProductStatus().then((_) {
                    if (mounted) {
                      _isFetchingProductStatus = false;
                    }
                  }).catchError((_) {
                    if (mounted) {
                      _isFetchingProductStatus = false;
                    }
                  });
                }
              }
              
              return _buildActionButtonsArea(newChatData);
            },
          ),
          
          // Input area - COMPLETELY STATIC, no StreamBuilder dependency
          _buildPureInputArea(),
        ],
      ),
    ),
  );
}

// Removed _getChatDataOnce() - no longer needed as we preload chat data in initState


Widget _buildMessage(MessageModel message, ChatModel chatData) {
  bool isMe = message.senderId == _chatService.currentUserIdSync;
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
    FadePageRoute(page: ReviewScreen(
      ratedUserId: chatData.sellerId,
      ratedById: chatData.buyerId,
      fromProductSold: false,
    )),
  );
}

void _navigateToRateBuyerScreen(ChatModel chatData) {
  Navigator.pushReplacement(
    context,
    FadePageRoute(page: ReviewScreen(
      ratedUserId: chatData.buyerId,
      ratedById: chatData.sellerId,
      fromProductSold: false,
    )),
  );
}

Future<void> _cancelDeal(ChatModel chatData) async {
  try {
    if (chatData.orderId != null && chatData.orderId!.isNotEmpty) {
      await ChatService.cancelDeal(orderId: chatData.orderId!);
    }
    
    // Update chat status
    await _chatService.cancelDealInChat(chatData.chatId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deal cancelled successfully'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ErrorHandler.showErrorSnackBar(context, e);
  }
}

void _showQuotePriceBottomSheet(ChatModel chatData) {
  debugPrint('[QuoteSheet] Attempting to open quote sheet for chat ${chatData.chatId} with dealStatus ${chatData.dealStatus}');
  // Only block quoting if deal is locked or confirmed (not if it's active)
  if (chatData.dealStatus == 'locked' || chatData.dealStatus == 'confirmed') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deal is locked! Cannot quote on this product.'),
        backgroundColor: Colors.red,
      ),
    );
    debugPrint('[QuoteSheet] Aborted opening sheet because deal is locked or confirmed');
    return;
  }
  
  // Ensure dealStatus is 'active' before allowing quotes
  if (chatData.dealStatus != 'active') {
    debugPrint('[QuoteSheet] Warning: dealStatus is ${chatData.dealStatus}, expected active');
  }

  final TextEditingController priceController = TextEditingController();
  final bool isSeller = chatData.sellerId == _chatService.currentUserIdSync;
  Timer? cooldownTimer;
  int remainingSeconds = _quoteCooldownRemainingSeconds();
  bool hasStartedCountdown = false;
  bool isSending = false;
  String? localError;
  bool modalMounted = true;
  final messenger = ScaffoldMessenger.of(context);
  debugPrint('[QuoteSheet] Initial cooldown remaining: $remainingSeconds seconds');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      debugPrint('[QuoteSheet] Bottom sheet builder invoked; modalMounted=$modalMounted');
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              if (!modalMounted) {
                debugPrint('[QuoteSheet] Builder hit after disposal; returning empty widget.');
                return const SizedBox.shrink();
              }
              void startCountdown() {
                if (hasStartedCountdown) return;
                hasStartedCountdown = true;
                remainingSeconds = _quoteCooldownRemainingSeconds();
                if (remainingSeconds > 0) {
                  cooldownTimer?.cancel();
                  cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                    if (!modalMounted) {
                      debugPrint('[QuoteSheet] Timer tick after modal disposed; cancelling timer.');
                      timer.cancel();
                      return;
                    }
                    final updated = _quoteCooldownRemainingSeconds();
                    if (updated <= 0) {
                      timer.cancel();
                      setModalState(() {
                        remainingSeconds = 0;
                      });
                      debugPrint('[QuoteSheet] Cooldown finished while sheet open.');
                    } else {
                      setModalState(() {
                        remainingSeconds = updated;
                      });
                      debugPrint('[QuoteSheet] Cooldown tick -> $remainingSeconds seconds remaining');
                    }
                  });
                  debugPrint('[QuoteSheet] Cooldown timer started with $remainingSeconds seconds remaining');
                }
              }

              startCountdown();

              final bool isInCooldown = remainingSeconds > 0;
              final String cooldownLabel = isInCooldown
                  ? 'Please wait ${remainingSeconds}s before sending another quote.'
                  : '';

              return Column(
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
                    'Enter the amount you would like to offer for this product.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Quote Price',
                    placeholder: 'Enter your price offer',
                    isMandatory: true,
                    keyboardType: TextInputType.number,
                    controller: priceController,
                    prefixText: '₹ ',
                  ),
                  const SizedBox(height: 20),
                  if (isInCooldown) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cooldownLabel,
                              style: TextStyle(color: Colors.orange[800], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (localError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              localError!,
                              style: TextStyle(color: Colors.red[700], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        onPressed: () {
                          if (modalMounted) {
                            debugPrint('[QuoteSheet] Cancel button tapped; closing sheet.');
                            modalMounted = false;
                            cooldownTimer?.cancel();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              priceController.clear();
                              setState(() {
                                _messageController.clear();
                              });
                            });
                            Navigator.of(sheetContext).pop();
                          }
                        },
                        backgroundColor: Colors.grey[600],
                      ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: isSending ? 'Sending...' : 'Send Quote',
                          onPressed: (isSending || isInCooldown)
                              ? null
                              : () async {
                                  final rawText = priceController.text.trim();
                                  if (rawText.isEmpty) {
                                    setModalState(() => localError = 'Please enter a price');
                                    return;
                                  }

                                  final parsedPrice = double.tryParse(rawText.replaceAll(',', ''));
                                  if (parsedPrice == null || parsedPrice <= 0) {
                                    setModalState(() => localError = 'Please enter a valid price');
                                    return;
                                  }

                                  setModalState(() {
                                    isSending = true;
                                    localError = null;
                                  });

                                  try {
                                    setModalState(() => isSending = true);
                                    final offerNumber = await _chatService.getNextOfferNumber(widget.chatId);
                                    final receiverId = isSeller ? chatData.buyerId : chatData.sellerId;

                                    await _chatService.sendPriceQuote(
                                      chatId: widget.chatId,
                                      receiverId: receiverId,
                                      price: parsedPrice,
                                      offerNumber: offerNumber,
                                    );

                                    _nextQuoteAllowedAt = DateTime.now().add(const Duration(minutes: 1));
                                    if (!mounted) return;
                                    setState(() {});

                                    if (modalMounted) {
                                      debugPrint('[QuoteSheet] Quote sent successfully; dismissing sheet.');
                                      modalMounted = false;
                                      cooldownTimer?.cancel();
                                      setModalState(() {
                                        isSending = false;
                                      });
                                      if (Navigator.of(sheetContext).canPop()) {
                                        Navigator.of(sheetContext).pop();
                                      }
                                    }

                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Quote sent successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e, stack) {
                                    debugPrint('[QuoteSheet] Error sending quote: $e');
                                    debugPrint('[QuoteSheet] Stack trace: $stack');
                                    if (modalMounted) {
                                      setModalState(() {
                                        localError = 'Failed to send quote. Please try again.';
                                        isSending = false;
                                      });
                                    } else {
                                      ErrorHandler.showErrorSnackBar(
                                        context,
                                        null,
                                        customMessage: 'Failed to send quote. Please try again.',
                                      );
                                    }
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      );
    },
  ).whenComplete(() {
    modalMounted = false;
    debugPrint('[QuoteSheet] Bottom sheet closed (whenComplete). Cleaning up resources.');
    cooldownTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[QuoteSheet] Disposing priceController after frame');
      priceController.dispose();
    });
  });
}

  int _quoteCooldownRemainingSeconds() {
    if (_nextQuoteAllowedAt == null) {
      debugPrint('[QuoteSheet] No cooldown set; returning 0');
      return 0;
    }
    final diff = _nextQuoteAllowedAt!.difference(DateTime.now());
    if (diff.isNegative) {
      debugPrint('[QuoteSheet] Cooldown already expired (${diff.inSeconds}s); returning 0');
      return 0;
    }
    debugPrint('[QuoteSheet] Cooldown remaining ${diff.inSeconds} seconds');
    return diff.inSeconds;
  }

void _navigateToProductSoldFlow(ChatModel chatData) {
  Navigator.pushReplacement(
    context,
    FadePageRoute(page: ProductSoldScreen(
      productName: chatData.productTitle,
      ratedUserId: chatData.buyerId,
      ratedById: chatData.sellerId,
      fromProductSold: true,
    )),
  );
}

void _showImagePickerBottomSheet(ChatModel chatData) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Container(
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
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Take a Photo',
                backgroundColor: Colors.white,
                textColor: const Color(0xFF262626),
                borderColor: const Color(0xFF262626),
                onPressed: () {
                  Navigator.pop(sheetContext); // Close bottom sheet using its own context
                  _handleImageSelection(ImageSource.camera, chatData);
                },
                bottomSpacing: 16,
              ),
              AppButton(
                label: 'Upload from device',
                backgroundColor: Colors.white,
                textColor: const Color(0xFF262626),
                borderColor: const Color(0xFF262626),
                onPressed: () {
                  Navigator.pop(sheetContext); // Close bottom sheet using its own context
                  _handleImageSelection(ImageSource.gallery, chatData);
                },
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
  // Bottom sheet is already closed by the button's onPressed handler
  // No need to pop here - this prevents accidentally popping the chat screen
  
  final bool isSeller = chatData.sellerId == _chatService.currentUserIdSync;
  String receiverId = isSeller ? chatData.buyerId : chatData.sellerId;

  // Don't set upload state here - wait until image is actually picked
  // This prevents getting stuck if user cancels

  try {
    await _chatService.pickAndSendImageWithProgress(
      chatId: widget.chatId,
      receiverId: receiverId,
      source: source,
      onUploadStart: (status) {
        // Show overlay only when upload actually starts (after image is picked)
        if (!_isImageUploading) {
          setState(() {
            _isImageUploading = true;
            _imageUploadProgress = 0.0;
            _imageUploadStatus = status;
          });
          _showImageUploadOverlay();
        } else {
          setState(() {
            _imageUploadStatus = status;
            _imageUploadProgress = 0.0;
          });
        }
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
        // Close overlay if it's open
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        
        // Only show error if it's not empty (empty means cancellation)
        if (error.isNotEmpty) {
          ErrorHandler.showErrorSnackBar(context, error);
        }
      },
      onCancelled: () {
        // Handle cancellation: clean up state without showing error
        // User stays on chat screen - no navigation needed
        // Overlay should not be open since we only show it after image is picked
        setState(() {
          _isImageUploading = false;
          _imageUploadProgress = 0.0;
          _imageUploadStatus = '';
        });
        // No navigation needed - user cancelled, so they stay on chat screen
      },
    );
  } catch (e) {
    setState(() {
      _isImageUploading = false;
      _imageUploadProgress = 0.0;
      _imageUploadStatus = '';
    });
    Navigator.of(context, rootNavigator: true).pop(); // Close overlay if still open
    ErrorHandler.showErrorSnackBar(context, e);
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
                AppButton(
                  label: _isConfirmingDeal ? 'Confirming...' : 'Confirm',
                  onPressed: _isConfirmingDeal ? null : () => _showConfirmPriceBottomSheet(chatData, message, price),
                  backgroundColor: _isConfirmingDeal ? Colors.grey : Colors.black,
                  textColor: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> _showConfirmPriceBottomSheet(ChatModel chatData, MessageModel quoteMessage, double price) async { 
  bool isSeller = chatData.sellerId == _chatService.currentUserIdSync;

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
                'Lock this deal at the quoted price',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              
              // Display the quoted price as read-only
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quoted Price:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6705),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: The deal will be locked at this exact price. To change the price, send a new quote instead.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
              
              // Error message display
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      onPressed: _isConfirmingDeal ? null : () => Navigator.pop(context),
                      backgroundColor: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: _isConfirmingDeal ? 'Confirming...' : 'Lock Deal',
                      onPressed: _isConfirmingDeal
                          ? null
                          : () async {
                              // Disable button for 1 minute
                              _confirmButtonTimer?.cancel();
                              setModalState(() => _isConfirmingDeal = true);
                              setState(() => _isConfirmingDeal = true);

                              // Use the exact quoted price - no modification allowed
                              double finalPrice = price;

                              // Fetch latest chat data from Firestore to ensure we have current dealStatus
                              ChatModel? latestChatData;
                              try {
                                latestChatData = await _chatService.getChat(chatData.chatId);
                              } catch (e) {
                                debugPrint('[ConfirmDeal] Error fetching latest chat data: $e');
                                // Fallback to passed chatData if fetch fails
                                latestChatData = chatData;
                              }

                              // Use latest data if available, otherwise use passed data
                              final currentChatData = latestChatData ?? chatData;
                              
                              // Only block confirmation if deal is locked or confirmed (not if it's active)
                              if (currentChatData.dealStatus == 'locked' || currentChatData.dealStatus == 'confirmed') {
                                setModalState(() => _isConfirmingDeal = false);
                                _confirmButtonTimer?.cancel();
                                setModalState(() => _isConfirmingDeal = false);
                                setState(() => _isConfirmingDeal = false);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Deal is locked! Cannot confirm this deal.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Ensure dealStatus is 'active' before allowing confirmation
                              if (currentChatData.dealStatus != 'active') {
                                debugPrint('[ConfirmDeal] Error: dealStatus is "${currentChatData.dealStatus}", expected "active". Cannot proceed.');
                                _confirmButtonTimer?.cancel();
                                setModalState(() => _isConfirmingDeal = false);
                                setState(() => _isConfirmingDeal = false);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cannot lock deal: Deal status is "${currentChatData.dealStatus}". Please refresh and try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              try {
                                String orderId = await ChatService.lockDeal(
                                  productId: currentChatData.productId,
                                  buyerId: currentChatData.buyerId,
                                  finalPrice: finalPrice,
                                );

                                if (orderId.isNotEmpty) {
                                  if (mounted) {
                                    setState(() {
                                      _productStatus = 'Locked';
                                    });
                                  }

                                  // Determine receiverId based on who is confirming
                                  final receiverId = isSeller ? currentChatData.buyerId : currentChatData.sellerId;
                                  
                                  await _chatService.confirmDeal(
                                    chatId: currentChatData.chatId,
                                    receiverId: receiverId,
                                    finalPrice: finalPrice,
                                    productId: currentChatData.productId,
                                    buyerId: currentChatData.buyerId,
                                    orderId: orderId,
                                  );

                                  await FirebaseFirestore.instance
                                      .collection('messages')
                                      .doc(currentChatData.chatId)
                                      .collection('messages')
                                      .doc(quoteMessage.messageId)
                                      .update({
                                    'priceData.isConfirmed': true,
                                  });

                                  Navigator.pop(context);

                                  // Clear cached data to force refresh
                                  if (mounted) {
                                    setState(() {
                                      _cachedChatData = null; // Force refresh
                                      _isConfirmingDeal = false;
                                    });
                                  }

                                  if (isSeller) {
                                    // Create updated chatData with orderId for mark as sold
                                    final updatedChatData = ChatModel(
                                      chatId: currentChatData.chatId,
                                      productId: currentChatData.productId,
                                      sellerId: currentChatData.sellerId,
                                      buyerId: currentChatData.buyerId,
                                      sellerName: currentChatData.sellerName,
                                      buyerName: currentChatData.buyerName,
                                      productTitle: currentChatData.productTitle,
                                      productImage: currentChatData.productImage,
                                      productPrice: currentChatData.productPrice,
                                      orderId: orderId,
                                      lastMessage: currentChatData.lastMessage,
                                      lastMessageTime: currentChatData.lastMessageTime,
                                      createdAt: currentChatData.createdAt,
                                      dealStatus: 'confirmed',
                                      finalPrice: finalPrice,
                                      participants: currentChatData.participants,
                                    );
                                    _showMarkAsSoldConfirmation(updatedChatData, orderId);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Deal confirmed successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else {
                                  throw Exception('Failed to lock deal: orderId is empty');
                                }
                              } catch (e) {
                                _confirmButtonTimer?.cancel();
                                setModalState(() => _isConfirmingDeal = false);
                                setState(() => _isConfirmingDeal = false);
                                setState(() {
                                  _errorMessage = ErrorHandler.getErrorMessage(e);
                                });
                                debugPrint('[ConfirmDeal] Error locking deal: $e');
                              }
                              _confirmButtonTimer?.cancel();
                            },
                      backgroundColor: _isConfirmingDeal ? Colors.grey : Colors.black,
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
  bool isSeller = chatData.sellerId == _chatService.currentUserIdSync;

  if (!isSeller) {
    // Safety: buyers should never see this prompt
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
                  child: AppButton(
                    label: 'Cancel',
                    onPressed: () {
                      setState(() {
                        _isConfirmingDeal = false;
                      });
                      Navigator.pop(context);
                    },
                    backgroundColor: Colors.white,
                    borderColor: const Color(0xFF262626),
                    textColor: const Color(0xFF262626),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Mark as Sold',
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

                        if (mounted) {
                          setState(() {
                            _productStatus = 'Sold';
                          });
                        }

                        setState(() => _isConfirmingDeal = false);

                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(
                        //     content: Text('Product marked as sold!'),
                        //     backgroundColor: Colors.green,
                        //   ),
                        // );

                        // Start polling for status updates
                        _startStatusPolling();
                        // Also do an immediate refresh
                        await _fetchProductStatus();
                        if (mounted) {
                          setState(() {});
                        }
                        
                        // Navigate to ProductSoldScreen (original flow)
                        _navigateToProductSoldFlow(chatData);
                      } catch (e) {
                        setState(() => _isConfirmingDeal = false);
                        ErrorHandler.showErrorSnackBar(context, e);
                      }
                    },
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
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
  bool isSeller = chatData.sellerId == _chatService.currentUserIdSync;
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
                      color: Color(0xFFFF6705),

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
  /*
  // Previous deal-locked UI (grey card with price pill) – commented out per new design
  final priceData = message.priceData;
  if (priceData == null) return const SizedBox();
  double price = priceData['price']?.toDouble() ?? 0;
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    child: Column(
      children: [
        // ... prior UI removed for brevity ...
      ],
    ),
  );
  */

  // New: full-width green banner identical to system messages, price text in bold
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
        Icon(Icons.check_circle, color: Colors.green[600], size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w500),
              children: _buildBoldPriceSpans(message.message),
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper: splits text and makes the price segment bold (₹123…)
List<InlineSpan> _buildBoldPriceSpans(String text) {
  final regex = RegExp(r'(₹[\d,]+)');
  final match = regex.firstMatch(text);
  if (match == null) return [TextSpan(text: text)];
  return [
    TextSpan(text: text.substring(0, match.start)),
    TextSpan(text: match.group(0), style: const TextStyle(fontWeight: FontWeight.bold)),
    TextSpan(text: text.substring(match.end)),
  ];
}

void _openReportUserBottomSheet(String peerUserId, ChatModel chatData) {
  _selectedReportReasonCode = null;
  _reportNotesController.clear();
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Report User',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a reason for reporting this user:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _reportReasonOptions.map((option) {
                    final code = option['code']!;
                    final label = option['label']!;
                    final isSelected = _selectedReportReasonCode == code;
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) {
                        setModalState(() {
                          _selectedReportReasonCode = code;
                        });
                        setState(() {
                          _selectedReportReasonCode = code;
                        });
                      },
                      selectedColor: const Color(0xFF262626),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reportNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Additional details (optional)',
                    hintText: 'Describe what happened...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 500,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Important: Reporting this user will also block them from interacting with you on the platform. Do you wish to proceed?',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: _isSubmittingReport ? 'Submitting...' : 'Submit report',
                  onPressed: _selectedReportReasonCode == null || _isSubmittingReport
                      ? null
                      : () => _submitUserReport(peerUserId, chatData, sheetContext),
                  backgroundColor: const Color(0xFF262626),
                  textColor: Colors.white,
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _submitUserReport(String peerUserId, ChatModel chatData, BuildContext sheetContext) async {
  if (_selectedReportReasonCode == null) return;
  
  setState(() => _isSubmittingReport = true);
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    
    if (token == null) {
      if (!mounted) return;
      Navigator.pop(sheetContext);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to report users')),
      );
      return;
    }
    
    final payload = {
      'conversationId': widget.chatId,
      'reasonCode': _selectedReportReasonCode,
      'reasonText': _reportNotesController.text.trim().isNotEmpty
          ? _reportNotesController.text.trim()
          : null,
    };
    
    final response = await http.post(
      Uri.parse('https://api.junctionverse.com/user/$peerUserId/report'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );
    
    if (!mounted) return;
    
    Navigator.pop(sheetContext);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final alreadyReported = data['alreadyReported'] == true || data['status'] == 'duplicate';
      final userBlocked = data['userBlocked'] == true;
      
      // Immediately lock the chat
      if (userBlocked || alreadyReported) {
        setState(() {
          _isChatBlocked = true;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(alreadyReported
              ? 'You already reported this user. This chat is now blocked.'
              : 'User reported and blocked. You can no longer chat with them.'),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      // Extract error message from response
      String errorMessage;
      try {
        final data = jsonDecode(response.body);
        errorMessage = data['message']?.toString() ?? 'Failed to submit report. Please try again.';
      } catch (_) {
        errorMessage = 'Failed to submit report. Please try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  } catch (e) {
    debugPrint('Error submitting user report: $e');
    if (!mounted) return;
    Navigator.pop(sheetContext);
    
    String errorMessage = 'An error occurred. Please try again.';
    if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
      errorMessage = 'Network error. Please check your connection.';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  } finally {
    if (mounted) {
      setState(() => _isSubmittingReport = false);
    }
  }
}

void _showFullScreenImage(String imageUrl) {
  Navigator.push(
    context,
    FadePageRoute(page: Scaffold(
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
    )),
  );
}
}

