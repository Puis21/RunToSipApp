import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
//import 'package:animations/animations.dart'; REPLACED WITH ANIMATED TEXT KIT FOR EASIER IMPLEMENTATION
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

class LevelUpAnimation extends StatefulWidget {
  final int newLevel;

  const LevelUpAnimation({super.key, required this.newLevel});

  @override
  State<LevelUpAnimation> createState() => _LevelUpAnimationState();
}

class _LevelUpAnimationState extends State<LevelUpAnimation>
    with TickerProviderStateMixin{

  ///For Progress Bar
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  bool _showTextAnimation = false;

  ///Confetti and audio player
  late ConfettiController _confettiController;
  late final AudioPlayer _audioPlayer;
  bool _isPlayingSound = false;

  @override
  void initState() {
    super.initState();

    // Set up progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _progressAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showTextAnimation = true);
      }
    });

    _progressController.forward(); // Start animation

    //Audio set up
    _audioPlayer = AudioPlayer();
    _playSound();

    //Confetti set up
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _confettiController.play();

    //Set life span
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pop(); // Auto-close after 3 seconds
    });

  }

  @override
  void dispose() {
    _progressController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound() async {
    if (_isPlayingSound) return;

    setState(() => _isPlayingSound = true);
    try {
      await _audioPlayer.play(
        AssetSource('sounds/level_up.mp3'),
        volume: 0.8, // Adjust volume (0.0 to 1.0)
      );
    } catch (e) {
      debugPrint('Sound error: $e');
    } finally {
      setState(() => _isPlayingSound = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background overlay
        Container(
          color: Colors.black.withOpacity(0.7),
          width: double.infinity,
          height: double.infinity,
        ),

        // Confetti effect
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 20,
            gravity: 0.5,
            maxBlastForce: 25,
            minBlastForce: 15,
            colors: const [
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.red,
              Colors.orange
            ],
          ),
        ),

        // Level-up content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars, size: 100, color: Colors.yellow),
              const SizedBox(height: 10),
              Container(
                width: 100,
                child:  AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, _) {
                    return LinearProgressIndicator(
                      value: _progressAnimation.value,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                      valueColor: AlwaysStoppedAnimation(Colors.blue),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              if (_showTextAnimation)
              AnimatedTextKit(
                animatedTexts: [
                  ScaleAnimatedText(
                    'LEVEL UP!',
                    textStyle: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    scalingFactor: 0.5,
                    duration: const Duration(seconds: 3),
                  ),
                ],
                isRepeatingAnimation: false,
              ),
              const SizedBox(height: 10),
              Text(
                'You reached level ${widget.newLevel}!',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
