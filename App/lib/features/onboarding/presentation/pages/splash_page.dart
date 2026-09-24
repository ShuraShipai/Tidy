import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/tidy_motion.dart';
import '../../../../core/widgets/tidy_page_background.dart';

import '../../widgets/splash_identity.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(TidyMotion.splashDuration, () {
      if (mounted) context.go('/onboarding/welcome');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: TidyPageBackground(child: SafeArea(child: SplashIdentity())),
  );
}
