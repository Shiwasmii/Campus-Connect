import 'package:image_picker/image_picker.dart';

/// Abre la cámara o la galería. Se puede sustituir en las pruebas.
class SelectorImagen {
  ImagePicker? _picker;

  ImagePicker get _imagePicker => _picker ??= ImagePicker();

  Future<XFile?> tomarFoto() {
    return _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
  }

  Future<XFile?> elegirImagen() {
    return _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }
}
