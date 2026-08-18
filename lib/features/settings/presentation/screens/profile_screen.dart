import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../documents/data/document_provider.dart';
import '../../../chat/data/conversation_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final user = authState.user;
    final displayName = user?.name ?? (authState.isGuest ? 'Guest User' : 'RAG User');
    final displayEmail = user?.email ?? (authState.isGuest ? 'guest@ragagent.local' : 'user@ragagent.ai');
    final authProviderName = user?.authProvider.toUpperCase() ?? (authState.isGuest ? 'GUEST' : 'EMAIL');

    final docsCount = ref.watch(documentListProvider).maybeWhen(
      data: (docs) => docs.length.toString(),
      orElse: () => '0',
    );
    final chatsCount = ref.watch(conversationListProvider).maybeWhen(
      data: (chats) => chats.length.toString(),
      orElse: () => '0',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: 'Toggle Theme',
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.m),
            // User Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundImage: user?.avatarUrl != null 
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 2),
            Text(
              displayEmail,
              style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: AppSpacing.s),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Text(
                'AUTH: $authProviderName',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Stats Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _buildStat(docsCount, 'Documents', isDark),
                  Container(width: 1, height: 36, color: isDark ? Colors.white12 : Colors.grey.shade300),
                  _buildStat(chatsCount, 'Chats', isDark),
                  Container(width: 1, height: 36, color: isDark ? Colors.white12 : Colors.grey.shade300),
                  _buildStat('Free Cloud', 'Tier', isDark),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Appearance Tile
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: isDark ? Colors.white10 : AppColors.borderLight),
              ),
              child: SwitchListTile(
                secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.primary),
                title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(isDark ? 'Dark Theme enabled' : 'Light Theme enabled', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                value: isDark,
                onChanged: (val) {
                  ref.read(themeProvider.notifier).setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: isDark ? Colors.white10 : AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildActionTile(Icons.key_rounded, 'AI Provider & API Keys', () {
                    Navigator.of(context).pushNamed('/settings');
                  }, isDark),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildActionTile(Icons.security_rounded, 'Privacy & Cloud Storage', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Supabase 100% Free Tier Cloud Storage active.')),
                    );
                  }, isDark),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildActionTile(Icons.info_outline_rounded, 'About RAG Agent', () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'RAG Agent AI',
                      applicationVersion: '2.0.0',
                      children: const [
                        Text('AI Document Retrieval & Multi-Tool Agent built with Flutter and FastAPI.'),
                      ],
                    );
                  }, isDark),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: 'Sign Out',
              isSecondary: true,
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                ref.read(navigationIndexProvider.notifier).state = 0;
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap, bool isDark, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
      title: Text(title, style: TextStyle(color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight), fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMutedLight),
      onTap: onTap,
    );
  }
}
