import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ai_image_generator_screen.dart';
import 'ai_image_enhancement_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const NeuroGenApp());
}

class NeuroGenApp extends StatelessWidget {
  const NeuroGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeuroGen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Map<String, dynamic>> tools = [
    {'name': 'AI Image Generator', 'icon': Icons.image, 'color': Colors.blue},
    {
      'name': 'AI Image Enhancement',
      'icon': Icons.enhance_photo_translate,
      'color': Colors.green,
    },
    {'name': 'ChatGPT', 'icon': Icons.chat, 'color': Colors.orange},
    {'name': 'PDF Editor', 'icon': Icons.picture_as_pdf, 'color': Colors.red},
    {'name': 'PPT Maker', 'icon': Icons.slideshow, 'color': Colors.purple},
    {'name': 'Pro Image Editor', 'icon': Icons.edit, 'color': Colors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.blue.shade900],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'NeuroGen',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI-powered creative toolkit',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: tools.length,
                  itemBuilder: (context, index) {
                    return ToolCard(
                      name: tools[index]['name'],
                      icon: tools[index]['icon'],
                      color: tools[index]['color'],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ToolCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;

  const ToolCard({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: widget.color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_isHovered ? 0.5 : 0.2),
              blurRadius: _isHovered ? 20 : 10,
              spreadRadius: _isHovered ? 2 : 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            if (widget.name == "AI Image Generator") {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const AIImageGeneratorScreen(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            } else if (widget.name == "AI Image Enhancement") {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const AIImageEnhancementScreen(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 50, color: widget.color),
              const SizedBox(height: 10),
              Text(
                widget.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
