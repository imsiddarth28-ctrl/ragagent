import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/providers/navigation_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.l),
            Stack(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=john'),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            const Text(
              'John Doe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const Text(
              'john.doe@example.com',
              style: TextStyle(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: AppSpacing.xxl),
            
            Row(
              children: [
                _buildStat('12', 'Documents'),
                _buildStat('24', 'Chats'),
                _buildStat('158', 'Questions'),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            _buildActionItem(Icons.edit_outlined, 'Edit Profile', () {}),
            _buildActionItem(Icons.lock_outline_rounded, 'Change Password', () {}),
            _buildActionItem(Icons.notifications_none_rounded, 'Notifications', () {}),
            _buildActionItem(Icons.delete_outline_rounded, 'Delete Account', () {}, color: AppColors.error),
            
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              text: 'Sign Out',
              isSecondary: true,
              onPressed: () {
                ref.read(navigationIndexProvider.notifier).state = 0;
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
