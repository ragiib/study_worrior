import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedAiLoader extends StatefulWidget {
  final String? customText;
  final bool isCompact;

  const AnimatedAiLoader({
    super.key,
    this.customText,
    this.isCompact = false,
  });

  @override
  State<AnimatedAiLoader> createState() => _AnimatedAiLoaderState();
}

class _AnimatedAiLoaderState extends State<AnimatedAiLoader> with TickerProviderStateMixin {
  final List<String> _aiPhrases = [
    "Thinking...",
    "Analyzing...",
    "Understanding...",
    "Processing...",
    "Generating...",
    "Formulating...",
    "Preparing answer...",
    "Almost there...",
  ];

  int _currentPhraseIndex = 0;
  Timer? _timer;
  
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Cycle phrases every 2.5 seconds
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) {
        setState(() {
          _currentPhraseIndex = (_currentPhraseIndex + 1) % _aiPhrases.length;
        });
      }
    });

    // Subtle pulsing glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    final String displayText = _isGenerating() ? _aiPhrases[_currentPhraseIndex] : widget.customText!;
    
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
            duration: const Duration(milliseconds: 500),
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
    return Column(
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
                  Icons.auto_awesome,
                  color: theme.primaryColor.withOpacity(_glowAnimation.value),
                  size: 32,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
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
              color: theme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
