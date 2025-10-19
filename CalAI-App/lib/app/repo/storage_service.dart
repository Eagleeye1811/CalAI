import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:CalAI/app/config/environment.dart';

class StorageService {
  /// Upload image to backend server (free, no Firebase Storage needed)
  Future<String?> uploadImage(File imageFile) async {
    try {
      print('📤 Uploading image to backend: ${Environment.backendUrl}');

      final uri = Uri.parse('${Environment.backendUrl}/upload/image');

      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      print('📤 Sending upload request...');
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final json = jsonDecode(responseData);
        final imageUrl = json['imageUrl'] as String?;

        print('✅ Image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }
}
