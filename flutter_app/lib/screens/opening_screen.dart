import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/audio_service.dart';

import 'home_screen.dart';

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen> {
  late final VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset(
      'assets/videos/we_snap_intro.mp4',
    )
      ..initialize().then((_) {
        if (!mounted) return;

        // Keep the intro looping.
        _videoController.setLooping(true);

        // Muted autoplay is much more reliable on web/mobile browsers.
        _videoController.setVolume(0);

        _videoController.play();

        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _startApp() async {
    // The first user gesture is the safest point to start BGM on web/mobile.
    await AppAudioService.instance.playClick();
    await AppAudioService.instance.startBgm();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),

      body: Stack(
        fit: StackFit.expand,
        children: [

          // =========================================================
          // 1. FULL-SCREEN INTRO VIDEO
          // =========================================================

          if (_videoController.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(
                  _videoController,
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(),
            ),


          // =========================================================
          // 2. SOFT OVERLAY
          // Makes text/button easier to read over the animation.
          // =========================================================

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00FFF9ED),
                  Color(0x22FFF9ED),
                  Color(0xDDFFF9ED),
                ],
              ),
            ),
          ),


          // =========================================================
          // 3. FOREGROUND CONTENT
          // =========================================================

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 24,
              ),

              child: Column(
                children: [

                  const Spacer(),

                  // -------------------------------------------------
                  // App name
                  // -------------------------------------------------

                  Text(
                    'WE Snap',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 50,
                          fontWeight: FontWeight.w800,
                          color: const Color.fromARGB(255, 59, 46, 40),
                          letterSpacing: 0.5,
                        ),
                  ),

                  const SizedBox(height: 8),


                  // -------------------------------------------------
                  // Tagline
                  // -------------------------------------------------

                  const Text(
                    'Snap it · Sort it · Recycle it',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 102, 81, 62),
                    ),
                  ),

                  const SizedBox(height: 24),


                  // -------------------------------------------------
                  // Start button
                  // -------------------------------------------------

                  SizedBox(
                    width: 190,
                    height: 54,

                    child: FilledButton(
                      onPressed: _startApp,

                      style: FilledButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 255, 244, 184),

                        foregroundColor:
                            const Color.fromARGB(255, 65, 53, 48),

                        elevation: 2,

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(60),
                        ),
                      ),

                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.eco_rounded,
                            size: 30,
                          ),
                          SizedBox(width: 8),

                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}