import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImagePreviewWidget extends StatelessWidget {
  final String? imagePath;
  final double height;
  final double? width;
  final BoxFit fit;
  final bool showFullScreenOnTap;

  const ImagePreviewWidget({
    super.key,
    this.imagePath,
    this.height = 200,
    this.width,
    this.fit = BoxFit.cover,
    this.showFullScreenOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder();
    }

    final file = File(imagePath!);

    return GestureDetector(
      onTap: showFullScreenOnTap
          ? () => _showFullScreenImage(context)
          : null,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: file.existsSync()
              ? Image.file(
            file,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            'No image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imagePath: imagePath!),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoView(
        imageProvider: FileImage(File(imagePath)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
      ),
    );
  }
}