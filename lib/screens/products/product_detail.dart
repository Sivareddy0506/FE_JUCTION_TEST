import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:junction/screens/Chat/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../../widgets/products_grid.dart';
import '../profile/empty_state.dart';
import '../../services/favorites_service.dart';
import '../services/chat_service.dart';
import '../../services/view_tracker.dart';
import '../services/location_helper.dart';
import '../../services/profile_service.dart';
import '../../app.dart'; 
import '../../../widgets/custom_appbar.dart';
import '../profile/user_profile.dart';
import '../profile/others_profile.dart';
import '../../utils/error_handler.dart';
import '../../widgets/app_button.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final List<Product>? products;
  final int? initialIndex;
  final VoidCallback? onFavoriteChanged;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.products,
    this.initialIndex,
    this.onFavoriteChanged,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  List<Product> relatedProducts = [];
  int currentProductIndex = 0;
  PageController? _pageController;
  PageController? _imagePageController;
  bool isLoadingRelated = true;
  final ChatService _chatService = ChatService();
  late FavoritesService _favoritesService;
  String? _sellerName;
  int _displayViews = 0;
  bool _registeredView = false;
  String? _cachedLocation;
  bool _isLoadingLocation = false;
  int _viewCount = 0;
  int _currentImageIndex = 0;
  String? _currentProductStatus; // Track product status
  Timer? _statusPollingTimer; // Timer for polling product status
  DateTime? _pollingStartTime; // Track when polling started
  bool _isFetchingStatus = false; // Prevent multiple simultaneous status fetches
  bool _hasScheduledStatusFetch = false; // Prevent scheduling multiple status fetches
  final TextEditingController _reportNotesController = TextEditingController();
  String? _selectedReportReasonCode;
  bool _isSubmittingReport = false;

  static const List<Map<String, String>> _reportReasonOptions = [
    {'code': 'SCAM', 'label': 'Scam / Fraud'},
    {'code': 'SPAM', 'label': 'Spam or promotion'},
    {'code': 'INAPPROPRIATE', 'label': 'Inappropriate content'},
    {'code': 'MISLEADING', 'label': 'Misleading information'},
    {'code': 'OTHER', 'label': 'Other'},
  ];

  // After fetching related products, use this helper:
  void _setProductList(List<Product> fetched) {
    if (!mounted) return;
    
    List<Product> withCurrent = List<Product>.from(fetched);
    if (!withCurrent.any((p) => p.id == widget.product.id)) {
      withCurrent.insert(0, widget.product);
    }
    currentProductIndex = withCurrent.indexWhere((p) => p.id == widget.product.id);
    
    // Dispose old controllers before creating new ones
    _pageController?.dispose();
    _imagePageController?.dispose();
    
    _pageController = PageController(initialPage: currentProductIndex);
    _imagePageController = PageController();
    _currentImageIndex = 0;
    
    if (mounted) {
      setState(() {
        relatedProducts = withCurrent;
        isLoadingRelated = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _favoritesService = FavoritesService();
    _displayViews = widget.product.views ?? 0;

    if (widget.products != null && widget.products!.isNotEmpty) {
      relatedProducts = List<Product>.from(widget.products!);
      currentProductIndex = widget.initialIndex ?? 0;
      _pageController = PageController(initialPage: currentProductIndex);
      _imagePageController = PageController();
      _currentImageIndex = 0;
      isLoadingRelated = false;
    } else {
      // Fallback to related product API
      _fetchRelatedProducts();
    }

    if (!ViewTracker.instance.isViewed(widget.product.id)) {
      _displayViews += 1;
      ViewTracker.instance.markViewed(widget.product.id);
      _registeredView = true;
    }

    _loadSellerName();
    _loadProductLocation();
    _fetchUniqueClicks();
    _fetchProductStatus(); // Fetch product status on init

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _favoritesService.addListener(_onFavoritesChanged);
    });
  }
  
  Future<String?> _fetchProductStatus() async {
    // Prevent multiple simultaneous fetches
    if (_isFetchingStatus) {
      debugPrint('Status fetch already in progress, skipping...');
      return _currentProductStatus;
    }
    
    if (!mounted) return null;
    
    try {
      _isFetchingStatus = true;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        _isFetchingStatus = false;
        return null;
      }
      
      // Get single product by ID
      final response = await http.get(
        Uri.parse('https://api.junctionverse.com/product/${widget.product.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final productData = jsonDecode(response.body);
        final String newStatus = productData['status']?.toString() ?? '';
        if (mounted) {
          setState(() {
            _currentProductStatus = newStatus;
          });
          // Return the status so we can check if polling should stop
          _isFetchingStatus = false;
          return newStatus;
        }
      }
      _isFetchingStatus = false;
      return null;
    } catch (e) {
      debugPrint('Error fetching product status: $e');
      _isFetchingStatus = false;
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
          debugPrint('Polling timeout reached (30s). Stopping status polling.');
          return;
        }
      }
      
      final String? status = await _fetchProductStatus();
      
      // Check if widget is still mounted after async operation
      if (!mounted) {
        timer.cancel();
        _statusPollingTimer = null;
        return;
      }
      
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

  void _resetReportState() {
    _selectedReportReasonCode = null;
    _reportNotesController.clear();
    _isSubmittingReport = false;
  }

  List<Widget> _buildAppBarActions(Product product, bool isSellerViewing) {
    final bool isLoggedIn = _chatService.currentUserId != null;
    final bool canReport = isLoggedIn && !isSellerViewing;

    if (!canReport) return const [];

    return [
      IconButton(
        icon: const Icon(Icons.flag_outlined, color: Color(0xFF262626)),
        tooltip: 'Report listing',
        onPressed: () => _openReportBottomSheet(product),
      ),
    ];
  }

  void _openReportBottomSheet(Product product) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Report listing',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              setState(_resetReportState);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Let us know what\'s wrong with this listing.',
                        style: TextStyle(color: Color(0xFF5F5F5F)),
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
                            selectedColor: const Color(0xFF262626),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF262626),
                              fontWeight: FontWeight.w500,
                            ),
                            backgroundColor: const Color(0xFFEDEDED),
                            onSelected: (_) {
                              setModalState(() {
                                _selectedReportReasonCode = code;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _reportNotesController,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          labelText: 'Additional details (optional)',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: _isSubmittingReport ? 'Submitting...' : 'Submit report',
                        onPressed: (_selectedReportReasonCode == null || _isSubmittingReport)
                            ? null
                            : () => _submitListingReport(
                                  product,
                                  sheetContext,
                                  setModalState,
                                ),
                        backgroundColor: const Color(0xFF262626),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(_resetReportState);
      } else {
        _resetReportState();
      }
    });
  }

  Future<void> _submitListingReport(
    Product product,
    BuildContext sheetContext,
    void Function(void Function())? refreshSheetState,
  ) async {
    if (_selectedReportReasonCode == null || _isSubmittingReport) return;

    void updateSubmitting(bool value) {
      if (mounted) {
        setState(() {
          _isSubmittingReport = value;
        });
      } else {
        _isSubmittingReport = value;
      }
      refreshSheetState?.call(() {});
    }

    updateSubmitting(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to report listings.')),
        );
        Navigator.of(sheetContext).pop();
        return;
      }

      final uri = Uri.parse(
          'https://api.junctionverse.com/product/products/${product.id}/report');
      final payload = {
        'reasonCode': _selectedReportReasonCode,
        if (_reportNotesController.text.trim().isNotEmpty)
          'reasonText': _reportNotesController.text.trim(),
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final int statusCode = response.statusCode;
      if (statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
        Navigator.of(sheetContext).pop();
        return;
      }

      if (statusCode == 200 || statusCode == 201) {
        final Map<String, dynamic> body =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final bool alreadyReported =
            body['alreadyReported'] == true || body['status'] == 'duplicate';

        Navigator.of(sheetContext).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                alreadyReported ? 'You already reported this listing.' : 'Thanks for the report. Our team will review it.'),
          ),
        );
        return;
      }

      final String errorMessage = () {
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          return body['message']?.toString();
        } catch (_) {
          return null;
        }
      }() ??
          'Something went wrong. Please try again later.';

      Navigator.of(sheetContext).pop();
      ErrorHandler.showErrorSnackBar(context, errorMessage);
    } catch (e) {
      Navigator.of(sheetContext).pop();
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      updateSubmitting(false);
    }
  }

  @override
  void dispose() {
    // Cancel timer first to prevent any async operations
    _statusPollingTimer?.cancel();
    _statusPollingTimer = null;
    _pollingStartTime = null;
    
    // Remove listener to prevent callbacks after dispose
    _favoritesService.removeListener(_onFavoritesChanged);
    
    // Dispose controllers
    _pageController?.dispose();
    _imagePageController?.dispose();
    _reportNotesController.dispose();
    
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {}); 
    }
  }

  Future<void> _loadSellerName() async {
    final name = widget.product.seller?.fullName;
    if (mounted) {
      setState(() {
        _sellerName = (name != null && name.isNotEmpty) ? name : 'Unknown Seller';
      });
    }
  }

  Future<void> _loadProductLocation() async {
    if ((widget.product.location == null || widget.product.location!.isEmpty) &&
        widget.product.latitude != null &&
        widget.product.longitude != null &&
        _cachedLocation == null &&
        !_isLoadingLocation) {
      setState(() => _isLoadingLocation = true);

      try {
        final location = await getAddressFromLatLng(
            widget.product.latitude!, widget.product.longitude!);
        if (mounted) {
          setState(() {
            _cachedLocation = location;
            _isLoadingLocation = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading location: $e');
        if (mounted) {
          setState(() {
            _cachedLocation = 'Location unavailable';
            _isLoadingLocation = false;
          });
          // Don't show error snackbar for location loading failures
          // as they're handled gracefully with fallback text
        }
      }
    }
  }

  Future<void> _toggleFavorite(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login to add favorites')));
      return;
    }

    try {
      if (_favoritesService.isFavorited(productId)) {
        final success = await _favoritesService.removeFromFavorites(productId);
        if (success) widget.onFavoriteChanged?.call();
      } else {
        final success = await _favoritesService.addToFavorites(productId);
        if (success) widget.onFavoriteChanged?.call();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _fetchRelatedProducts() async {
    if (!mounted) return;
    setState(() => isLoadingRelated = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() => isLoadingRelated = false);
        _setProductList([]);
      }
      return;
    }

    final uri =
        Uri.parse('https://api.junctionverse.com/product/related/${widget.product.id}');
    try {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (!mounted) return;
      
      if (response.statusCode != 200) {
        if (mounted) {
          setState(() => isLoadingRelated = false);
          _setProductList([]);
        }
        return;
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['products'] ?? [];

      final List<Product> fetched = data.map<Product>((item) {
        final map = Map<String, dynamic>.from(item);
        final List<ProductImage> imageList = (map['images'] as List?)
                ?.map((imgRaw) {
                  final img = Map<String, dynamic>.from(imgRaw);
                  return ProductImage(
                    fileUrl: img['fileUrl'] ?? 'assets/placeholder.png',
                    fileType: img['fileType'],
                    filename: img['filename'],
                  );
                }).toList() ??
            [];

        final Seller? seller = map['seller'] != null
            ? Seller.fromJson(Map<String, dynamic>.from(map['seller']))
            : null;

        return Product(
          id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
          images: imageList,
          imageUrl: imageList.isNotEmpty
              ? imageList.first.fileUrl
              : (map['imageUrl']?.toString() ?? 'assets/placeholder.png'),
          title: map['title']?.toString() ?? 'No title',
          price: map['price'] != null ? '₹${map['price']}' : null,
          description: map['description']?.toString(),
          location: map['pickupLocation']?.toString() ??
              map['locationName']?.toString(),
          seller: seller,
          isAuction: map['isAuction'] == true,
          views: int.tryParse((map['views'] ?? map['viewCount'] ?? '0').toString()) ?? 0,
        );
      }).toList();

      _setProductList(fetched);
    } catch (e) {
      debugPrint('Error fetching related products: $e');
      if (mounted) {
        setState(() => isLoadingRelated = false);
        _setProductList([]);
      }
    }
  }

  Future<void> _fetchUniqueClicks() async {
    // try {
    //   final clicks = await ProductClickService.getUniqueClicks(widget.product.id);
    //   if (mounted) {
    //     setState(() {
    //       _displayViews = (_registeredView ? _displayViews : clicks);
    //     });
    //   }
    // } catch (e) {
    //   debugPrint('Error fetching unique clicks: $e');
    // }
    final result = await ProductClickService.getUniqueClicksFor([widget.product.id]);
    if (mounted) {
      setState(() {
        _viewCount = result[widget.product.id] ?? 0;
      });
    }
  }

  void startChat(BuildContext context) async {
    final Product currentProduct = relatedProducts.isNotEmpty
        ? relatedProducts[currentProductIndex]
        : widget.product;

    if (currentProduct.seller?.id == _chatService.currentUserId) return;

    try {
      String sellerId = currentProduct.seller?.id ?? '';
      String buyerId = _chatService.currentUserId;
      String productId = currentProduct.id;
      String chatId = '${productId}_${sellerId}_$buyerId';
      final prefs = await SharedPreferences.getInstance();
      String buyerName = prefs.getString('fullName') ?? 'You';
      final token = prefs.getString('authToken');

      // Check if user is blocked before allowing chat
      if (token != null) {
        try {
          final blockCheckResponse = await http.get(
            Uri.parse('https://api.junctionverse.com/user/check-block/$sellerId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (blockCheckResponse.statusCode == 200) {
            final blockData = jsonDecode(blockCheckResponse.body);
            if (blockData['isBlocked'] == true) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You cannot chat with this user. They have been blocked.'),
                  duration: Duration(seconds: 3),
                ),
              );
              return; // Prevent chat from starting
            }
          }
        } catch (e) {
          debugPrint('Error checking block status: $e');
          // Continue with chat if block check fails (don't block legitimate users due to errors)
        }
      }

      bool exists = await _chatService.chatExists(chatId);
      if (!exists) {
        await _chatService.createChat(
          productId: productId,
          sellerId: sellerId,
          buyerId: buyerId,
          sellerName: currentProduct.seller?.fullName ?? 'Seller',
          buyerName: buyerName,
          productTitle: currentProduct.title,
          productImage: currentProduct.imageUrl ?? '',
          productPrice: currentProduct.price ?? '',
        );
      }

      Navigator.push(
        context,
        SlidePageRoute(
          page: ChatPage(chatId: chatId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refresh product status when build is called (e.g., when returning to page)
    // Only fetch if status is null, not already fetching, and haven't scheduled a fetch yet
    if (_currentProductStatus == null && !_isFetchingStatus && !_hasScheduledStatusFetch) {
      _hasScheduledStatusFetch = true;
      // Use a one-time callback to avoid multiple calls
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hasScheduledStatusFetch = false;
        if (mounted && _currentProductStatus == null && !_isFetchingStatus) {
          _fetchProductStatus();
        }
      });
    }
    
    if (isLoadingRelated || relatedProducts.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final product = relatedProducts[currentProductIndex];
    final bool isSellerViewing = product.seller?.id == _chatService.currentUserId;
    // Use current status if available, otherwise fallback to product.status
    final String productStatus = _currentProductStatus ?? product.status ?? 'For Sale';
    final bool isProductForSale = productStatus == 'For Sale';
    final bool isDealLocked = productStatus == 'Sold' || productStatus == 'Locked' || productStatus == 'Deal Locked';
    final bool isProductSold = productStatus == 'Sold';
    final bool isProductLocked = productStatus == 'Locked' || productStatus == 'Deal Locked';

    return Scaffold(
      appBar: CustomAppBar(
        title: product.title,
        actions: _buildAppBarActions(product, isSellerViewing),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: relatedProducts.length,
        onPageChanged: (index) {
          setState(() {
            currentProductIndex = index;
            _currentImageIndex = 0;
          });
          _imagePageController?.jumpToPage(0);
        },
        itemBuilder: (context, index) {
          final product = relatedProducts[index];
          return ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(context).padding.bottom + 80),
            children: [
              _buildPrimaryCard(product, isSellerViewing),

              const SizedBox(height: 16),

              _buildActionRow(product),

              const SizedBox(height: 16),


          // Description & Pickup Location
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Text(product.description ?? 'No description provided', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade300, thickness: 1),
                const SizedBox(height: 16),
                const Text('Pickup Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                _buildLocationText(product),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Deal Status Badge
          if (isProductSold)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
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

          // Related Products
          const Text('Related Products', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (isLoadingRelated)
            const Center(child: CircularProgressIndicator())
          else ...[
            Builder(
              builder: (context) {
                final current = product;
                final List<Product> candidates = relatedProducts
                    .where((p) =>
                        p.id != current.id &&
                        p.category != null &&
                        current.category != null &&
                        p.category == current.category &&
                        // Exclude products from the same seller
                        (p.seller?.id ?? '') != (current.seller?.id ?? ''))
                    .toList();
                if (candidates.isEmpty) {
                  return const EmptyState(text: 'No related products found.');
                }
                return ProductGridWidget(products: candidates);
              },
            ),
          ],
        ],
      );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isSellerViewing, isProductForSale, isDealLocked, isProductLocked, isProductSold),
    );
  }
Widget _buildBottomNavigationBar(bool isSellerViewing, bool isProductForSale, bool isDealLocked, bool isProductLocked, bool isProductSold) {
  return SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // For seller: Show "Mark as Sold" button (if product is not sold)
          // Only visible to seller, not to buyers
          if (isSellerViewing && !isProductSold)
            Expanded(
              child: AppButton(
                label: 'Mark as Sold',
                onPressed: isProductSold ? null : _showMarkAsSoldDialog,
                backgroundColor: isProductSold ? Colors.grey : const Color(0xFF262626),
                textColor: Colors.white,
              ),
            ),

          // Chat button - only for buyers (sellers don't see chat button)
          // Disabled for buyer if product is Sold
          if (!isSellerViewing)
            Expanded(
              child: AppButton(
                label: 'Chat',
                icon: Icons.chat_bubble_outline,
                onPressed: isProductSold ? null : () => startChat(context),
                backgroundColor: Colors.white,
                borderColor: isProductSold ? Colors.grey : const Color(0xFFE3E3E3),
                textColor: isProductSold ? Colors.grey : Colors.black,
              ),
            ),
        ],
      ),
    ),
  );
}


  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE3E3E3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
    );
  }

  Widget _buildPrimaryCard(Product product, bool isSellerViewing) {
     final sellerName = product.seller?.fullName?.isNotEmpty == true
         ? product.seller!.fullName!
         : (_sellerName ?? 'Unknown Seller');
     final sellerId = product.seller?.id ?? '';
 
     final imageUrls = product.images.isNotEmpty
         ? product.images.map((img) => img.fileUrl).whereType<String>().toList()
         : [(product.imageUrl?.isNotEmpty == true) ? product.imageUrl! : 'assets/placeholder.png'];
 
     final badgeChips = <Widget>[];
     if (product.yearOfPurchase != null) {
       final age = (DateTime.now().year - product.yearOfPurchase!).clamp(0, 99);
       badgeChips.add(_buildBadge('Age: < ${age.toInt()}Y'));
     }
     if ((product.usage ?? '').isNotEmpty) {
       badgeChips.add(_buildBadge('Usage: ${product.usage}'));
     }
     if ((product.condition ?? '').isNotEmpty) {
       badgeChips.add(_buildBadge('Condition: ${product.condition}'));
     }
 
     final controller = _imagePageController ??= PageController();
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (sellerId.isEmpty) return;
            if (sellerId == _chatService.currentUserId) {
              Navigator.push(context, SlidePageRoute(page: const UserProfilePage()));
            } else {
              Navigator.push(context, SlidePageRoute(page: OthersProfilePage(userId: sellerId)));
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black.withOpacity(0.08),
                    child: Text(
                      sellerName.isNotEmpty ? sellerName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    sellerName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Row(
                children: [
                  Image.asset('assets/ClockCountdown.png', width: 14, height: 14, color: const Color(0xFF8A8894)),
                  const SizedBox(width: 4),
                  Text(
                    product.createdAt != null ? _timeAgo(product.createdAt!) : '',
                    style: const TextStyle(color: Color(0xFF8A8894), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7E8ED)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: PageView.builder(
                    controller: controller,
                    itemCount: imageUrls.length,
                    onPageChanged: (value) {
                      setState(() => _currentImageIndex = value);
                    },
                    itemBuilder: (_, pageIndex) {
                      final url = imageUrls[pageIndex];
                      final isNetwork = url.startsWith('http');
                      return isNetwork
                          ? Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset('assets/placeholder.png', fit: BoxFit.cover),
                            )
                          : Image.asset(url, fit: BoxFit.cover);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (imageUrls.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(imageUrls.length, (index) {
                      final isActive = index == _currentImageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: isActive ? 18 : 6,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.black87 : const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badgeChips.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: badgeChips,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if ((product.category ?? '').isNotEmpty)
                      Text(
                        product.category!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8A8894)),
                      ),
                    if ((product.category ?? '').isNotEmpty) const SizedBox(height: 6),
                    Text(
                      product.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.price ?? '',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFFF6705)),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Image.asset('assets/Eye.png', width: 16, height: 16),
                        const SizedBox(width: 6),
                        Text('Viewed by $_viewCount others', style: const TextStyle(fontSize: 13, color: Color(0xFF8A8894))),
                        const Spacer(),
                        Image.asset('assets/MapPin.png', width: 16, height: 16),
                        const SizedBox(width: 6),
                        Expanded(child: _buildLocationText(product)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(Product product) {
    final isFav = _favoritesService.isFavorited(product.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E8ED)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _favoritesService.isLoading ? null : () => _toggleFavorite(product.id),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_favoritesService.isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? const Color(0xFFFF6705) : Colors.black87,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    isFav ? 'Favourited' : 'Favourite',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFFE7E8ED)),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.share_outlined, color: Colors.black87),
                  SizedBox(width: 8),
                  Text('Share', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationText(Product product) {
    if (product.location != null && product.location!.isNotEmpty) {
      return Text(product.location!, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    if (_cachedLocation != null && _cachedLocation != 'Location unavailable') {
      return Text(_cachedLocation!, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    if (_isLoadingLocation) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey))),
          SizedBox(width: 8),
          Text('Loading location...', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      );
    }
    return const Text('Location not set', style: TextStyle(fontSize: 14, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return '${diff.inHours} hour(s) ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minute(s) ago';
    return 'Just now';
  }

  void _showMarkAsSoldDialog() {
    // Prevent opening dialog if product is already sold
    final String currentStatus = _currentProductStatus ?? widget.product.status ?? 'For Sale';
    if (currentStatus == 'Sold') {
      ErrorHandler.showErrorSnackBar(
        context,
        null,
        customMessage: 'Product is already marked as sold.',
      );
      return;
    }
    
    // Check if product is locked
    final bool isProductLocked = currentStatus == 'Locked' || currentStatus == 'Deal Locked';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Initialize state variables inside the builder
        String? selectedOption = isProductLocked ? 'junction' : null;
        List<dynamic>? chats;
        Map<String, dynamic>? selectedChat;
        bool isLoadingChats = false;
        bool hasInitializedChats = false;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Initialize chats if product is locked and Junction is pre-selected
            if (isProductLocked && selectedOption == 'junction' && !hasInitializedChats && !isLoadingChats) {
              setModalState(() {
                isLoadingChats = true;
                hasInitializedChats = true;
              });
              _fetchProductChats().then((fetchedChats) {
                final chatsWithOrders = fetchedChats
                    .where((chat) => chat['orderId'] != null && chat['orderId'].toString().isNotEmpty)
                    .toList();
                setModalState(() {
                  chats = chatsWithOrders;
                  isLoadingChats = false;
                });
              }).catchError((e) {
                setModalState(() {
                  chats = [];
                  isLoadingChats = false;
                });
              });
            }
          
          // Determine if Mark as Sold button should be enabled
          bool canMarkAsSold = false;
          if (isProductLocked) {
            // If product is locked, only allow Junction option
            if (selectedOption == 'junction' && selectedChat != null && chats != null && chats!.isNotEmpty) {
              canMarkAsSold = true;
            }
          } else {
            // If product is not locked, allow both options
            if (selectedOption == 'outside') {
              canMarkAsSold = true;
            } else if (selectedOption == 'junction' && selectedChat != null && chats != null && chats!.isNotEmpty) {
              canMarkAsSold = true;
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Did you sell the Product in Junction or Outside?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                RadioListTile<String>(
                  title: const Text('Junction'),
                  value: 'junction',
                  groupValue: selectedOption,
                  onChanged: (value) async {
                    setModalState(() {
                      selectedOption = value;
                      selectedChat = null;
                      chats = null;
                      isLoadingChats = true;
                      hasInitializedChats = false;
                    });
                    
                    // Fetch chats when Inside Junction is selected
                    try {
                      final fetchedChats = await _fetchProductChats();
                      final chatsWithOrders = fetchedChats
                          .where((chat) => chat['orderId'] != null && chat['orderId'].toString().isNotEmpty)
                          .toList();
                      
                      setModalState(() {
                        chats = chatsWithOrders;
                        isLoadingChats = false;
                        hasInitializedChats = true;
                      });
                    } catch (e) {
                      setModalState(() {
                        chats = [];
                        isLoadingChats = false;
                        hasInitializedChats = true;
                      });
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Outside Junction'),
                  value: 'outside',
                  groupValue: selectedOption,
                  onChanged: isProductLocked 
                      ? null 
                      : (value) {
                          setModalState(() {
                            selectedOption = value;
                            selectedChat = null;
                            chats = null;
                            hasInitializedChats = false;
                          });
                        },
                  subtitle: isProductLocked 
                      ? const Text(
                          'Product has a locked deal. Please sell within Junction.',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        )
                      : null,
                ),
                
                // Show dropdown for Inside Junction
                if (selectedOption == 'junction') ...[
                  const SizedBox(height: 16),
                  if (isLoadingChats)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (chats == null)
                    const SizedBox.shrink()
                  else if (chats!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'No locked deals found. Please lock a deal with a buyer first.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          isExpanded: true,
                          hint: const Text('Select Buyer'),
                          value: selectedChat,
                          items: chats!.map((chat) {
                            final buyerName = chat['buyerName'] ?? 'Unknown Buyer';
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: chat as Map<String, dynamic>,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    buyerName,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  if (chat['orderId'] != null)
                                    Text(
                                      'Order: ${chat['orderId']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              selectedChat = value;
                            });
                          },
                        ),
                      ),
                    ),
                ],
                
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.pop(context),
                        backgroundColor: Colors.white,
                        textColor: const Color(0xFF262626),
                        borderColor: const Color(0xFF262626),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Mark as Sold',
                        onPressed: canMarkAsSold
                            ? () async {
                                // Double-check product status before marking as sold
                                final String currentStatus = _currentProductStatus ?? widget.product.status ?? 'For Sale';
                                if (currentStatus == 'Sold') {
                                  Navigator.pop(context);
                                  ErrorHandler.showErrorSnackBar(
                                    context,
                                    null,
                                    customMessage: 'Product is already marked as sold.',
                                  );
                                  return;
                                }
                                
                                Navigator.pop(context);
                                
                                if (selectedOption == 'junction' && selectedChat != null) {
                                  final buyerId = selectedChat!['buyerId'] ?? '';
                                  final orderId = selectedChat!['orderId'];
                                  await _markProductAsSoldWithBuyer(buyerId, orderId);
                                } else if (selectedOption == 'outside') {
                                  await _markProductAsSoldOutside();
                                }
                              }
                            : null,
                        backgroundColor: canMarkAsSold ? const Color(0xFF262626) : Colors.grey,
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
          },
        );
      },
    );
  }

  void _showUserRating() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AnimatedScale(
          scale: 1.0,
          duration: Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: AlertDialog(
            title: const Text('Rate User'),
            content: const Text('Rate your experience with this seller.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: AppButton(
                  label: 'Submit Rating',
                  onPressed: () {
                    Navigator.of(context).pop();
                    _rateUser();
                  },
                  backgroundColor: const Color(0xFFFF6705),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<dynamic>> _fetchProductChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null) {
        ErrorHandler.showErrorSnackBar(context, Exception('Please login to perform this action'));
        return [];
      }

      final response = await http.get(
        Uri.parse('https://api.junctionverse.com/chats/product-chats?productId=${widget.product.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> chats = data['chats'] ?? [];
        return chats;
      } else {
        ErrorHandler.showErrorSnackBar(context, null, response: response);
        return [];
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
      return [];
    }
  }


  Future<void> _markProductAsSoldWithBuyer(String buyerId, String? orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null) {
        ErrorHandler.showErrorSnackBar(context, Exception('Please login to perform this action'));
        return;
      }

      final response = await http.post(
        Uri.parse('https://api.junctionverse.com/product/mark-sold'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'orderId': orderId,
          'soldInJunction': true,
        }),
      );

      if (response.statusCode == 200) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Product marked as sold successfully!',
        );
        // Start polling for status updates
        _startStatusPolling();
        // Also do an immediate refresh
        await _fetchProductStatus();
        if (mounted) {
          setState(() {});
        }
      } else {
        ErrorHandler.showErrorSnackBar(context, null, response: response);
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _markProductAsSoldOutside() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null) {
        ErrorHandler.showErrorSnackBar(context, Exception('Please login to perform this action'));
        return;
      }

      final response = await http.post(
        Uri.parse('https://api.junctionverse.com/product/mark-sold'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'productId': widget.product.id,
          'soldInJunction': false,
        }),
      );

      if (response.statusCode == 200) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Product marked as sold successfully!',
        );
        // Start polling for status updates
        _startStatusPolling();
        // Also do an immediate refresh
        await _fetchProductStatus();
        if (mounted) {
          setState(() {});
        }
      } else {
        ErrorHandler.showErrorSnackBar(context, null, response: response);
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _rateUser() async {
    try {
      // Call API to rate user
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to perform this action')),
        );
        return;
      }

      // For now, just show a success message
      ErrorHandler.showSuccessSnackBar(
        context,
        'Rating submitted successfully!',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }
}
