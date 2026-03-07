import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const Duration _initialDelay = Duration.zero;
  static const Duration _event2Duration = Duration(milliseconds: 400);
  static const Duration _event3Duration = Duration(milliseconds: 600);
  static const Duration _finalDelay = Duration(milliseconds: 1200);

  static const double _animationStart = 0.0;
  static const double _animationEnd = 1.0;
  static const double _event2Target = 1.0;
  static const double _event3Target = 2.0;
  static const double _iconSize = 120.0;
  static const double _textBottomPosition = 50.0;
  static const double _edgePosition = 0.0;
  static const double _divisionFactor = 2.0;
  static const double _fontSize = 28.0;
  static const FontWeight _fontWeight = FontWeight.w600;

  late AnimationController _iconTransitionController;
  late Animation<double> _iconTransitionAnimation;
  bool _showIcon = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    _iconTransitionController = AnimationController(
      duration: _event2Duration + _event3Duration,
      vsync: this,
    );

    _iconTransitionAnimation =
        Tween<double>(begin: _animationStart, end: _event3Target).animate(
          CurvedAnimation(
            parent: _iconTransitionController,
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

    if (!mounted) return;
    setState(() {
      _showIcon = true;
    });

    await _iconTransitionController.animateTo(
      _event2Target / _divisionFactor,
      duration: _event2Duration,
      curve: Curves.easeInQuad,
    );

    await _iconTransitionController.animateTo(
      _event3Target,
      duration: _event3Duration,
      curve: Curves.easeOutQuad,
    );

    if (mounted) {
      await Future.delayed(_finalDelay);
      Modular.to.navigate('/dashboard/');
    }
  }

  @override
  void dispose() {
    _iconTransitionController.dispose();
    super.dispose();
  }

  CoreIconData _getCurrentIcon() {
    double value = _iconTransitionAnimation.value;
    if (value < _event2Target) {
      return CoreIcons.splashFirstState;
    } else if (value < _event3Target) {
      return CoreIcons.splashSecondState;
    } else {
      return CoreIcons.splashThirdState;
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
              animation: _iconTransitionController,
              builder: (context, child) {
                if (!_showIcon) return const SizedBox.shrink();

                return CoreIconWidget(
                  icon: _getCurrentIcon(),
                  size: _iconSize,
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
