import 'package:http/http.dart' as http;

/// Debug script to test production API endpoints
class ApiEndpointDebugger {
  static const String baseUrl = 'https://api.junctionverse.com';
  
  // Test various endpoint patterns
  static const List<String> testEndpoints = [
    '/user/search/current',
    '/api/user/search/current',
    '/user/search',
    '/api/search/current',
    '/search/current',
    '/user/products',
    '/api/user/products',
    '/products',
    '/user/profile', // This should work as a control test
    '/api/notifications/user/received', // This should work as a control test
  ];

  /// Test if an endpoint exists
  static Future<void> testEndpoint(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      print('🔍 Testing: $endpoint');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer test_token',
        },
      );

      print('   Status: ${response.statusCode}');
      
      if (response.statusCode == 401) {
        print('   ✅ Endpoint EXISTS (401 Unauthorized expected)');
      } else if (response.statusCode == 404) {
        print('   ❌ Endpoint NOT FOUND');
      } else if (response.statusCode == 200) {
        print('   ✅ Endpoint ACCESSIBLE');
      } else {
        print('   ⚠️  Status: ${response.statusCode}');
      }
      
      // Show response body for debugging
      if (response.statusCode != 404) {
        print('   Body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      }
      
    } catch (e) {
      print('   ❌ Error: $e');
    }
    print('');
  }

  /// Test all endpoints
  static Future<void> testAllEndpoints() async {
    print('🚀 Testing Production API Endpoints...\n');
    
    for (final endpoint in testEndpoints) {
      await testEndpoint(endpoint);
    }
    
    print('✅ Endpoint testing complete!');
  }

  /// Test with actual search parameters
  static Future<void> testSearchWithParams() async {
    print('🔍 Testing Search with Parameters...\n');
    
    final searchEndpoints = [
      '/user/search/current',
      '/api/user/search/current',
      '/user/search',
    ];

    final params = {
      'userLat': '37.4219983',
      'userLng': '-122.084',
      'query': 'furniture',
      'radius': '50.0',
      'sortBy': 'Distance',
      'limit': '10',
    };

    for (final endpoint in searchEndpoints) {
      try {
        final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params);
        print('🔍 Testing: $endpoint with params');
        print('   URL: $uri');
        
        final response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer test_token',
          },
        );

        print('   Status: ${response.statusCode}');
        
        if (response.statusCode == 401) {
          print('   ✅ Endpoint EXISTS and accepts parameters');
        } else if (response.statusCode == 404) {
          print('   ❌ Endpoint NOT FOUND');
        } else if (response.statusCode == 400) {
          print('   ⚠️  Bad request - check parameter format');
        } else {
          print('   ✅ Endpoint working');
        }
        
      } catch (e) {
        print('   ❌ Error: $e');
      }
      print('');
    }
  }

  /// Check if the API server is reachable
  static Future<void> testApiServer() async {
    print('🌐 Testing API Server Connectivity...\n');
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Server Status: ${response.statusCode}');
      print('Server Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      
    } catch (e) {
      print('❌ Cannot reach API server: $e');
    }
  }
}

void main() async {
  await ApiEndpointDebugger.testApiServer();
  await ApiEndpointDebugger.testAllEndpoints();
  await ApiEndpointDebugger.testSearchWithParams();
}
