import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/libraries/extensions/extensions.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const Duration _initialDelay = Duration(milliseconds: 200);
  static const Duration _event2Duration = Duration(milliseconds: 400);
  static const Duration _event3Duration = Duration(milliseconds: 600);
  static const Duration _finalDelay = Duration(milliseconds: 1200);

  static const double _animationStart = 0.0;
  static const double _animationEnd = 1.0;
  static const double _event2Target = 1.0;
  static const double _event3Target = 2.0;
  static const double _imageSize = 120.0;
  static const double _textBottomPosition = 50.0;
  static const double _edgePosition = 0.0;
  static const double _divisionFactor = 2.0;
  static const double _fontSize = 28.0;
  static const FontWeight _fontWeight = FontWeight.w600;

  late AnimationController _imageTransitionController;
  late Animation<double> _imageTransitionAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    _imageTransitionController = AnimationController(
      duration: _event2Duration + _event3Duration,
      vsync: this,
    );

    _imageTransitionAnimation =
        Tween<double>(begin: _animationStart, end: _event3Target).animate(
          CurvedAnimation(
            parent: _imageTransitionController,
            curve: const Interval(
              _animationStart,
              _animationEnd,
              curve: Curves.linear,
            ),
          ),
        );
  }

  void _startAnimationSequence() async {
    await Future.delayed(_initialDelay);

    await _imageTransitionController.animateTo(
      _event2Target / _divisionFactor,
      duration: _event2Duration,
      curve: Curves.easeInQuad,
    );

    await _imageTransitionController.animateTo(
      _event3Target,
      duration: _event3Duration,
      curve: Curves.easeOutQuad,
    );

    if (mounted) {
      await Future.delayed(_finalDelay);
      Modular.to.navigate('/auth');
    }
  }

  @override
  void dispose() {
    _imageTransitionController.dispose();
    super.dispose();
  }

  String _getCurrentImage() {
    double value = _imageTransitionAnimation.value;
    if (value < _event2Target) {
      return 'assets/images/first.png';
    } else if (value < _event3Target) {
      return 'assets/images/second.png';
    } else {
      return 'assets/images/third.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    return Scaffold(
      backgroundColor: colors.backgroundDarkOrient,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _imageTransitionController,
              builder: (context, child) {
                return Image.asset(
                  _getCurrentImage(),
                  width: _imageSize,
                  height: _imageSize,
                );
              },
            ),
          ),

          Positioned(
            bottom: _textBottomPosition,
            left: _edgePosition,
            right: _edgePosition,
            child: Center(
              child: Text(
                'Construculator',
                style: context.textTheme.headlineMediumSemiBold.copyWith(
                  color: colors.textInverse,
                  fontSize: _fontSize,
                  fontWeight: _fontWeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
