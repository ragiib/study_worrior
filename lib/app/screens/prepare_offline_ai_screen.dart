import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../../services/ai/ai_model_manager.dart';
import '../../utils/device_utils.dart';

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
  int _deviceRamGB = 0;
  AiModelTier? _selectedTier;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _detectDeviceRam();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wifiOnly = prefs.getBool('ai_download_wifi_only') ?? true;
    });
  }

  Future<void> _detectDeviceRam() async {
    final ram = await DeviceUtils.getDeviceRamGB();
    setState(() {
      _deviceRamGB = ram;
      if (ram > 0) {
        if (ram >= 12) {
          _selectedTier = AiModelTier.tier8GB;
        } else if (ram >= 8) {
          _selectedTier = AiModelTier.tier8GB;
        } else if (ram >= 6) {
          _selectedTier = AiModelTier.tier6GB;
        } else {
          _selectedTier = AiModelTier.tier4GB;
        }
      }
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
    if (_selectedTier == null) return;
    final manager = context.read<AiModelManager>();
    
    // Check if it already exists
    if (await manager.doesModelExistLocally(_selectedTier!)) {
      await manager.switchActiveModel(_selectedTier!);
      widget.onDownloadComplete();
      return;
    }

    setState(() {
      _error = null;
    });
    
    try {
      await manager.downloadModel(_selectedTier!, wifiOnly: _wifiOnly);
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
        title: const Text(
          'Intelligence Setup',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AiModelManager>(
        builder: (context, manager, child) {
          if (manager.isDownloaded && !manager.isDownloading && manager.selectedTier == _selectedTier) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onDownloadComplete();
            });
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.memory_rounded,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Choose Your Device's RAM",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Study Warrior will adapt its AI engine to run as smoothly as possible on your hardware.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (_deviceRamGB > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 24.0),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 20, color: AppTheme.accentOrange),
                          const SizedBox(width: 8),
                          Text(
                            'Auto-Detected RAM: ~$_deviceRamGB GB',
                            style: TextStyle(
                              color: AppTheme.accentOrange, 
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  _buildRamSelector(),
                  const SizedBox(height: 32),
                  
                  if (_selectedTier != null) _buildModelInfoCard(),
                  
                  const SizedBox(height: 24),
                  
                  if (!manager.isDownloading)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Download over Wi-Fi only',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        subtitle: const Text('Recommended for large files'),
                        value: _wifiOnly,
                        onChanged: _savePreferences,
                        activeColor: AppTheme.primaryColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                    ),
                    
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 24.0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade400.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                  const SizedBox(height: 36),
                  
                  if (manager.isDownloading) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withAlpha(20),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: manager.downloadProgress,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(6),
                            backgroundColor: AppTheme.primaryColor.withAlpha(30),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Downloading...',
                                style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              Text(
                                '${(manager.downloadProgress * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextButton.icon(
                            onPressed: () => manager.cancelDownload(),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Cancel Download'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade400,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          )
                        ],
                      ),
                    )
                  ] else
                    ElevatedButton(
                      onPressed: _selectedTier == null ? null : () => _startDownload(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded),
                          SizedBox(width: 12),
                          Text(
                            'Download & Install Model',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    
                  const SizedBox(height: 48), // Bottom padding
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRamSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildRamChip('4 GB', AiModelTier.tier4GB)),
            const SizedBox(width: 8),
            Expanded(child: _buildRamChip('6 GB', AiModelTier.tier6GB)),
            const SizedBox(width: 8),
            Expanded(child: _buildRamChip('8 GB+', AiModelTier.tier8GB)),
          ],
        );
      }
    );
  }

  Widget _buildRamChip(String label, AiModelTier tier) {
    final isSelected = _selectedTier == tier;
    final requiredRam = AiModelManager.availableModels[tier]!.requiredRamGB;
    final isWarning = isSelected && _deviceRamGB > 0 && _deviceRamGB < requiredRam;

    final Color activeColor = isWarning ? Colors.orange : AppTheme.primaryColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTier = tier;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [
            BoxShadow(
              color: activeColor.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withAlpha(30),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelInfoCard() {
    final config = AiModelManager.availableModels[_selectedTier!]!;
    final isWarning = _deviceRamGB > 0 && _deviceRamGB < config.requiredRamGB;

    String badgeEmoji;
    String badgeText;
    Color badgeColor;
    
    switch (config.tier) {
      case AiModelTier.tier4GB:
        badgeEmoji = '⚡';
        badgeText = 'Fast';
        badgeColor = Colors.blue;
        break;
      case AiModelTier.tier6GB:
        badgeEmoji = '🧠';
        badgeText = 'Balanced';
        badgeColor = AppTheme.accentPurple;
        break;
      case AiModelTier.tier8GB:
        badgeEmoji = '🚀';
        badgeText = 'Advanced';
        badgeColor = AppTheme.accentOrange;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isWarning ? Colors.orange.withAlpha(100) : badgeColor.withAlpha(30),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Text(badgeEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    config.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.description, 
                  style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sd_storage_rounded, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text('Download Size', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Text(config.displaySize, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                if (isWarning) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withAlpha(50)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This model requires ${config.requiredRamGB}GB RAM. It may be too slow or crash on your device.',
                            style: const TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
