import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../core/config/app_routes.dart';

class LandingHome extends StatefulWidget {
  const LandingHome({super.key});

  @override
  State<LandingHome> createState() => _LandingHomeState();
}

class _LandingHomeState extends State<LandingHome> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('lib/assets/videos/bannerlogo.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHero(),
        _buildGetStarted(context),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      decoration: const BoxDecoration(
        color: AppColors.primary, // Replace 'primary' with an existing color getter from AppColors
      ),
      child: Column(
        children: [
          if (_controller.value.isInitialized)
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              constraints: const BoxConstraints(maxWidth: 800),
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Text(
                  'Time2Bill helpt je bij het eenvoudig registreren van werktijden en het genereren van facturen.',
                  style: AppTextStyles.heading2.copyWith(color: AppColors.text),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStarted(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      color: AppColors.surface,
      child: Center(
        child: PrimaryButton(
          text: 'Start nu gratis',
          onPressed: () => Navigator.pushNamed(context, AppRouter.register),
          isFullWidth: false,
        ),
      ),
    );
  }
}

