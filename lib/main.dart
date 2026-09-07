import 'package:flutter/material.dart';
import 'widgets/app_logo.dart';
import 'services/theme_service.dart';
import 'screens/splash_screen.dart';
import 'screens/jpg_viewer_screen.dart';
import 'screens/events_dashboard_screen.dart';
import 'screens/upload_photos_screen.dart';
import 'screens/upload_queue_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Photo House',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _onAddToHomePressed() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const JpgViewerScreen()));
  }

  void _onOpenUploadPhotos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UploadPhotosScreen(eventTitle: 'Maulik'),
      ),
    );
  }

  void _onOpenUploadQueue() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UploadQueueScreen()));
  }

  void _onOpenEventsDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const EventsDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        elevation: 0,
        title: Row(
          children: [
            AppLogo(size: 32),
            const SizedBox(width: 10),
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _onOpenUploadPhotos,
                icon: const Icon(Icons.cloud_upload),
                label: const Text(
                  'Upload Photos (Stitch UI)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF09090B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _onOpenUploadQueue,
                icon: const Icon(Icons.format_list_bulleted),
                label: const Text(
                  'Upload Queue (Stitch UI)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  foregroundColor: const Color(0xFFF59E0B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _onOpenEventsDashboard,
                icon: const Icon(Icons.dashboard),
                label: const Text(
                  'Events Dashboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _onAddToHomePressed,
                icon: const Icon(Icons.add_to_home_screen),
                label: const Text(
                  'JPG Viewer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
