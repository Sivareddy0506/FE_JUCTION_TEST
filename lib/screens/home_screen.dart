import 'dart:async';
import 'package:flutter/material.dart';
import 'package:junction/screens/profile/user_profile.dart';
import 'package:junction/screens/signup/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_overview.dart';  
import '../widgets/app_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMainContent = false;

  final PageController _pageController = PageController();
  int _currentSlide = 0;

  final List<Map<String, String>> _slides = [
    {
      'image': 'assets/slide1.png',
      'title': 'A Marketplace Built for Students',
      'description':
          'Buy and sell essentials within Junction’s verified network of student community',
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


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      bool? isLoggedIn = await prefs.getBool('isLogin');
      Timer(const Duration(seconds: 3), () async{
        if(isLoggedIn == null || isLoggedIn == false) {
          bool? isFirstTime = await prefs.getBool('isFirstTime');
          if(isFirstTime == false){
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignupPage()),
            );
          }else {
            setState(() {
              _showMainContent = true;
            });
          }
        }else{
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserProfilePage()),
          );
        }
      });
    });
  }

  Widget _logoImage(String asset, {double size = 30}) {
    return Image.asset(asset, width: size, height: size);
  }

  Widget _buildMatrixLogo() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logoImage('assets/logo-a.png', size: 48),
              const SizedBox(width: 12),
              _logoImage('assets/logo-b.png', size: 48),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logoImage('assets/logo-c.png', size: 48),
              const SizedBox(width: 12),
              _logoImage('assets/logo-d.png', size: 48),
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
                  icon: Image.asset('assets/back.png', width: 24),
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
              Image.asset(slide['image']!, height: 240),
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

// Import your AppOverviewScreen here
Widget _buildBottomButton() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: AppButton(
      label: _currentSlide == _slides.length - 1 ? 'Continue' : 'Next',
      backgroundColor: Colors.black,
      bottomSpacing: 24, // Controls distance from bottom of screen
      onPressed: () {
        if (_currentSlide == _slides.length - 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AppOverviewScreen()),
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
        child: _showMainContent
            ? Column(
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
    );
  }
}
