import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/ai/ai_provider.dart';
import '../widgets/premium_page_header.dart';

class VoiceTeacherScreen extends StatefulWidget {
  const VoiceTeacherScreen({super.key});

  @override
  State<VoiceTeacherScreen> createState() => _VoiceTeacherScreenState();
}

class _VoiceTeacherScreenState extends State<VoiceTeacherScreen> {
  // Speech to Text
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  // Text to Speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  List<String> _responseChunks = [];
  int _currentChunkIndex = 0;
  
  // State
  bool _isThinking = false;
  String _aiResponse = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for Voice Teacher.')),
        );
      }
      return;
    }

    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
              // If it automatically stopped and we have words, trigger AI
              if (_lastWords.isNotEmpty && !_isThinking && _aiResponse.isEmpty) {
                _askAi();
              }
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('SpeechError: ${errorNotification.errorMsg}');
          if (mounted) {
            setState(() {
              _isListening = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Speech error: ${errorNotification.errorMsg}')),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('SpeechInitError: $e');
      _speechEnabled = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initialize speech recognition: $e')),
        );
      }
    }
    
    if (mounted) {
      setState(() {});
      if (!_speechEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available on this device.')),
        );
      }
    }
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Natural conversational speed
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        _playNextChunk();
      }
    });

    _flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _toggleListening() async {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() async {
    if (_speechEnabled) {
      await _stopTts(); // stop any ongoing speech
      setState(() {
        _lastWords = '';
        _aiResponse = '';
        _isListening = true;
      });
      try {
        await _speechToText.listen(
          onResult: _onSpeechResult,
          listenOptions: stt.SpeechListenOptions(
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            cancelOnError: true,
            listenMode: stt.ListenMode.confirmation,
          ),
        );
      } catch (e) {
        debugPrint('ListenError: $e');
        setState(() {
          _isListening = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start listening: $e')),
          );
        }
      }
    } else {
      // If speech is not enabled, try initializing again
      await _initSpeech();
      if (_speechEnabled) {
        _startListening();
      }
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    if (_lastWords.isNotEmpty && !_isThinking) {
      _askAi();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
    
    // If the speech engine is completely confident it's final
    if (result.finalResult && _lastWords.isNotEmpty && !_isThinking) {
      _askAi();
    }
  }

  Future<void> _askAi() async {
    if (_lastWords.trim().isEmpty) return;
    
    setState(() {
      _isThinking = true;
    });

    try {
      final aiProvider = context.read<AiProvider>();
      final response = await aiProvider.askVoiceTeacher(question: _lastWords);
      
      if (mounted) {
        setState(() {
          _aiResponse = response;
          _isThinking = false;
        });
        _prepareAndPlayTts(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiResponse = "Sorry, I had trouble thinking of an answer. Let's try again.";
          _isThinking = false;
        });
        _prepareAndPlayTts(_aiResponse);
      }
    }
  }

  void _prepareAndPlayTts(String text) {
    // Chunking by sentences to ensure smooth playback for long responses.
    // We split by standard sentence terminators (.!?) followed by space or newline.
    _responseChunks = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
        
    if (_responseChunks.isEmpty) {
      _responseChunks = [text];
    }
    
    _currentChunkIndex = 0;
    _playCurrentChunk();
  }

  Future<void> _playCurrentChunk() async {
    if (_currentChunkIndex < _responseChunks.length) {
      await _flutterTts.speak(_responseChunks[_currentChunkIndex]);
    } else {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _playNextChunk() {
    _currentChunkIndex++;
    if (_currentChunkIndex < _responseChunks.length) {
      _playCurrentChunk();
    } else {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _stopTts() async {
    await _flutterTts.stop();
    setState(() {
      _isPlaying = false;
    });
  }
  
  Future<void> _replayTts() async {
    await _stopTts();
    _currentChunkIndex = 0;
    _playCurrentChunk();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Voice Teacher'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: PremiumPageHeader(
                topLabel: 'Interactive',
                emoji: '🗣️',
                title: 'Voice Teacher',
                subtitle: 'Speak naturally. Learn effectively.',
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Transcript Area
                    if (_lastWords.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.primaryColor.withAlpha(50),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You said:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _lastWords,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      
                    const SizedBox(height: 24),
                    
                    // AI Response Area
                    if (_isThinking)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_aiResponse.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor.withAlpha(20),
                              theme.primaryColor.withAlpha(10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.primaryColor.withAlpha(80),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.record_voice_over, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Voice Teacher:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _aiResponse,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.5,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            // Playback Controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.replay),
                                  onPressed: _replayTts,
                                  tooltip: 'Replay',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.stop),
                                  onPressed: _stopTts,
                                  tooltip: 'Stop',
                                ),
                                IconButton(
                                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                                  onPressed: () {
                                    if (_isPlaying) {
                                      _flutterTts.pause();
                                    } else {
                                      _playCurrentChunk();
                                    }
                                  },
                                  tooltip: _isPlaying ? 'Pause' : 'Play',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Microphone Button
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Center(
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _isListening ? 90 : 80,
                    width: _isListening ? 90 : 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening 
                          ? [Colors.red, Colors.redAccent]
                          : [theme.primaryColor, theme.primaryColor.withAlpha(200)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isListening 
                              ? Colors.red.withAlpha(100) 
                              : theme.primaryColor.withAlpha(100),
                          blurRadius: _isListening ? 30 : 15,
                          spreadRadius: _isListening ? 10 : 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _speechEnabled 
                  ? (_isListening ? 'Listening...' : 'Tap to speak')
                  : 'Speech recognition not available',
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
