import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

class AIImageGeneratorScreen extends StatefulWidget {
  const AIImageGeneratorScreen({super.key});

  @override
  AIImageGeneratorScreenState createState() => AIImageGeneratorScreenState();
}

class AIImageGeneratorScreenState extends State<AIImageGeneratorScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _generatedImageUrl;
  bool _isLoading = false;

  Future<void> generateImage() async {
    final apiKey = dotenv.env['API_KEY'];
    final prompt = _textController.text.trim();

    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ API Key is missing! Check .env file')),
      );
      return;
    }

    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter a prompt!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedImageUrl = null; // Reset the image URL
    });

    final url = Uri.parse(
      'https://api.stability.ai/v1/generation/stable-diffusion-v1-6/text-to-image',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text_prompts': [
            {'text': prompt},
          ],
          'cfg_scale': 7, // Controls how closely the image follows the prompt
          'height': 512, // Image height
          'width': 512, // Image width
          'samples': 1, // Number of images to generate
          'steps': 30, // Number of diffusion steps
        }),
      );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['artifacts'] == null || data['artifacts'].isEmpty) {
          throw Exception('No image found in response');
        }
        final imageBytes = base64Decode(data['artifacts'][0]['base64']);

        // Save the image to a temporary file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/generated_image.png');
        await file.writeAsBytes(imageBytes);

        setState(() {
          _generatedImageUrl = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to generate image: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('❌ Error: $e');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ API Request Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Image Generator'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[900],
                labelText: 'Enter text to generate image',
                labelStyle: const TextStyle(color: Colors.grey),
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : generateImage,
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
                        'Generate Image',
                        style: TextStyle(fontSize: 16),
                      ),
            ),
            const SizedBox(height: 20),
            if (_generatedImageUrl != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_generatedImageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          'Error loading generated image',
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
