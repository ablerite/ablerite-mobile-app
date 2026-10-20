import 'package:image_picker/image_picker.dart';

/// Selects photos at a size suitable for app uploads instead of retaining the
/// multi-megapixel originals produced by modern phone cameras.
class PhotoCompressionService {
  static const double maximumDimension = 2048;
  static const int imageQuality = 82;

  final ImagePicker _picker;

  PhotoCompressionService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(
      source: source,
      maxWidth: maximumDimension,
      maxHeight: maximumDimension,
      imageQuality: imageQuality,
    );
  }

  Future<List<XFile>> pickMultipleImages() {
    return _picker.pickMultiImage(
      maxWidth: maximumDimension,
      maxHeight: maximumDimension,
      imageQuality: imageQuality,
    );
  }
}
