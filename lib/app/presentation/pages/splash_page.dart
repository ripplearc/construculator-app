import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/libraries/extensions/extensions.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _calculatorController;
  late AnimationController _buttonController;
  late AnimationController _textController;
  
  late Animation<double> _calculatorAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Calculator animation controller (150ms + 450ms = 600ms total)
    _calculatorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Button animation controller (100ms for blink)
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Text animation controller (fade in)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Calculator animation: starts from bottom (behind roof) to fully visible
    _calculatorAnimation = Tween<double>(
      begin: 1.0, // Start from bottom (fully behind roof)
      end: 0.0,   // End at top (fully visible)
    ).animate(CurvedAnimation(
      parent: _calculatorController,
      curve: const Interval(
        0.0,
        1.0,
        curve: Cubic(0.25, 0.46, 0.45, 0.94), // Custom curve for accel/deaccel
      ),
    ));

    // Button blink animation: opacity from 1 to 0 to 1
    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    // Text fade in animation
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimationSequence() async {
    // Event 1: Only roof visible (initial state)
    await Future.delayed(const Duration(milliseconds: 100));

    // Event 2: Calculator rising to half visible (150ms)
    _calculatorController.forward();
    await _calculatorController.animateTo(0.25); // 25% of animation = half visible

    // Event 3: Calculator continues to fully visible (450ms)
    // Event 4: Button blinks (starts 100ms before calculator animation ends)
    
    // Start button blink 100ms before calculator animation completes
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _buttonController.forward().then((_) {
          _buttonController.reverse(); // Complete the blink
        });
      }
    });

    // Complete calculator animation
    await _calculatorController.forward();

    // Show text after calculator animation completes
    if (mounted) {
      _textController.forward();
    }

    // Navigate to main app after animation completes
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      Modular.to.navigate('/auth');
    }
  }

  @override
  void dispose() {
    _calculatorController.dispose();
    _buttonController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF015B7C), // Dark teal background
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_calculatorController, _buttonController, _textController]),
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon stack (roof + calculator + button)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Roof image (always visible)
                    Image.asset(
                      'assets/images/roof.png',
                      width: 120,
                      height: 120,
                    ),
                    
                    // Calculator image (animated)
                    Positioned(
                      bottom: 60 * _calculatorAnimation.value,
                      child: Image.asset(
                        'assets/images/calculator.png',
                        width: 100,
                        height: 100,
                      ),
                    ),
                    
                    // Blue button overlay (for blinking effect)
                    Positioned(
                      bottom: 60 * _calculatorAnimation.value + 40, // Position on calculator button
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Opacity(
                          opacity: 1.0 - _buttonAnimation.value, // Invert for blink effect
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2196F3), // Blue color
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Construculator text (fade in)
                Opacity(
                  opacity: _textAnimation.value,
                  child: Text(
                    'Construculator',
                    style: context.textTheme.headlineMediumSemiBold.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
