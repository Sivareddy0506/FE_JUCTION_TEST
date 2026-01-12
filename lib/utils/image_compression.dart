import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCompression {
  // Target max file size: 2MB (to account for ~40-50% multipart encoding overhead and multiple files)
  // This ensures the final upload stays well under 5MB server limit per file
  // When multiple files are uploaded together, each needs to be smaller
  static const int maxFileSize = 2097152; // 2MB in bytes

  /// Compress an image file to ensure it's under the max file size
  /// Returns the compressed file, or the original if already small enough
  static Future<File?> compressImageToFit(
    String imagePath, {
    int quality = 85,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }

      final originalSize = await file.length();
      
      // If already under limit, return original
      if (originalSize <= maxFileSize) {
        _log('Image already under size limit: ${(originalSize / 1024 / 1024).toStringAsFixed(2)}MB');
        return file;
      }

      _log('Compressing image: ${(originalSize / 1024 / 1024).toStringAsFixed(2)}MB');

      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final tempPath = dir.path;
      
      // Generate a unique filename
      final fileName = p.basename(imagePath);
      final nameWithoutExt = p.basenameWithoutExtension(fileName);
      final ext = p.extension(fileName);
      final targetPath = '$tempPath/${nameWithoutExt}_compressed_${DateTime.now().millisecondsSinceEpoch}$ext';

      // Initial compression with high quality
      // autoCorrectionAngle: true - Automatically corrects rotation based on EXIF orientation
      // keepExif: false - Removes EXIF data after applying corrections to prevent double rotation
      XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: _getCompressFormat(ext),
        autoCorrectionAngle: true,
        keepExif: false,
      );

      if (compressedFile == null) {
        _log('Compression failed, returning original');
        return file;
      }

      var currentFile = File(compressedFile.path);
      var currentSize = await currentFile.length();
      
      _log('After initial compression: ${(currentSize / 1024 / 1024).toStringAsFixed(2)}MB');

      // If still too large, reduce quality progressively
      int currentQuality = quality;
      while (currentSize > maxFileSize && currentQuality > 20) {
        currentQuality -= 10;
        
        _log('Reducing quality to $currentQuality');
        
        // Delete previous compressed file
        await currentFile.delete();
        
        // Recompress with lower quality
        // autoCorrectionAngle: true - Automatically corrects rotation based on EXIF orientation
        // keepExif: false - Removes EXIF data after applying corrections to prevent double rotation
        final newTargetPath = '$tempPath/${nameWithoutExt}_compressed_${DateTime.now().millisecondsSinceEpoch}$ext';
        compressedFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          newTargetPath,
          quality: currentQuality,
          format: _getCompressFormat(ext),
          autoCorrectionAngle: true,
          keepExif: false,
        );

        if (compressedFile == null) {
          _log('Recompression failed');
          return file;
        }

        currentFile = File(compressedFile.path);
        currentSize = await currentFile.length();
        
        _log('After quality $currentQuality: ${(currentSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }


      // Final check - if still too large, return original (user will get size error)
      if (currentSize > maxFileSize) {
        _log('Warning: Image still exceeds size limit even after compression');
        await currentFile.delete();
        return file;
      }

      _log('Compression successful: ${(currentSize / 1024 / 1024).toStringAsFixed(2)}MB');
      return currentFile;

    } catch (e) {
      _log('Error compressing image: $e');
      return File(imagePath);
    }
  }

  /// Get CompressFormat based on file extension
  static CompressFormat _getCompressFormat(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return CompressFormat.jpeg;
      case '.png':
        return CompressFormat.png;
      case '.heic':
        return CompressFormat.heic;
      case '.webp':
        return CompressFormat.webp;
      default:
        return CompressFormat.jpeg; // Default to JPEG
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Log wrapper
  static void _log(String message) {
    debugPrint('[ImageCompression] $message');
  }
}

