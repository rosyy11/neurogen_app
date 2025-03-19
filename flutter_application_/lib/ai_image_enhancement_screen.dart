import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert'; // Required for JSON response
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For loading .env

class AIImageEnhancementScreen extends StatefulWidget {
  const AIImageEnhancementScreen({super.key});

  @override
  AIImageEnhancementScreenState createState() =>
      AIImageEnhancementScreenState();
}

class AIImageEnhancementScreenState extends State<AIImageEnhancementScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _enhancedImageUrl;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _enhancedImageUrl = null;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('⚠️ No image selected!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error picking image: $e')));
    }
  }

  Future<void> _enhanceImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please select an image first!')),
      );
      return;
    }

    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ API key not found. Please check your .env file.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _enhancedImageUrl = null;
    });

    try {
      // Perform heavy work in the background
      final enhancedImageUrl = await _enhanceImageInBackground(apiKey);
      if (enhancedImageUrl != null) {
        setState(() {
          _enhancedImageUrl = enhancedImageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  Future<String?> _enhanceImageInBackground(String apiKey) async {
    final imageBytes = await _image!.readAsBytes();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://api.stability.ai/v1/generation/stable-diffusion-v1-5/image-to-image',
      ), // Correct endpoint
    );
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.headers['Accept'] = 'application/json'; // Add Accept header
    request.fields['image_strength'] =
        '0.35'; // Example parameter for image strength
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'uploaded_image.png',
      ),
    );

    http.StreamedResponse response = await request.send().timeout(
      const Duration(seconds: 60),
    );

    final responseBody = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(responseBody.body);
      if (responseData['artifacts'] == null ||
          responseData['artifacts'].isEmpty) {
        throw Exception('No enhanced image found in response');
      }
      final enhancedImageUrl = responseData['artifacts'][0]['url'] as String;

      final imageResponse = await http.get(Uri.parse(enhancedImageUrl));
      if (imageResponse.statusCode == 200) {
        final enhancedBytes = imageResponse.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/enhanced_image_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(enhancedBytes);
        return file.path;
      } else {
        throw Exception(
          'Failed to download enhanced image: ${imageResponse.statusCode}',
        );
      }
    } else {
      throw Exception(
        'Failed to enhance image: Status ${response.statusCode}, Body: ${responseBody.body}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Image Enhancement'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Select Image', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _enhanceImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Enhance Image',
                        style: TextStyle(fontSize: 16),
                      ),
            ),
            const SizedBox(height: 20),
            if (_enhancedImageUrl != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_enhancedImageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'Error loading enhanced image',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
