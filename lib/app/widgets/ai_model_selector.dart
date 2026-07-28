import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class AiModelSelector extends StatefulWidget {
  const AiModelSelector({super.key});

  @override
  State<AiModelSelector> createState() => _AiModelSelectorState();
}

class _AiModelSelectorState extends State<AiModelSelector> {
  String? _modelPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModelPath();
  }

  Future<void> _loadModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _modelPath = prefs.getString('local_gguf_model_path');
      _isLoading = false;
    });
  }

  Future<void> _pickModelFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any, // Android might not associate .gguf properly with custom extensions
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      
      // Basic validation (optional)
      if (!path.toLowerCase().endsWith('.gguf')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Warning: Selected file does not have a .gguf extension.')),
          );
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_gguf_model_path', path);

      setState(() {
        _modelPath = path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model file selected successfully.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasModel = _modelPath != null && _modelPath!.isNotEmpty;
    final filename = hasModel ? _modelPath!.split('/').last : 'None';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.memory_rounded, color: AppTheme.secondaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Local AI Model',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasModel ? filename : 'Select a .gguf model file',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: hasModel ? AppTheme.secondaryColor : Colors.redAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _pickModelFile,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondaryColor,
                ),
                child: Text(hasModel ? 'Change' : 'Select'),
              ),
            ],
          ),
          if (hasModel) ...[
            const SizedBox(height: 12),
            Text(
              _modelPath!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey),
            ),
          ]
        ],
      ),
    );
  }
}
