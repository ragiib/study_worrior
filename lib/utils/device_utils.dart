import 'dart:io';

class DeviceUtils {
  /// Returns the device RAM in GB, or 0 if it cannot be determined.
  static Future<int> getDeviceRamGB() async {
    try {
      if (Platform.isAndroid) {
        final file = File('/proc/meminfo');
        if (await file.exists()) {
          final lines = await file.readAsLines();
          for (final line in lines) {
            if (line.startsWith('MemTotal:')) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length >= 2) {
                final kb = int.tryParse(parts[1]) ?? 0;
                return (kb / 1024 / 1024).round();
              }
            }
          }
        }
      }
    } catch (_) {}
    return 0; // Unknown
  }
}
