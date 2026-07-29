# Discontinued Package & Llama Model Loading Analysis

## 1. The Discontinued Package

| Field | Value |
|---|---|
| **Package** | `flutter_markdown` |
| **Locked version** | `0.7.7+1` |
| **Status** | **Discontinued** — replaced by `flutter_markdown_plus` |
| **Dependency type** | Direct (line 39 of [pubspec.yaml](file:///c:/study_worrior/pubspec.yaml)) |
| **Used in** | [ai_notes_viewer_screen.dart](file:///c:/study_worrior/lib/app/screens/ai_notes_viewer_screen.dart), [ai_doubt_solver_screen.dart](file:///c:/study_worrior/lib/app/screens/ai_doubt_solver_screen.dart) |

The exact warning from `flutter pub get`:
```
flutter_markdown 0.7.7+1 (discontinued replaced by flutter_markdown_plus)
```

### Why is it discontinued?
The Flutter team discontinued the official `flutter_markdown` package and recommended migration to `flutter_markdown_plus`, a community-maintained successor.

---

## 2. Is `flutter_markdown` Involved in Llama/Qwen Model Loading?

**No.** `flutter_markdown` is a UI rendering widget for displaying markdown text. It has zero relationship to:
- Native library loading (`libllama.so`, `libmtmd.so`)
- FFI bindings
- Model inference
- The `llama_cpp_dart` package

It is used **only** for displaying AI-generated responses as formatted markdown in the chat/notes UI.

---

## 3. Can Its Discontinued Status Cause `LlamaException: failed to initialize Llama` / `could not load model`?

**No, absolutely not.** The discontinued status of `flutter_markdown`:
- Does not affect native library compilation or packaging
- Does not affect FFI symbol resolution
- Does not affect model file loading from disk
- Does not affect the `llama_cpp_dart` dependency chain in any way

---

## 4. Llama Flutter Package Compatibility

| Component | Current Version | Compatibility |
|---|---|---|
| `llama_cpp_dart` | `0.2.2` (local path override) | SDK constraint: `>=3.2.0 <4.0.0` ✅ |
| Flutter constraint | `>=1.20.0` | Your Flutter `>=3.29.0` ✅ |
| Android `compileSdk` | `34` (plugin) | Compatible ✅ |
| NDK | `25.1.8937393` (llamalib) | Compatible ✅ |
| `ffi` | `^2.1.4` → resolved `2.2.0` | Compatible ✅ |
| `typed_isolate` | `^6.0.0` → resolved `6.0.0` | Compatible ✅ |

The Dart/Flutter version constraints are satisfied. The package itself is compatible.

---

## 5. Native `.so` Library Dependencies

**Yes**, the package depends critically on native `.so` libraries. Here is the full chain:

### Dependency Chain
```
Your App (Dart)
  └── llama_cpp_dart (local path: ./local_llama_dart)
        ├── pubspec.yaml: ffiPlugin: true (Android)
        ├── Dart FFI: DynamicLibrary.open("libmtmd.so")  ← entry point
        │
        └── Native build (CMakeLists.txt + llamalib/build.gradle)
              ├── libmtmd.so  ← TOP-LEVEL .so loaded by Dart
              │     ├── links: libllama.so
              │     ├── links: libggml.so
              │     ├── links: libggml-base.so
              │     ├── links: libggml-cpu.so
              │     ├── links: libggml-opencl.so
              │     ├── links: libOpenCL.so (prebuilt, from src/opencl-libs/)
              │     └── links: liblog.so (Android system)
              │
              └── Model loading flow:
                    Dart: Llama("path/to/model.gguf")
                      → _initializeLlama()
                        → llama_backend_init()
                        → llama_load_model_from_file()  [in libllama.so]
                        → llama_new_context_with_model() [in libllama.so]
```

### Key code in [llama.dart](file:///c:/study_worrior/local_llama_dart/lib/src/llama.dart#L68-L72):
```dart
// On Android, DynamicLibrary.process() does NOT include symbols from plugin
// .so files. We must explicitly open the top-level native library built by
// CMake. libmtmd.so is the wrapper that transitively links libllama.so and
// libggml.so, making all llama_* / ggml_* / mtmd_* symbols available.
static String? libraryPath = Platform.isAndroid ? "libmtmd.so" : null;
```

---

## 6. Are the Required Native Libraries Actually Packaged for `arm64-v8a`?

> [!CAUTION]
> **The `libmtmd.so` build for `arm64-v8a` FAILED.** This is the root cause of the `LlamaException`.

### Evidence from build logs

In [build_stdout_targets.txt](file:///c:/study_worrior/local_llama_dart/android/llamalib/build/intermediates/cxx/RelWithDebInfo/2k6914o6/logs/arm64-v8a/build_stdout_targets.txt#L339-L342):

```
[334/335] Linking CXX shared library bin\libllama.so        ← SUCCESS ✅
[335/335] Linking CXX shared library ...obj/arm64-v8a/libmtmd.so
FAILED: ...obj/arm64-v8a/libmtmd.so                         ← FAILED ❌
```

### The linker errors (20+ undefined vtable symbols):
```
ld: error: undefined symbol: vtable for mtmd_image_preprocessor_llava_uhd
ld: error: undefined symbol: vtable for mtmd_image_preprocessor_internvl
ld: error: undefined symbol: vtable for clip_graph_whisper_enc
ld: error: undefined symbol: vtable for clip_graph_llava
ld: error: undefined symbol: vtable for clip_graph_siglip
ld: error: undefined symbol: vtable for clip_graph_qwen2vl
ld: error: undefined symbol: vtable for clip_graph_qwen3vl
... (20+ more)
ld: error: too many errors emitted, stopping now
clang++: error: linker command failed with exit code 1
ninja: build stopped: subcommand failed.
```

### Root cause of the linker failure
The [CMakeLists.txt](file:///c:/study_worrior/local_llama_dart/src/CMakeLists.txt#L32-L41) compiles `mtmd.cpp`, `clip.cpp`, etc. and globs `llama.cpp/tools/mtmd/models/*.cpp`. However, the **model-specific source files** (which define the vtable key functions for `clip_graph_llava`, `clip_graph_qwen2vl`, `mtmd_image_preprocessor_*`, etc.) are **not being linked** into the `libmtmd.so` target. The glob `${MTMD_MODEL_SOURCES}` was added but likely the `models/` directory in the llama.cpp submodule doesn't contain all the required `.cpp` files, or they were added upstream after this snapshot was taken.

---

## Summary & Verdict

| Question | Answer |
|---|---|
| **Discontinued package** | `flutter_markdown` `0.7.7+1` (replaced by `flutter_markdown_plus`) |
| **Involved in Llama loading?** | ❌ **No** — purely UI rendering |
| **Can it cause `LlamaException`?** | ❌ **No** |
| **Actual cause of `LlamaException`** | ✅ **`libmtmd.so` failed to build for `arm64-v8a`** due to missing vtable symbols in the CMake build. Without `libmtmd.so`, `DynamicLibrary.open("libmtmd.so")` fails at runtime, which causes `LlamaException: failed to initialize Llama`. |
| **`libllama.so` built?** | ✅ Yes — step [334/335] succeeded |
| **`libmtmd.so` built?** | ❌ No — step [335/335] **FAILED** with 20+ linker errors |

> [!IMPORTANT]
> The `flutter_markdown` discontinuation is a **cosmetic warning** and is completely unrelated to the Llama model loading failure. The **real problem** is that `libmtmd.so` fails to compile for Android because the CMake build is missing source files for the multimodal model preprocessors (vtable key functions).

### What needs to happen (when you're ready to fix):
1. Fix the `CMakeLists.txt` to include all required model `.cpp` source files for the `mtmd` target
2. OR — since you're only using text-only Qwen models — refactor the Dart code to load `libllama.so` directly instead of `libmtmd.so` (the multimodal wrapper is unnecessary for text-only inference)
3. Separately, consider replacing `flutter_markdown` → `flutter_markdown_plus` to clear the discontinued warning
