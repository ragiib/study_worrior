# Flutter Development Workflow Rule

When making changes to the Study Warrior app:

1. **Standard Deployment Method**: Use **Build APK + Update Install** (`flutter build apk --debug` followed by `adb install -r -d <apk_path>` and launching via adb shell) as the primary deployment workflow. Do **not** rely on Hot Reload (`r`) or Hot Restart (`R`) as the primary method.
2. **Preserve State**: Do **not** uninstall the existing app unless absolutely required. Preserve app data, downloaded AI models, conversation history, and user settings. 
3. **App Launching**: Launch the updated app automatically after install.
4. **Verification**: Verify that the latest code is running on the physical device before reporting completion.
5. **Hot Reload Exceptions**: Only use Hot Reload or Hot Restart for quick debugging during an active session if no native, plugin, FFI, or initialization code has changed. For normal development and feature verification, always perform a Build APK + Update Install.
6. **No Unnecessary Deletions**: Do not clear caches, uninstall the app, or delete AI model files unless there is a proven technical reason. If such a step becomes necessary, explain why before doing it.
