import 'dart:ui';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/products_grid.dart';
import '../../widgets/bottom_navbar.dart';
import '../profile/empty_state.dart';
import 'active_listing.dart';
import 'about_repository.dart';
import 'about.dart';

class OthersProfilePage extends StatefulWidget {
  final String userId;
  const OthersProfilePage({super.key, required this.userId});

  @override
  State<OthersProfilePage> createState() => _OthersProfilePageState();
}

class _OthersProfilePageState extends State<OthersProfilePage> {
  bool _isLoading = true;
  String name = 'User';
  String university = '';
  String location = '';
  String profileImage = '';

  int selectedTabIndex = 0;
  List<Product> activeListings = [];
  bool _loadingActive = true;

  Color get _baseColor {
    final hash = name.hashCode;
    final r = ((hash & 0xFF0000) >> 16).clamp(40, 220);
    final g = ((hash & 0x00FF00) >> 8).clamp(40, 220);
    final b = (hash & 0x0000FF).clamp(40, 220);
    return Color.fromRGBO(r, g, b, 1);
  }

  Color _darken(Color color, [double amount = .1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(math.max(0, hsl.lightness - amount)).toColor();
  }

  Color _lighten(Color color, [double amount = .1]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(math.min(1, hsl.lightness + amount)).toColor();
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _loadingActive = true;
    });

    try {
      final results = await Future.wait([
        ActiveListingRepository.fetchActiveListings(userId: widget.userId),
        AboutRepository.fetchAboutData(userId: widget.userId),
      ]);

      if (!mounted) return;

      final listings = results[0] as List<Product>;
      final aboutSummary = results[1] as AboutSummary;

      final user = aboutSummary.user;
      setState(() {
        activeListings = listings;

        if (user != null) {
          final resolvedName = (user['name']?.toString() ?? user['fullName']?.toString() ?? '').trim();
          if (resolvedName.isNotEmpty) {
            name = resolvedName;
          }
          university = _extractUniversity(user['university']) ?? university;
          
          // Location handling: backend may return full address in 'location' field, or just an ID
          final locationField = user['location']?.toString();
          if (locationField != null && locationField.isNotEmpty) {
            // Check if location is a UUID (ID) - UUIDs have a specific format
            final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(locationField);
            if (!isUuid) {
              // It's a full address string, use it directly
              location = locationField;
            } else {
              // It's an ID, try to extract from addressJson
              final extractedLocation = _extractLocationFromAddressJson(user);
              if (extractedLocation != null && extractedLocation.isNotEmpty) {
                location = extractedLocation;
              }
            }
          } else {
            // No location field, try to extract from addressJson
            final extractedLocation = _extractLocationFromAddressJson(user);
            if (extractedLocation != null && extractedLocation.isNotEmpty) {
              location = extractedLocation;
            }
          }
          
          profileImage = user['profileImage']?.toString() ?? profileImage;
        }
        if (profileImage.isEmpty && listings.isNotEmpty) {
          profileImage = listings.first.imageUrl;
        }

        _loadingActive = false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('OthersProfilePage: failed to load data $e');
      if (!mounted) return;
      setState(() {
        _loadingActive = false;
        _isLoading = false;
      });
    }
  }

  String getReadableLocation(String fullAddress) {
    if (fullAddress.isEmpty) return '';
    
    // Split by commas and trim spaces
    final parts = fullAddress.split(',').map((p) => p.trim()).toList();
    
    // Remove any part that starts with a number (likely a street number)
    final filteredParts = parts.where((p) => !RegExp(r'^\d').hasMatch(p)).toList();
    
    if (filteredParts.isEmpty) return fullAddress;

    // Format as "area, city or state"
    if (filteredParts.length >= 3) {
      // Last 3 parts: area, city, state -> "area, city or state"
      final area = filteredParts[filteredParts.length - 3];
      final city = filteredParts[filteredParts.length - 2];
      final state = filteredParts[filteredParts.length - 1];
      return '$area, $city, $state';
    } else if (filteredParts.length >= 2) {
      // Last 2 parts: city, state -> "city or state"
      final city = filteredParts[filteredParts.length - 2];
      final state = filteredParts[filteredParts.length - 1];
      return '$city,  $state';
    } else {
      // Single part: just return it
      return filteredParts.first;
    }
  }

  String? _extractUniversity(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      final parts = <String?>[
        value['name']?.toString(),
        value['department']?.toString(),
      ].whereType<String>().where((e) => e.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }
    return null;
  }

  String? _extractLocation(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      final parts = <String?>[
        value['city']?.toString(),
        value['state']?.toString(),
        value['country']?.toString(),
      ].whereType<String>().where((e) => e.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }
    return null;
  }

  String? _extractLocationFromAddressJson(Map<String, dynamic> user) {
    final homeAddressId = user['homeAddress'];
    dynamic addressJson = user['addressJson'];

    if (addressJson == null) {
      debugPrint('OthersProfilePage: addressJson is null');
      return null;
    }

    // Parse addressJson if it's a string
    if (addressJson is String) {
      try {
        addressJson = jsonDecode(addressJson);
        debugPrint('OthersProfilePage: Parsed addressJson from string');
      } catch (e) {
        debugPrint('OthersProfilePage: Failed to parse addressJson string: $e');
        return null;
      }
    }

    if (addressJson is! List) {
      debugPrint('OthersProfilePage: addressJson is not a List, type: ${addressJson.runtimeType}');
      return null;
    }

    if (addressJson.isEmpty) {
      debugPrint('OthersProfilePage: addressJson is empty');
      return null;
    }

    // Find the address matching the homeAddress ID
    dynamic selectedAddress;
    if (homeAddressId != null && homeAddressId is String) {
      try {
        selectedAddress = addressJson.firstWhere(
          (addr) => addr['id'] == homeAddressId,
          orElse: () => addressJson.isNotEmpty ? addressJson[0] : null,
        );
        debugPrint('OthersProfilePage: Found address with ID: $homeAddressId');
      } catch (e) {
        debugPrint('OthersProfilePage: Address ID not found, using first address: $e');
        selectedAddress = addressJson.isNotEmpty ? addressJson[0] : null;
      }
    } else {
      debugPrint('OthersProfilePage: No homeAddressId, using first address');
      selectedAddress = addressJson[0];
    }

    if (selectedAddress != null && selectedAddress['address'] != null) {
      final address = selectedAddress['address'].toString();
      debugPrint('OthersProfilePage: Extracted location: $address');
      return address;
    }

    debugPrint('OthersProfilePage: No address found in selectedAddress');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    String? bgImage;
    if (profileImage.isNotEmpty) {
      bgImage = profileImage;
    } else if (activeListings.isNotEmpty && activeListings.first.imageUrl.isNotEmpty) {
      bgImage = activeListings.first.imageUrl;
    }

    final Widget content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bgImage != null) ...[
                  Image.network(
                    bgImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_darken(_baseColor, 0.5), _darken(_baseColor, 0.2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                    child: Container(color: Colors.black.withOpacity(0.5)),
                  ),
                ] else ...[
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_darken(_baseColor, 0.5), _darken(_baseColor, 0.2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                    child: Container(color: Colors.black.withOpacity(0.4)),
                  ),
                ],
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: _darken(_baseColor, 0.4),
                            child: ClipOval(
                              child: (bgImage != null)
                                  ? Image.network(
                                      bgImage,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    )
                                  : Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
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
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/univ.png', width: 14, errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 14, color: Color(0xFFE3E3E3))),
                        const SizedBox(width: 4),
                        Text(
                          university.isNotEmpty ? university : '—',
                          style: const TextStyle(color: Color(0xFFE3E3E3), fontWeight: FontWeight.w500, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Image.asset('assets/loc.png', width: 14, errorBuilder: (_, __, ___) => const Icon(Icons.location_on, size: 14, color: Color(0xFFE3E3E3))),
                        const SizedBox(width: 4),
                        Text(
                          location.isNotEmpty ? getReadableLocation(location) : '—',
                          style: const TextStyle(color: Color(0xFFE3E3E3), fontWeight: FontWeight.w500, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                            Container(
                              height: 50,
                              padding: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                children: [
                                  _buildTab('Active Listings', selectedTabIndex == 0, () => setState(() => selectedTabIndex = 0)),
                                  _buildTab('About', selectedTabIndex == 1, () => setState(() => selectedTabIndex = 1)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: selectedTabIndex == 0
                                  ? _buildActiveListings()
                                  : _buildAboutSection(),
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

    return BottomNavWrapper(
      activeItem: 'profile',
      onTap: (_) {},
      child: Scaffold(
        body: content,
      ),
    );
  }

  Widget _buildActiveListings() {
    if (_loadingActive) {
      return const Center(child: CircularProgressIndicator());
    }
    if (activeListings.isEmpty) {
      return const EmptyState(text: 'No active listings yet');
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: ProductGridWidget(products: activeListings),
    );
  }

  Widget _buildAboutSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AboutTab(userId: widget.userId),
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
