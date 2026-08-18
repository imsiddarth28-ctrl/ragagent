import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../models/ai_config_model.dart';
import '../../data/ai_settings_provider.dart';
import '../../../../core/providers/navigation_provider.dart';

final apiKeyVisibilityProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final providersAsync = ref.watch(providersProvider);
    final testState = ref.watch(connectionTestProvider);
    final isApiKeyVisible = ref.watch(apiKeyVisibilityProvider);

    // Notification listener for connection test results
    ref.listen<ConnectionTestState>(connectionTestProvider, (previous, next) {
      if (next.result != null && previous?.result != next.result) {
        final snackBar = SnackBar(
          content: Text(next.result!.message),
          backgroundColor: next.result!.success ? AppColors.secondary : AppColors.error,
          behavior: SnackBarBehavior.floating,
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          _buildSection('Account'),
          _buildSettingItem(Icons.person_outline_rounded, 'Profile', () => Navigator.of(context).pushNamed('/profile')),
          _buildSettingItem(Icons.email_outlined, 'Email', () {}),
          _buildSettingItem(Icons.lock_outline_rounded, 'Change Password', () {}),
          
          _buildSection('AI Configuration'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: providersAsync.when(
              data: (providers) {
                if (providers.isEmpty) {
                  return const Text('No AI providers found.');
                }
                
                // Auto-select first provider if none selected
                if (aiSettings.selectedProvider == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(aiSettingsProvider.notifier).setProvider(providers.first.id);
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Provider', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppSpacing.s),
                    DropdownButtonFormField<String>(
                      initialValue: providers.any((p) => p.id == aiSettings.selectedProvider) 
                          ? aiSettings.selectedProvider 
                          : null,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                      ),
                      items: providers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                      onChanged: (val) {
                        if (val != null) ref.read(aiSettingsProvider.notifier).setProvider(val);
                      },
                    ),
                    
                    const SizedBox(height: AppSpacing.m),
                    const Text('Select Model', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppSpacing.s),
                    if (aiSettings.selectedProvider != null)
                      ref.watch(modelsProvider(aiSettings.selectedProvider!)).when(
                        data: (models) {
                          if (models.isEmpty) return const Text('No models found.');
                          
                          // Auto-select first model if none selected
                          if (aiSettings.selectedModel == null) {
                             WidgetsBinding.instance.addPostFrameCallback((_) {
                               ref.read(aiSettingsProvider.notifier).setModel(models.first.id);
                             });
                          }

                          return DropdownButtonFormField<String>(
                            initialValue: models.any((m) => m.id == aiSettings.selectedModel)
                                ? aiSettings.selectedModel
                                : null,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
                            ),
                            items: models.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                            onChanged: (val) {
                              if (val != null) ref.read(aiSettingsProvider.notifier).setModel(val);
                            },
                          );
                        },
                        loading: () => const Center(child: Padding(
                          padding: EdgeInsets.all(AppSpacing.m),
                          child: CircularProgressIndicator(),
                        )),
                        error: (err, stack) => Text('Error loading models: $err', style: const TextStyle(color: AppColors.error)),
                      ),
                    
                    const SizedBox(height: AppSpacing.m),
                    const Text('API Key', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppSpacing.s),
                    TextFormField(
                      key: ValueKey(aiSettings.selectedProvider), 
                      initialValue: aiSettings.selectedProvider != null 
                          ? aiSettings.apiKeys[aiSettings.selectedProvider!] ?? ''
                          : '',
                      obscureText: !isApiKeyVisible,
                      decoration: InputDecoration(
                        hintText: 'Enter API key (stored in memory)',
                        prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isApiKeyVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => ref.read(apiKeyVisibilityProvider.notifier).state = !isApiKeyVisible,
                        ),
                      ),
                      onChanged: (val) {
                        if (aiSettings.selectedProvider != null) {
                          ref.read(aiSettingsProvider.notifier).setApiKey(aiSettings.selectedProvider!, val);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: testState.isLoading 
                            ? null 
                            : () => ref.read(connectionTestProvider.notifier).testConnection(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.m),
                            side: const BorderSide(color: AppColors.primary, width: 1),
                          ),
                          disabledBackgroundColor: Colors.grey.shade100,
                        ),
                        child: testState.isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Testing Connection...'),
                                ],
                              )
                            : const Text('Test Connection'),
                      ),
                    ),
                    if (testState.result != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s),
                        child: Row(
                          children: [
                            Icon(
                              testState.result!.success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                              size: 16,
                              color: testState.result!.success ? AppColors.secondary : AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                testState.result!.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: testState.result!.success ? AppColors.secondary : AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(AppSpacing.l),
                child: CircularProgressIndicator(),
              )),
              error: (err, stack) => Column(
                children: [
                  Text('Failed to load providers: $err', style: const TextStyle(color: AppColors.error)),
                  TextButton.icon(
                    onPressed: () => ref.refresh(providersProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),

          _buildSection('AI Settings'),
          _buildSettingItem(
            Icons.psychology_outlined, 
            'AI Model', 
            () {}, 
            trailing: aiSettings.selectedModel ?? 'Not selected',
          ),
          _buildSettingItem(Icons.auto_awesome_mosaic_outlined, 'Response Style', () {}, trailing: 'Professional'),
          _buildTopKSelector(context, ref, aiSettings.topK),
          
          _buildSection('Knowledge Base'),
          _buildSettingItem(Icons.folder_copy_outlined, 'Manage Documents', () {}),
          _buildSettingItem(Icons.cloud_done_outlined, 'Storage Usage', () {}, trailing: '15/100 MB'),
          _buildSettingItem(Icons.delete_sweep_outlined, 'Clear Knowledge Base', () {}, color: AppColors.error),
          
          _buildSection('Appearance'),
          _buildSettingItem(Icons.light_mode_outlined, 'Light Mode', () {}),
          _buildSettingItem(Icons.dark_mode_outlined, 'Dark Mode', () {}),
          
          _buildSection('Other'),
          _buildSettingItem(Icons.notifications_none_rounded, 'Notifications', () {}),
          _buildSettingItem(Icons.help_outline_rounded, 'Help & Support', () {}),
          _buildSettingItem(Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
          _buildSettingItem(Icons.info_outline_rounded, 'About RAG Agent', () {}),
          
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(navigationIndexProvider.notifier).state = 0;
                Navigator.of(context).pushReplacementNamed('/login');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.all(AppSpacing.m),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildTopKSelector(BuildContext context, WidgetRef ref, int currentVal) {
    return ListTile(
      leading: const Icon(Icons.format_list_numbered_rtl_rounded, size: 22),
      title: const Text('Number of Sources', style: TextStyle(fontWeight: FontWeight.w500)),
      trailing: DropdownButton<int>(
        value: currentVal,
        underline: const SizedBox(),
        items: [1, 2, 3, 4, 5, 8, 10].map((val) => DropdownMenuItem(value: val, child: Text(val.toString()))).toList(),
        onChanged: (val) {
          if (val != null) ref.read(aiSettingsProvider.notifier).setTopK(val);
        },
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.xl, AppSpacing.l, AppSpacing.s),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondaryLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap, {String? trailing, Color? color}) {
    return ListTile(
      leading: Icon(icon, size: 22, color: color ?? AppColors.textPrimaryLight),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.textPrimaryLight,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Flexible(
              child: Text(
                trailing,
                style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}
