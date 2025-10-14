import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

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

  Future<void> _updateProfileImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Choose Image Source"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text("Camera"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text("Gallery"),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(source: source);
      if (!mounted) return;
      if (pickedFile == null) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (!mounted) return;
      if (token == null) return;

      final uri = Uri.parse('https://api.junctionverse.com/user/update-profile-image');
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('profileImage', pickedFile.path));

      final response = await request.send();
      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);
        
        // Add null safety checks
        if (data is Map<String, dynamic> && 
            data['user'] is Map<String, dynamic> &&
            data['user']['selfieUrl'] is String) {
          final updatedUser = data['user'] as Map<String, dynamic>;
          final newProfileImage = updatedUser['selfieUrl'] as String;
          
          if (mounted) {
            setState(() {
              profileImage = newProfileImage;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile image updated successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid response from server')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile image: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
            profileImage.isNotEmpty
                ? Image.network(
                    profileImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: backgroundColor);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(color: backgroundColor);
                    },
                  )
                : Container(color: backgroundColor),
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
                          profileImage.isNotEmpty
                              ? CircleAvatar(
                                  radius: 36,
                                  backgroundColor: backgroundColor,
                                  child: ClipOval(
                                    child: Image.network(
                                      profileImage,
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
                              : CircleAvatar(
                                  radius: 36,
                                  backgroundColor: backgroundColor,
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _updateProfileImage,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Image.asset(
                                  'assets/edit.png',
                                  width: 16,
                                  height: 16,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.edit, size: 16);
                                  },
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
                      location,
                      style: const TextStyle(
                        color: Color(0xFFE3E3E3),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                    ),
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
                        SizedBox(
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