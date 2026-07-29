import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../constants/engagement_messages.dart';

class AnimatedAiLoader extends StatefulWidget {
  final String? customText;
  final bool isCompact;
  final bool isSuccessSequence;

  const AnimatedAiLoader({
    super.key,
    this.customText,
    this.isCompact = false,
    this.isSuccessSequence = false,
  });

  @override
  State<AnimatedAiLoader> createState() => _AnimatedAiLoaderState();
}

class _AnimatedAiLoaderState extends State<AnimatedAiLoader> with TickerProviderStateMixin {
  final List<String> _aiPhrases = [
    "Thinking...",
    "Analyzing...",
    "Processing...",
    "Creating...",
    "Formulating...",
    "Preparing...",
  ];

  int _currentPhraseIndex = 0;
  Timer? _statusTimer;
  
  // Final sequence state
  String? _finalSequenceText;
  
  // Engagement content state
  Timer? _engagementTimer;
  String? _currentEngagementMessage;
  static final List<int> _recentEngagementIndices = [];
  final Random _random = Random();

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Cycle phrases every 3.5 seconds (slow, calm rhythm)
    _statusTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (mounted && !widget.isSuccessSequence) {
        setState(() {
          _currentPhraseIndex = (_currentPhraseIndex + 1) % _aiPhrases.length;
        });
      }
    });

    // Handle engagement messages if not compact
    if (!widget.isCompact) {
      _pickNextEngagementMessage();
      _engagementTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (mounted && !widget.isSuccessSequence) {
          setState(() {
            _pickNextEngagementMessage();
          });
        }
      });
    }

    // Subtle pulsing glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slightly slower glow for calm feel
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void didUpdateWidget(AnimatedAiLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSuccessSequence && !oldWidget.isSuccessSequence) {
      _runSuccessSequence();
    }
  }
  
  void _runSuccessSequence() async {
    if (!mounted) return;
    setState(() {
      _finalSequenceText = "Almost there...";
      _currentEngagementMessage = null; // Hide engagement message during final sequence
    });
    
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    
    setState(() {
      _finalSequenceText = "There you go! ✨";
    });
  }

  void _pickNextEngagementMessage() {
    if (engagementMessages.isEmpty) return;
    
    // Clear history if it gets too large (keep last 10 or half the list)
    final maxHistory = (engagementMessages.length / 2).ceil().clamp(0, 10);
    if (_recentEngagementIndices.length >= maxHistory) {
      _recentEngagementIndices.removeAt(0);
    }

    int nextIndex;
    int attempts = 0;
    do {
      nextIndex = _random.nextInt(engagementMessages.length);
      attempts++;
    } while (_recentEngagementIndices.contains(nextIndex) && attempts < 10);

    _recentEngagementIndices.add(nextIndex);
    _currentEngagementMessage = engagementMessages[nextIndex];
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _engagementTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  bool _isGenerating() {
    if (widget.customText == null) return true;
    final t = widget.customText!.toLowerCase();
    return t.contains('generating') || t.contains('solving') || t.contains('thinking') || t.contains('processing');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String displayText;
    if (_finalSequenceText != null) {
      displayText = _finalSequenceText!;
    } else {
      displayText = _isGenerating() ? _aiPhrases[_currentPhraseIndex] : widget.customText!;
    }
    
    if (widget.isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withOpacity(_glowAnimation.value),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(_glowAnimation.value * 0.5),
                      blurRadius: 8 * _glowAnimation.value,
                      spreadRadius: 2 * _glowAnimation.value,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              displayText,
              key: ValueKey<String>(displayText),
              style: TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      );
    }

    // Full screen / large version
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(_glowAnimation.value * 0.3),
                          blurRadius: 30 * _glowAnimation.value,
                          spreadRadius: 10 * _glowAnimation.value,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    widget.isSuccessSequence ? Icons.check_circle : Icons.auto_awesome,
                    color: widget.isSuccessSequence 
                        ? Colors.green 
                        : theme.primaryColor.withOpacity(_glowAnimation.value),
                    size: 32,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800), // Slightly slower text transition
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              displayText,
              key: ValueKey<String>(displayText),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.isSuccessSequence ? Colors.green : theme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 48), // Spacing before engagement content
          
          // Independent Engagement Content
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: _currentEngagementMessage != null ? 80 : 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _currentEngagementMessage != null
                  ? Container(
                      key: ValueKey<String>(_currentEngagementMessage!),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.primaryColor.withAlpha(20),
                        ),
                      ),
                      child: Text(
                        _currentEngagementMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.textTheme.bodyMedium?.color?.withAlpha(200),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
