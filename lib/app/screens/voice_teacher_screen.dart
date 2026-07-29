import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/ai/ai_provider.dart';
import '../../../services/database_service.dart';
import '../../../models/chat_message.dart';
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
  List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _initSpeech();
    _initTts();
  }

  Future<void> _loadHistory() async {
    final db = context.read<DatabaseService>();
    final rawMessages = await db.getVoiceConversation();
    if (mounted) {
      setState(() {
        _messages = rawMessages.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return ChatMessage.fromMap(map);
        }).toList();
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveHistory() async {
    final db = context.read<DatabaseService>();
    await db.saveVoiceConversation(_messages.map((m) => m.toMap()).toList());
  }

  void _clearConversation() async {
    await _stopTts();
    final db = context.read<DatabaseService>();
    await db.clearVoiceConversation();
    if (mounted) {
      setState(() {
        _messages.clear();
        _lastWords = '';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
              if (_lastWords.isNotEmpty && !_isThinking) {
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
    
    final question = _lastWords;
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: question));
      _lastWords = '';
      _isThinking = true;
    });
    _saveHistory();
    _scrollToBottom();

    try {
      final aiProvider = context.read<AiProvider>();
      
      // Pass history excluding the current question we just added
      final history = _messages.sublist(0, _messages.length - 1);
      
      final response = await aiProvider.askVoiceTeacher(
        question: question,
        history: history,
      );
      
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'ai', content: response));
          _isThinking = false;
        });
        _saveHistory();
        _scrollToBottom();
        _prepareAndPlayTts(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'ai', content: "Sorry, I had trouble thinking of an answer. Let's try again."));
          _isThinking = false;
        });
        _saveHistory();
        _scrollToBottom();
        _prepareAndPlayTts(_messages.last.content);
      }
    }
  }

  void _prepareAndPlayTts(String text) {
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
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(String text, bool isUser, ThemeData theme, bool isDark) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser 
              ? (isDark ? Colors.grey[800] : Colors.grey[200])
              : (theme.primaryColor.withAlpha(20)),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
          ),
          border: isUser ? null : Border.all(
            color: theme.primaryColor.withAlpha(50),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.record_voice_over, 
                  size: 14,
                  color: isUser ? theme.textTheme.bodySmall?.color : theme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? 'You' : 'Voice Teacher',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isUser ? theme.textTheme.bodySmall?.color : theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'New Conversation',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('New Conversation?'),
                  content: const Text('This will clear the current conversation history.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearConversation();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
              child: _messages.isEmpty && _lastWords.isEmpty && !_isThinking
                ? Center(
                    child: Text(
                      'Tap the microphone to start learning.',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24.0),
                    itemCount: _messages.length + (_lastWords.isNotEmpty ? 1 : 0) + (_isThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Messages
                      if (index < _messages.length) {
                        final msg = _messages[index];
                        return _buildMessageBubble(msg.content, msg.role == 'user', theme, isDark);
                      }
                      
                      int offset = index - _messages.length;
                      
                      // Active listening transcript
                      if (_lastWords.isNotEmpty) {
                        if (offset == 0) {
                          return _buildMessageBubble(_lastWords, true, theme, isDark);
                        }
                        offset--;
                      }
                      
                      // Thinking indicator
                      if (_isThinking && offset == 0) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
            ),
            
            // Playback Controls if AI just spoke
            if (_messages.isNotEmpty && _messages.last.role == 'ai' && !_isThinking && !_isListening)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
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
              ),
            
            // Microphone Button
            Container(
              padding: const EdgeInsets.only(top: 16, bottom: 32),
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
