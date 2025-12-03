import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/app_button.dart';
import '../../app.dart';
import '../profile/user_profile.dart';
import 'referral_code_page.dart' as edu;
import 'referral_code_page_non_edu.dart' as non_edu;

class EULAAcceptancePage extends StatefulWidget {
  final String? email;
  final String? otp;
  final bool isSignupFlow;
  final bool isEduFlow;

  const EULAAcceptancePage({
    super.key,
    this.email,
    this.otp,
    this.isSignupFlow = true,
    this.isEduFlow = true,
  });

  @override
  State<EULAAcceptancePage> createState() => _EULAAcceptancePageState();
}

class _EULAAcceptancePageState extends State<EULAAcceptancePage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _isCheckboxChecked = false;
  bool _isAccepting = false;
  String _eulaContent = '';
  String _eulaVersion = '1.0.3'; // Match app version

  @override
  void initState() {
    super.initState();
    _loadEULAContent();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEULAContent() async {
    try {
      final content = await rootBundle.loadString('assets/eula.txt');
      setState(() {
        _eulaContent = content;
      });
    } catch (e) {
      debugPrint('Error loading EULA content: $e');
      setState(() {
        _eulaContent = 'Failed to load Terms & Conditions. Please try again.';
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      // Consider "scrolled to bottom" if within 50 pixels of the bottom
      if (maxScroll - currentScroll <= 50 && !_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  bool get _canAccept => _hasScrolledToBottom && _isCheckboxChecked;

  Future<void> _acceptEULA() async {
    if (!_canAccept || _isAccepting) return;

    setState(() => _isAccepting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication error. Please log in again.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('https://api.junctionverse.com/user/accept-eula'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'eulaVersion': _eulaVersion}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Save EULA acceptance locally
        await prefs.setBool('eulaAccepted', true);
        await prefs.setString('eulaVersion', _eulaVersion);

        // Navigate based on flow type
        if (widget.isSignupFlow && widget.email != null && widget.otp != null) {
          // Continue signup flow to referral code page
          if (widget.isEduFlow) {
            Navigator.pushReplacement(
              context,
              SlidePageRoute(
                page: edu.ReferralCodePage(email: widget.email!, otp: widget.otp!),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              SlidePageRoute(
                page: non_edu.ReferralCodePage(email: widget.email!, otp: widget.otp!),
              ),
            );
          }
        } else {
          // For login flow or completed signup, go to main app
          Navigator.pushAndRemoveUntil(
            context,
            SlidePageRoute(page: const UserProfilePage()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to accept terms. Please try again.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please check your connection and try again.')),
      );
      debugPrint('Error accepting EULA: $e');
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back button - user must accept to proceed
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // No back button
          title: const Text(
            'Terms & Conditions',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: _eulaContent.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // EULA Content Area
                  Expanded(
                    child: Container(
                      color: Colors.grey[50],
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Scroll indicator
                            if (!_hasScrolledToBottom)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_downward, color: Colors.orange[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Please scroll to the bottom to read all terms',
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
                            
                            // EULA Text Content
                            Text(
                              _eulaContent,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Bottom indicator when reached
                            if (_hasScrolledToBottom)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'You\'ve reached the end. You can now accept the terms.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green[900],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom Action Area
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Checkbox
                        InkWell(
                          onTap: _hasScrolledToBottom
                              ? () {
                                  setState(() {
                                    _isCheckboxChecked = !_isCheckboxChecked;
                                  });
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _hasScrolledToBottom ? Colors.white : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _hasScrolledToBottom ? Colors.grey[300]! : Colors.grey[200]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _isCheckboxChecked,
                                    onChanged: _hasScrolledToBottom
                                        ? (value) {
                                            setState(() {
                                              _isCheckboxChecked = value ?? false;
                                            });
                                          }
                                        : null,
                                    activeColor: const Color(0xFF262626),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'I have read and agree to the Terms & Conditions',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _hasScrolledToBottom ? Colors.black87 : Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Accept Button
                        AppButton(
                          label: _isAccepting ? 'Accepting...' : 'Accept & Continue',
                          onPressed: _canAccept && !_isAccepting ? _acceptEULA : null,
                          backgroundColor: _canAccept ? const Color(0xFF262626) : Colors.grey[300],
                          textColor: _canAccept ? Colors.white : Colors.grey[500],
                        ),
                        
                        // Help text
                        if (!_hasScrolledToBottom)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Scroll to the bottom to enable acceptance',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

