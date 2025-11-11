import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Centralized error handling utility for user-friendly error messages
class ErrorHandler {
  /// Get a user-friendly error message from an exception or HTTP response
  static String getErrorMessage(dynamic error, {http.Response? response}) {
    // Handle HTTP response errors first
    if (response != null) {
      return _getHttpErrorMessage(response);
    }

    // Handle different exception types
    if (error is http.ClientException) {
      return 'Connection failed. Please check your internet connection.';
    }

    if (error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup')) {
      return 'No internet connection. Please check your network settings.';
    }

    if (error.toString().contains('TimeoutException') ||
        error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (error.toString().contains('FormatException') ||
        error.toString().contains('json')) {
      return 'Invalid response from server. Please try again.';
    }

    // Check for common API error patterns in error messages
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('prisma') || 
        errorString.contains('database') ||
        errorString.contains('query') ||
        errorString.contains('column')) {
      return 'Server error occurred. Our team has been notified.';
    }

    if (errorString.contains('unauthorized') || 
        errorString.contains('401')) {
      return 'Your session has expired. Please log in again.';
    }

    if (errorString.contains('forbidden') || 
        errorString.contains('403')) {
      return 'You do not have permission to perform this action.';
    }

    if (errorString.contains('not found') || 
        errorString.contains('404')) {
      return 'The requested resource was not found.';
    }

    if (errorString.contains('entity too large') ||
        errorString.contains('413') ||
        errorString.contains('file size')) {
      return 'File size is too large. Please upload a smaller file.';
    }

    if (errorString.contains('internal server error') ||
        errorString.contains('500')) {
      return 'Server error occurred. Please try again later.';
    }

    if (errorString.contains('bad gateway') ||
        errorString.contains('502')) {
      return 'Service temporarily unavailable. Please try again.';
    }

    if (errorString.contains('service unavailable') ||
        errorString.contains('503')) {
      return 'Service is temporarily unavailable. Please try again later.';
    }

    // Default fallback message
    return 'Something went wrong. Please try again.';
  }

  /// Extract error message from HTTP response
  static String _getHttpErrorMessage(http.Response response) {
    try {
      final data = json.decode(response.body);
      
      // Try to extract user-friendly error message from response
      if (data is Map<String, dynamic>) {
        // Common error field names
        String? errorMessage = data['error'] ?? 
                              data['message'] ?? 
                              data['errorMessage'] ??
                              data['msg'];
        
        if (errorMessage != null && errorMessage.isNotEmpty) {
          // Filter out technical error messages
          if (_isTechnicalError(errorMessage)) {
            return _getFriendlyMessageForStatus(response.statusCode);
          }
          return errorMessage;
        }
      }
    } catch (_) {
      // If JSON parsing fails, use status code
    }

    // Fallback to status code based message
    return _getFriendlyMessageForStatus(response.statusCode);
  }

  /// Check if error message contains technical details that shouldn't be shown to users
  static bool _isTechnicalError(String message) {
    final lowerMessage = message.toLowerCase();
    
    return lowerMessage.contains('prisma') ||
           lowerMessage.contains('queryraw') ||
           lowerMessage.contains('column') ||
           lowerMessage.contains('database') ||
           lowerMessage.contains('sql') ||
           lowerMessage.contains('sequelize') ||
           lowerMessage.contains('mongo') ||
           lowerMessage.contains('error code') ||
           lowerMessage.contains('stack trace') ||
           lowerMessage.contains('at ') ||
           lowerMessage.contains('.js:') ||
           lowerMessage.contains('.dart:') ||
           lowerMessage.contains('invalid ') && 
             (lowerMessage.contains('invocation') || 
              lowerMessage.contains('request'));
  }

  /// Get user-friendly message based on HTTP status code
  static String _getFriendlyMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 408:
        return 'Request timed out. Please try again.';
      case 413:
        return 'File size is too large. Please upload a smaller file.';
      case 422:
        return 'Invalid data provided. Please check your input.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error occurred. Please try again later.';
      case 502:
        return 'Service temporarily unavailable. Please try again.';
      case 503:
        return 'Service is temporarily unavailable. Please try again later.';
      case 504:
        return 'Request timed out. Please try again.';
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return 'Invalid request. Please check your input and try again.';
        } else if (statusCode >= 500) {
          return 'Server error occurred. Please try again later.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  /// Show error snackbar with user-friendly message
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    http.Response? response,
    String? customMessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    final message = customMessage ?? getErrorMessage(error, response: response);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
      ),
    );
  }
}

