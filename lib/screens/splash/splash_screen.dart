import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/app_logo.dart';
import '../../providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  late final Animation<double> _hold;

  bool _initComplete = false;
  String? _targetRoute;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic));
    _scale = CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic));
    _hold = CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.linear));
    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _maybeNavigate();
      })
      ..forward();
    _initialize();
  }

  Future<void> _initialize() async {
    final repo = ref.read(balanceRepoProvider);
    final hasData = await repo.hasAnyOpeningBalance();
    if (!mounted) return;

    if (hasData) {
      await repo.ensureTodayOpeningBalance();
      if (mounted) _targetRoute = '/dashboard';
    } else {
      if (mounted) _targetRoute = '/first-time';
    }
    _initComplete = true;
    _maybeNavigate();
  }

  void _maybeNavigate() {
    if (_initComplete && _targetRoute != null && _controller.status == AnimationStatus.completed) {
      if (mounted) context.go(_targetRoute!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final fadeValue = _fadeIn.value;
            final scaleValue = _scale.value;
            return Opacity(
              opacity: fadeValue,
              child: Transform.scale(
                scale: scaleValue,
                child: const AppLogo(size: 120),
              ),
            );
          },
        ),
      ),
    );
  }
}