import 'dart:async';
import 'package:flutter/material.dart';
import 'package:junction/screens/products/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_overview.dart';  
import '../widgets/app_button.dart';
import '../services/app_cache_service.dart';
import '../services/memory_monitor_service.dart';
import 'services/api_service.dart';
import 'login/login_page.dart';
import '../app.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMainContent = false;
  bool _isFirstTime = true;
  bool _isInitializing = true;

  final PageController _pageController = PageController();
  int _currentSlide = 0;

  final List<Map<String, String>> _slides = [
    {
      'image': 'assets/slide1.png',
      'title': 'A Marketplace Built for Students',
      'description':
          "Buy and sell essentials within Junction's verified network of student community",
    },
    {
      'image': 'assets/slide2.png',
      'title': 'List, Sell or Auction Your Items',
      'description':
          'Post items for direct sale or start a bidding war. Reach real buyers and get the best value.',
    },
    {
      'image': 'assets/slide3.png',
      'title': 'A Marketplace You Can Trust',
      'description':
          'Every user is verified via student email, ensuring a safe and reliable buying & selling experience',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  Future<void> _initializeApp() async {
    try {
      // Show splash immediately
      setState(() {
        _isInitializing = true;
      });

      // Initialize cache with timeout
      try {
        await AppCacheService.initializeCache().timeout(
          const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint('AppCacheService initialization error or timeout: $e');
      }

      MemoryMonitorService().startMonitoring();

      final prefs = await SharedPreferences.getInstance();
      
      // Check if it's the first time
      _isFirstTime = prefs.getBool('isFirstTime') ?? true;
      
      bool? isLoggedIn = prefs.getBool('isLogin');
      bool shouldGoToHome = false;

      if (isLoggedIn == true) {
        try {
          final result = await AuthHealthService.refreshAuthToken().timeout(
            const Duration(seconds: 10),
            onTimeout: () => {'status': 'timeout'},
          );
          if (result['status'] == 'refreshed') {
            if (result['token'] != null) {
              await prefs.setString('authToken', result['token']);
            }
            shouldGoToHome = true;
          } else {
            await prefs.remove('authToken');
            await prefs.setBool('isLogin', false);
            shouldGoToHome = false;
          }
        } catch (e) {
          debugPrint('Token refresh error: $e');
          await prefs.remove('authToken');
          await prefs.setBool('isLogin', false);
          shouldGoToHome = false;
        }
      }

      // Show splash logo for at least 1.5 seconds
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // If it's the first time, show the onboarding slides
      if (_isFirstTime) {
        setState(() {
          _isInitializing = false;
          _showMainContent = true;
        });
        // Don't navigate away - let user go through slides
        return;
      }

      // If not first time, navigate directly to login/home
      if (mounted) {
        Navigator.pushReplacement(
          context,
          SlidePageRoute(page: shouldGoToHome ? HomePage() : LoginPage()),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      // On any error, go to login
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        Navigator.pushReplacement(
          context,
          SlidePageRoute(page: LoginPage()),
        );
      }
    }
  }


  /// Responsive + high-quality image helper
  Widget _logoImage(String asset, {double? size}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final effectiveSize = size ?? screenWidth * 0.1; // 10% of screen width
        return Image.asset(
          asset,
          width: effectiveSize,
          height: effectiveSize,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        );
      },
    );
  }

  Widget _buildMatrixLogo() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logoImage('assets/logo-a.png'),
              const SizedBox(width: 12),
              _logoImage('assets/logo-b.png'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logoImage('assets/logo-c.png'),
              const SizedBox(width: 12),
              _logoImage('assets/logo-d.png'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                const SizedBox(width: 10),
                if (_currentSlide != 0) // Hide back button on first slide
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: Image.asset(
                      'assets/back.png',
                      width: MediaQuery.of(context).size.width * 0.06,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    onPressed: () {
                      if (_currentSlide > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _logoImage('assets/logo-a.png'),
                const SizedBox(width: 10),
                _logoImage('assets/logo-b.png'),
                const SizedBox(width: 10),
                _logoImage('assets/logo-c.png'),
                const SizedBox(width: 10),
                _logoImage('assets/logo-d.png'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderContent() {
    final screenSize = MediaQuery.of(context).size;

    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        itemCount: _slides.length,
        onPageChanged: (index) {
          setState(() => _currentSlide = index);
        },
        itemBuilder: (context, index) {
          final slide = _slides[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  slide['image']!,
                  width: screenSize.width * 0.8,
                  height: screenSize.height * 0.3,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 32),
                Text(
                  slide['title']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20, // Title font size 20px
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  slide['description']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14, // Description font size 14px
                  ),
                ),
                const SizedBox(height: 24),
                _buildSliderDots(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliderDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _slides.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _currentSlide == index ? Colors.black : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AppButton(
        label: _currentSlide == _slides.length - 1 ? 'Continue' : 'Next',
        backgroundColor: Colors.black,
        bottomSpacing: 24, // Controls distance from bottom of screen
        onPressed: () {
          if (_currentSlide == _slides.length - 1) {
            // Mark that user has seen the onboarding
            SharedPreferences.getInstance().then((prefs) {
              prefs.setBool('isFirstTime', false);
            });
            Navigator.pushReplacement(
              context,
              FadePageRoute(page: const AppOverviewScreen()),
            );
          } else {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _showMainContent
              ? Column(
                  key: const ValueKey('main-content'),
                  children: [
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildSliderContent(),
                    const SizedBox(height: 24),
                    _buildBottomButton(),
                    const SizedBox(height: 24),
                  ],
                )
              : _buildMatrixLogo(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    MemoryMonitorService().stopMonitoring();
    super.dispose();
  }
}
