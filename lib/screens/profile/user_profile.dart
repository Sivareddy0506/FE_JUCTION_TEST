import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import './active_listing.dart';
import './purchased.dart';
import './sold.dart';
import './about.dart';
import './favourites.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/bottom_navbar.dart';
import '../../services/favorites_service.dart';
import '../../services/profile_service.dart';
import 'account_settings_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String name = 'Loading...';
  String university = 'Loading...';
  String location = 'Loading...';
  String profileImage = '';
  bool isLoading = true;
  int selectedTabIndex = 0;
  
  // Image upload state
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;
  String? _localImagePath; // For immediate preview

  // Separate flags for different data sources
  bool _favoritesReady = false;
  bool _profileReady = false;
  bool _activeListingsReady = false;
  bool _isFirstLoad = true; // Track if this is the first load
  
  // Computed getter to check if all data is ready
  bool get _allDataReady => _favoritesReady && _profileReady && _activeListingsReady; // Wait for all data on first load

  final List<String> tabs = [
    'Active Listings',
    'About',
    'Purchases',
    'Sold',
    'Favorites'
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('UserProfilePage: Starting initialization');
    
    // Check if profile is already cached
    final isProfileCached = await ProfileService.isProfileCached();
    
    if (!mounted) return;
    
    if (isProfileCached) {
      // If profile is cached, show structure immediately (like before)
      setState(() {
        _profileReady = true;
        _isFirstLoad = false;
      });
      debugPrint('UserProfilePage: Profile cached, showing structure immediately');
    }
    
    // Load favorites and profile data in parallel
    await Future.wait([
      _initializeFavorites(),
      _initializeProfile(),
    ]);
    
    if (!mounted) return;
    
    // For first load, also wait for active listings to load
    if (_isFirstLoad) {
      await _initializeActiveListings();
    } else {
      // For cached loads, don't wait for active listings
      if (mounted) {
        setState(() {
          _activeListingsReady = true;
        });
      }
    }
    
    debugPrint('UserProfilePage: All initialization completed');
  }

  Future<void> _initializeFavorites() async {
    debugPrint('UserProfilePage: Initializing favorites service');
    try {
      await FavoritesService().initialize();
      if (mounted) {
        setState(() {
          _favoritesReady = true;
        });
      }
      debugPrint('UserProfilePage: Favorites service initialized successfully');
    } catch (e) {
      debugPrint('UserProfilePage: Error initializing favorites service - $e');
      if (mounted) {
        setState(() {
          _favoritesReady = true; // Set to true even on error to prevent infinite loading
        });
      }
    }
  }

  Future<void> _initializeProfile() async {
    debugPrint('UserProfilePage: Loading profile data');
    try {
      await _loadUserProfile();
      if (mounted) {
        setState(() {
          _profileReady = true;
        });
      }
      debugPrint('UserProfilePage: Profile data loaded successfully');
    } catch (e) {
      debugPrint('UserProfilePage: Error loading profile data - $e');
      if (mounted) {
        setState(() {
          _profileReady = true; // Set to true even on error to prevent infinite loading
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ProfileService.getUserProfileWithCache();
      if (profile != null && mounted) {
        setState(() {
          name = profile.name;
          university = profile.university;
          location = profile.location;
          profileImage = profile.profileImage;
        });
        
        // Preload the profile image to ensure it's ready before showing UI
        if (profile.profileImage.isNotEmpty) {
          await _preloadProfileImage(profile.profileImage);
        }
      }
    } catch (e) {
      debugPrint("ProfileService: Error loading profile - $e");
    }
  }

  Future<void> _clearImageCache(String imageUrl) async {
    try {
      // Clear the image from Flutter's image cache
      await NetworkImage(imageUrl).evict();
      debugPrint('UserProfilePage: Cleared image cache for: $imageUrl');
    } catch (e) {
      debugPrint('UserProfilePage: Error clearing image cache - $e');
    }
  }

  Future<void> _preloadProfileImage(String imageUrl) async {
    ImageStreamListener? listener;
    try {
      debugPrint('UserProfilePage: Preloading profile image: $imageUrl');
      
      // Create a Completer to track when the image is fully loaded
      final completer = Completer<void>();
      
      // Create an ImageStreamListener to track when the image is ready
      final imageStream = NetworkImage(imageUrl).resolve(ImageConfiguration.empty);
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          debugPrint('UserProfilePage: Profile image fully loaded and ready');
          if (!completer.isCompleted) completer.complete();
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          debugPrint('UserProfilePage: Error loading profile image - $exception');
          if (!completer.isCompleted) completer.complete();
        }
      );
      
      imageStream.addListener(listener);
      
      // Wait for the image to be fully loaded
      await completer.future;
      
      // Clean up listener
      imageStream.removeListener(listener);
      
      debugPrint('UserProfilePage: Profile image preloaded successfully');
    } catch (e) {
      debugPrint('UserProfilePage: Error preloading profile image - $e');
    } finally {
      // Ensure listener is removed even if exception occurs
      if (listener != null) {
        try {
          final imageStream = NetworkImage(imageUrl).resolve(ImageConfiguration.empty);
          imageStream.removeListener(listener);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    }
  }

  Future<void> _initializeActiveListings() async {
    debugPrint('UserProfilePage: Loading active listings data');
    try {
      // Actually fetch and process the active listings data to ensure it's fully loaded
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      if (!mounted) return;
      
      if (token != null) {
        final uri = Uri.parse('https://api.junctionverse.com/product/active');
        final response = await http.get(uri, headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });
        
        if (!mounted) return;
        
        if (response.statusCode == 200) {
          debugPrint('UserProfilePage: Active listings API call successful');
          
          // Parse and process the response to ensure data is ready
          final dynamic decoded = jsonDecode(response.body);
          final List<dynamic> data = () {
            if (decoded == null) return <dynamic>[];
            if (decoded is List) return decoded;
            if (decoded is Map<String, dynamic>) {
              if (decoded['products'] is List) return decoded['products'];
              if (decoded['data'] is List) return decoded['data'];
              if (decoded['items'] is List) return decoded['items'];
              final found = decoded.values.firstWhere(
                (v) => v is List,
                orElse: () => <dynamic>[],
              );
              return found is List ? found : <dynamic>[];
            }
            return <dynamic>[];
          }();
          
          debugPrint('UserProfilePage: Processed ${data.length} active listings');
        } else {
          debugPrint('UserProfilePage: Active listings API call failed with status ${response.statusCode}');
        }
      }
      
      if (mounted) {
        setState(() {
          _activeListingsReady = true;
        });
      }
      debugPrint('UserProfilePage: Active listings data loaded successfully');
    } catch (e) {
      debugPrint('UserProfilePage: Error loading active listings data - $e');
      if (mounted) {
        setState(() {
          _activeListingsReady = true; // Set to true even on error to prevent infinite loading
        });
      }
    }
  }

  String getReadableLocation(String fullAddress) {
  if (fullAddress.isEmpty) return '';

  // Split by commas and trim spaces
  final parts = fullAddress.split(',').map((p) => p.trim()).toList();

  // Remove any part that starts with a number (likely a street number)
  final filteredParts = parts.where((p) => !RegExp(r'^\d').hasMatch(p)).toList();

  if (filteredParts.isEmpty) return fullAddress; // fallback

  // Take last 2-3 parts for area, city/state
  if (filteredParts.length >= 3) {
    return '${filteredParts[filteredParts.length - 3]}, ${filteredParts[filteredParts.length - 2]}, ${filteredParts[filteredParts.length - 1]}';
  } else if (filteredParts.length >= 2) {
    return '${filteredParts[filteredParts.length - 2]}, ${filteredParts[filteredParts.length - 1]}';
  } else {
    return filteredParts.join(', ');
  }
}


  Future<void> _updateProfileImage() async {
    // Add haptic feedback for better user experience
    await HapticFeedback.lightImpact();
    
    final picker = ImagePicker();
  final source = await showModalBottomSheet<ImageSource>(
  context: context,
  isScrollControlled: true, // 👈 allows full height if needed
  backgroundColor: Colors.transparent,
  builder: (context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // 👈 avoids overflow
      ),
      child: SingleChildScrollView(
        child: Container(
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
                    'Update Profile Picture',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to update your profile picture',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageSourceOption(
                          icon: Icons.camera_alt_rounded,
                          label: 'Camera',
                          onTap: () => Navigator.pop(context, ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildImageSourceOption(
                          icon: Icons.photo_library_rounded,
                          label: 'Gallery',
                          onTap: () => Navigator.pop(context, ImageSource.gallery),
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
      ),
    );
  },
);


    if (!mounted) return;
    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(source: source);
      if (!mounted) return;
      if (pickedFile == null) return;

      // Show immediate local preview
      if (mounted) {
        setState(() {
          _localImagePath = pickedFile.path;
          _isUploadingImage = true;
          _uploadProgress = 0.0;
        });
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (!mounted) return;
      if (token == null) return;

      final uri = Uri.parse('https://api.junctionverse.com/user/update-profile-image');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('profileImage', pickedFile.path));

      // Simulate upload progress
      final streamedResponse = await request.send();
      if (!mounted) return;

      // Update progress during upload
      if (mounted) {
        setState(() {
          _uploadProgress = 0.5; // Halfway through
        });
      }

     if (streamedResponse.statusCode == 200) {
  final responseBody = await streamedResponse.stream.bytesToString();
  final data = jsonDecode(responseBody);

  if (data is Map<String, dynamic> &&
      data['user'] is Map<String, dynamic> &&
      data['user']['selfieUrl'] is String) {
    final updatedUser = data['user'] as Map<String, dynamic>;
    final newProfileImage = updatedUser['selfieUrl'] as String;

    debugPrint('Profile image uploaded: $newProfileImage');

    // ✅ Step 1: Preload the new image before updating state
    await _preloadProfileImage(newProfileImage);

    // ✅ Step 2: Then update state seamlessly
    if (mounted) {
      setState(() {
        profileImage = newProfileImage;
        _isUploadingImage = false;
        _uploadProgress = 1.0;
        // Keep _localImagePath visible until swap is complete
      });
    }

    // ✅ Step 3: Small delay to ensure paint completes before clearing preview
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      setState(() {
        _localImagePath = null; // now safe to clear
      });
    }

    // ✅ Step 4: Cache updates (doesn't trigger rebuilds)
    final updatedProfile = UserProfile(
      name: name,
      university: university,
      location: location,
      profileImage: newProfileImage,
    );
    await ProfileService.updateProfileCache(updatedProfile);

    // ✅ Step 5: Success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Profile image updated successfully'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
 else {
        if (mounted) {
          setState(() {
            _localImagePath = null;
            _isUploadingImage = false;
            _uploadProgress = 0.0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile image: ${streamedResponse.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      if (mounted) {
        setState(() {
          _localImagePath = null;
          _isUploadingImage = false;
          _uploadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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

  Color _generateColorFromName(String name) {
    final hash = name.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = (hash & 0x0000FF);
    return Color.fromRGBO(r, g, b, 1);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('UserProfilePage: build called. _allDataReady=$_allDataReady, _favoritesReady=$_favoritesReady, _profileReady=$_profileReady, _activeListingsReady=$_activeListingsReady, _isFirstLoad=$_isFirstLoad');
    
    final backgroundColor = _generateColorFromName(name);
    
    Widget content;
    
    if (!_allDataReady) {
      // Show full-screen loader on first load or when data isn't ready
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      content = SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            (_localImagePath != null && _isUploadingImage)
                ? Image.file(
                    File(_localImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.transparent);
                    },
                  )
                : profileImage.isNotEmpty
                    ? Image.network(
                        profileImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.transparent);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.transparent,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(color: Colors.transparent),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      Stack(
                        children: [
                          // Show local image if uploading, otherwise show network image
                          (_localImagePath != null && _isUploadingImage)
                              ? CircleAvatar(
                                  radius: 36,
                                  backgroundColor: Colors.transparent,
                                  child: ClipOval(
                                    child: Image.file(
                                      File(_localImagePath!),
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                )
                              : profileImage.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 36,
                                      backgroundColor: Colors.transparent,
                                      child: ClipOval(
                                        child: Image.network(
                                          profileImage,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              width: 72,
                                              height: 72,
                                              decoration: const BoxDecoration(
                                                color: Colors.transparent,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                  strokeWidth: 2,
                                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : '',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 36,
                                      backgroundColor: Colors.transparent,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                          // Upload progress indicator - removed for seamless transition
                          // if (_isUploadingImage)
                          //   Positioned.fill(
                          //     child: Container(
                          //       decoration: BoxDecoration(
                          //         shape: BoxShape.circle,
                          //         color: Colors.black.withOpacity(0.3),
                          //       ),
                          //       child: Center(
                          //         child: Stack(
                          //           alignment: Alignment.center,
                          //           children: [
                          //             SizedBox(
                          //               width: 40,
                          //               height: 40,
                          //               child: CircularProgressIndicator(
                          //                 value: _uploadProgress,
                          //                 strokeWidth: 3,
                          //                 backgroundColor: Colors.white.withOpacity(0.3),
                          //                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          //               ),
                          //             ),
                          //             Text(
                          //               '${(_uploadProgress * 100).toInt()}%',
                          //               style: const TextStyle(
                          //                 color: Colors.white,
                          //                 fontSize: 10,
                          //                 fontWeight: FontWeight.bold,
                          //               ),
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //     ),
                          //   ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isUploadingImage ? null : _updateProfileImage,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _isUploadingImage ? Colors.grey[300] : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/edit.png',
                                      width: 18,
                                      height: 18,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.edit, 
                                          size: 18, 
                                          color: _isUploadingImage ? Colors.grey : Colors.black
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
                          );
                        },
                        icon: Image.asset(
                          'assets/settings.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.settings, size: 24, color: Colors.white);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFFF9F9F9),
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    height: 36 / 28,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/univ.png',
                      width: 14,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.school, size: 14, color: Color(0xFFE3E3E3));
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      university,
                      style: const TextStyle(
                        color: Color(0xFFE3E3E3),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/loc.png',
                      width: 14,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.location_on, size: 14, color: Color(0xFFE3E3E3));
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
  getReadableLocation(location),
  style: const TextStyle(
    color: Color(0xFFE3E3E3),
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 16 / 12,
  ),
)

                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // SizedBox(
                        //   height: 40,
                        //   child: ListView.builder(
                        //     scrollDirection: Axis.horizontal,
                        //     padding: const EdgeInsets.symmetric(horizontal: 12),
                        //     itemCount: tabs.length,
                        //     itemBuilder: (context, index) {
                        //       return _buildTab(
                        //         tabs[index],
                        //         selectedTabIndex == index,
                        //         () => setState(() => selectedTabIndex = index),
                        //       );
                        //     },
                        //   ),
                        // ),
                        ClipRRect(
  borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(40),
    topRight: Radius.circular(40),
  ),
  child: Container(
    color: Colors.white,
    height: 40,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: tabs.length,
      itemBuilder: (context, index) {
        return _buildTab(
          tabs[index],
          selectedTabIndex == index,
          () => setState(() => selectedTabIndex = index),
        );
      },
    ),
  ),
),

                        Expanded(
                          child: Builder(
                            builder: (context) {
                              switch (selectedTabIndex) {
                                case 0:
                                  return ActiveAuctionsTab(
                                    hideLoadingIndicator: !_allDataReady,
                                    startLoading: _allDataReady, // Only start loading when parent is ready
                                  );
                                case 1:
                                  return const AboutTab();
                                case 2:
                                  return const PurchasedTab();
                                case 3:
                                  return const SoldTab();
                                case 4:
                                  return const FavoritesTab(); // Or EmptyState widget
                                default:
                                  return const Center(child: Text("Invalid Tab"));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return BottomNavWrapper(
      activeItem: 'Profile',
      onTap: (selected) => print("Tapped on $selected"),
      child: Container(
        color: !_allDataReady ? Colors.white : const Color(0xFF121212),
        child: content,
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF262626) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E3E3)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF212121),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}