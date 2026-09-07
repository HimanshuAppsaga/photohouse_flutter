import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import '../widgets/app_logo.dart';

class JpgPhoto {
  final String id;
  final String name;
  final String? assetPath;
  final File? file;

  JpgPhoto({required this.id, required this.name, this.assetPath, this.file});
}

class JpgViewerScreen extends StatefulWidget {
  const JpgViewerScreen({super.key});

  @override
  State<JpgViewerScreen> createState() => _JpgViewerScreenState();
}

class _JpgViewerScreenState extends State<JpgViewerScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<JpgPhoto> _photos = [
    JpgPhoto(
      id: '1',
      name: 'Mountain_House.jpg',
      assetPath: 'assets/images/sample1.jpg',
    ),
    JpgPhoto(
      id: '2',
      name: 'Autumn_Studio.jpg',
      assetPath: 'assets/images/sample2.jpg',
    ),
  ];

  int _currentIndex = 0;

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        _addNewPhoto(
          JpgPhoto(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: pickedFile.name.isNotEmpty
                ? pickedFile.name
                : 'Photo_${_photos.length + 1}.jpg',
            file: File(pickedFile.path),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error selecting photo: $e', isError: true);
    }
  }

  Future<void> _capturePhotoWithCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        _addNewPhoto(
          JpgPhoto(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: pickedFile.name.isNotEmpty
                ? pickedFile.name
                : 'Captured_${_photos.length + 1}.jpg',
            file: File(pickedFile.path),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error taking photo: $e', isError: true);
    }
  }

  void _addSampleJpg(String assetPath, String name) {
    _addNewPhoto(
      JpgPhoto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        assetPath: assetPath,
      ),
    );
  }

  void _addNewPhoto(JpgPhoto photo) {
    setState(() {
      _photos.insert(0, photo);
      _currentIndex = 0;
    });
    _showSnackBar('${photo.name} added successfully!');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    AppToast.show(
      context,
      message,
      type: isError ? ToastType.error : ToastType.success,
    );
  }

  void _showAddPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Add .JPG Photos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text('Choose JPG from Phone Gallery'),
                  subtitle: const Text('Select a .jpg or .jpeg image'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text('Take a Photo with Camera'),
                  subtitle: const Text('Capture a new photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _capturePhotoWithCamera();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.landscape, color: Colors.amber),
                  ),
                  title: const Text('Add Sample JPG Photo 1'),
                  onTap: () {
                    Navigator.pop(context);
                    _addSampleJpg(
                      'assets/images/sample1.jpg',
                      'Mountain_House.jpg',
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.nature, color: Colors.amber),
                  ),
                  title: const Text('Add Sample JPG Photo 2'),
                  onTap: () {
                    Navigator.pop(context);
                    _addSampleJpg(
                      'assets/images/sample2.jpg',
                      'Autumn_Studio.jpg',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    final hasPhotos = _photos.isNotEmpty;
    final currentPhoto = hasPhotos ? _photos[_currentIndex] : null;

    return Scaffold(
      backgroundColor: palette.bgDarker,
      appBar: AppBar(
        backgroundColor: palette.bgDarker,
        iconTheme: IconThemeData(color: palette.textPrimary),
        title: Row(
          children: [
            const AppLogo(size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                currentPhoto != null ? currentPhoto.name : 'JPG Viewer',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_a_photo, color: palette.accentPrimary),
            tooltip: 'Add Photo',
            onPressed: _showAddPhotoOptions,
          ),
          if (hasPhotos)
            IconButton(
              icon: Icon(Icons.delete_outline, color: palette.danger),
              tooltip: 'Delete Photo',
              onPressed: () {
                setState(() {
                  _photos.removeAt(_currentIndex);
                  if (_currentIndex >= _photos.length && _photos.isNotEmpty) {
                    _currentIndex = _photos.length - 1;
                  }
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: !hasPhotos
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 72,
                            color: palette.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No .JPG photos added yet',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showAddPhotoOptions,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Add Your First JPG Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.accentPrimary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : InteractiveViewer(
                      key: ValueKey(currentPhoto!.id),
                      child: Center(
                        child: currentPhoto.file != null
                            ? Image.file(
                                currentPhoto.file!,
                                fit: BoxFit.contain,
                              )
                            : Image.asset(
                                currentPhoto.assetPath!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: palette.accentPrimary,
                                        size: 64,
                                      ),
                                    ),
                              ),
                      ),
                    ),
            ),
            if (hasPhotos)
              Container(
                height: 100,
                color: palette.cardBg,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: InkWell(
                        onTap: _showAddPhotoOptions,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: palette.accentPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.black, size: 28),
                              SizedBox(height: 2),
                              Text(
                                'Add JPG',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    VerticalDivider(color: palette.border, width: 1),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _photos.length,
                        itemBuilder: (context, index) {
                          final photo = _photos[index];
                          final isSelected = index == _currentIndex;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? palette.accentPrimary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    photo.file != null
                                        ? Image.file(
                                            photo.file!,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            photo.assetPath!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                      Icons.image,
                                                      color: palette.textMuted,
                                                    ),
                                          ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.7,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'JPG',
                                          style: TextStyle(
                                            color: palette.accentPrimary,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
