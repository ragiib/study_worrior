# Flutter Development Workflow Rule

When making changes to the Study Warrior app:

1. **Incremental Updates**: As the agent, you must always prefer using `flutter run` in the background for active development on physical Android devices. 
2. **Automatic Hot Reload/Restart**: When you (the agent) make code/UI changes, you must automatically and silently send the `r` (Hot Reload) or `R` (Hot Restart) input to the running `flutter run` task via the `manage_task` tool with `send_input`. **Do NOT ask the user to manually run these commands, and do NOT ask for permission to hot reload.**
3. **Preserve State**: Do NOT uninstall the app or run commands like `adb uninstall` or `flutter install` unless explicitly required by native changes. This preserves the downloaded AI models (~350 MB) and app data on the device.
4. **Full Rebuilds**: Only perform a full APK rebuild and reinstall (`flutter build apk` + `adb install -r`) when a change genuinely requires native Android changes, native C/C++ libraries, Gradle configuration, AndroidManifest changes, ABI/native dependencies, or if hot restart fails to apply changes. Always verify if a full reinstall is truly required before doing it.
5. **Verification**: After applying changes incrementally, instruct the user to verify the results on their connected physical Android device.
