import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationWebView extends StatefulWidget {
  final String url;
  final String? title;

  const RegistrationWebView({
    super.key,
    required this.url,
    this.title,
  });

  @override
  State<RegistrationWebView> createState() => _RegistrationWebViewState();
}

class _RegistrationWebViewState extends State<RegistrationWebView> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      // Get auth token to append to URL if needed
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken');

      // Build URL with token if not already present
      String finalUrl = widget.url;
      if (authToken != null && !finalUrl.contains('token=')) {
        final separator = finalUrl.contains('?') ? '&' : '?';
        finalUrl = '${finalUrl}${separator}token=$authToken';
      }
      
      // Initialize WebView
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _error = null;
                  _loadingProgress = 0.0;
                });
              }
            },
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _loadingProgress = progress / 100;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _loadingProgress = 1.0;
                  // Clear any previous errors on successful load
                  _error = null;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('❌ WebView Error: ${error.description}');
              debugPrint('   Error Code: ${error.errorCode}');
              debugPrint('   Error Type: ${error.errorType}');
              debugPrint('   Failed URL: ${error.url}');
              
              if (mounted) {
                setState(() {
                  // Only show error if it's a critical failure, not just resource loading issues
                  if (error.errorCode == -2 || error.errorCode == -6) {
                    // -2: Host lookup failed, -6: Connection failed
                    _error = 'Failed to load page: ${error.description}';
                    _isLoading = false;
                  } else {
                    // For other errors (like missing resources), just log but don't block
                    debugPrint('⚠️ Non-critical resource error, continuing...');
                  }
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              // Allow all navigation
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(finalUrl));
      
      // Set controller after initialization
      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load registration page: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Registration'),
        backgroundColor: const Color(0xFFFF6705),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _error != null
          ? _buildErrorView()
          : _controller == null
              ? _buildLoadingIndicator()
              : Stack(
                  children: [
                    WebViewWidget(controller: _controller!),
                    if (_isLoading) _buildLoadingIndicator(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _controller = null;
                });
                _initializeWebView();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6705),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: _loadingProgress > 0 ? _loadingProgress : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6705)),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading registration page...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
