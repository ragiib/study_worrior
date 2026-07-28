import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../../services/ai/ai_model_manager.dart';

class PrepareOfflineAiScreen extends StatefulWidget {
  final VoidCallback onDownloadComplete;

  const PrepareOfflineAiScreen({
    super.key,
    required this.onDownloadComplete,
  });

  @override
  State<PrepareOfflineAiScreen> createState() => _PrepareOfflineAiScreenState();
}

class _PrepareOfflineAiScreenState extends State<PrepareOfflineAiScreen> {
  bool _wifiOnly = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wifiOnly = prefs.getBool('ai_download_wifi_only') ?? true;
    });
  }

  Future<void> _savePreferences(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_download_wifi_only', value);
    setState(() {
      _wifiOnly = value;
    });
  }

  void _startDownload(BuildContext context) async {
    final manager = context.read<AiModelManager>();
    setState(() {
      _error = null;
    });
    try {
      await manager.downloadModel(wifiOnly: _wifiOnly);
      if (manager.isDownloaded) {
        widget.onDownloadComplete();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Prepare Offline AI'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AiModelManager>(
        builder: (context, manager, child) {
          if (manager.isDownloaded && !manager.isDownloading) {
            // Should not happen, but just in case
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onDownloadComplete();
            });
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 80,
                  color: AppTheme.accentPurple,
                ),
                const SizedBox(height: 32),
                Text(
                  'Powering Up Your Device',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'To use AI features completely offline, securely, and with zero latency, Study Warrior needs to download the Qwen AI model directly to your phone.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withAlpha(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Model', 'Qwen 2.5 (0.5B Instruct)', Icons.model_training),
                      const Divider(height: 24),
                      _buildDetailRow('Download Size', '~350 MB', Icons.data_usage),
                      const Divider(height: 24),
                      _buildDetailRow('Storage Required', '~350 MB', Icons.storage),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Wi-Fi Toggle
                if (!manager.isDownloading)
                  SwitchListTile(
                    title: const Text('Download over Wi-Fi only'),
                    subtitle: const Text('Recommended to save mobile data'),
                    value: _wifiOnly,
                    onChanged: _savePreferences,
                    activeColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 32),

                if (manager.isDownloading) ...[
                  LinearProgressIndicator(
                    value: manager.downloadProgress,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                    backgroundColor: AppTheme.primaryColor.withAlpha(30),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Downloading...',
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${(manager.downloadProgress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => manager.cancelDownload(),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel Download'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  )
                ] else
                  ElevatedButton(
                    onPressed: () => _startDownload(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Start Download',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.accentPurple),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
