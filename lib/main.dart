import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/documents/presentation/screens/documents_screen.dart';
import 'features/documents/presentation/screens/upload_document_screen.dart';
import 'features/chat/presentation/screens/chat_screen.dart';
import 'features/chat/presentation/screens/chat_history_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/settings/presentation/screens/profile_screen.dart';
import 'features/documents/presentation/screens/document_details_screen.dart';
import 'models/document_model.dart';
import 'core/providers/navigation_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: RAGAgentApp(),
    ),
  );
}

class RAGAgentApp extends ConsumerWidget {
  const RAGAgentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'RAG Agent AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigationShell(),
        '/upload': (context) => const UploadDocumentScreen(),
        '/chat': (context) => const ChatScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/document-details': (context) {
          final doc = ModalRoute.of(context)!.settings.arguments as Document;
          return DocumentDetailsScreen(document: doc);
        },
      },
    );
  }
}

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  static final List<Widget> _screens = [
    const HomeScreen(),
    const DocumentsScreen(),
    const ChatHistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _screens[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            ref.read(navigationIndexProvider.notifier).state = index;
          },
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          indicatorColor: const Color(0xFF4F46E5).withValues(alpha: 0.12),
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF4F46E5)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description_rounded, color: Color(0xFF4F46E5)),
              label: 'Docs',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF4F46E5)),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF4F46E5)),
              label: 'Settings',
            ),
          ],
        ),
      ),
      floatingActionButton: selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pushNamed('/upload'),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload'),
            )
          : null,
    );
  }
}
