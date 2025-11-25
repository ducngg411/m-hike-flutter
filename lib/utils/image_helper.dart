import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  // Pick image from camera or gallery
  static Future<String?> pickImage({
    required BuildContext context,
    required ImageSource source,
    bool cropImage = true,
  }) async {
    try {
      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Crop image if requested
      if (cropImage) {
        final croppedFile = await _cropImage(pickedFile.path, context);
        if (croppedFile == null) return null;

        // Save to app directory
        return await _saveImageToAppDirectory(croppedFile.path);
      } else {
        // Save to app directory
        return await _saveImageToAppDirectory(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Crop image
  static Future<CroppedFile?> _cropImage(
      String imagePath,
      BuildContext context,
      ) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.original,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.original,
            ],
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  // Save image to app directory
  static Future<String> _saveImageToAppDirectory(String imagePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imagePath)}';
    final savedImagePath = path.join(appDir.path, 'images', fileName);

    // Create images directory if not exists
    final imagesDir = Directory(path.join(appDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    // Copy image to app directory
    final File imageFile = File(imagePath);
    await imageFile.copy(savedImagePath);

    return savedImagePath;
  }

  // Delete image from app directory
  static Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  // Show image source selection dialog
  static Future<String?> showImageSourceDialog(BuildContext context) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.blue),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return null;

    // Pick image directly without cropping to avoid context issues
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Save directly without cropping to avoid context crashes
      return await _saveImageToAppDirectory(pickedFile.path);
    } catch (e) {
      debugPrint('Error in showImageSourceDialog: $e');
      return null;
    }
  }

  // Show image source selection dialog with cropping option
  static Future<String?> showImageSourceDialogWithCrop(BuildContext context) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.blue),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return null;

    if (!context.mounted) return null;

    // Use the pickImage method which includes cropping
    return await pickImage(
      context: context,
      source: source,
      cropImage: true,
    );
  }
}