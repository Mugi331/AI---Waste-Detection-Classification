import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'scan_screen.dart';

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

  void _startApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanScreen(),
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

                  const Text(
                    'WE Snap',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5B3A29),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 8),


                  // -------------------------------------------------
                  // Tagline
                  // -------------------------------------------------

                  const Text(
                    'Snap it. Sort it. Recycle it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7D654E),
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
                            const Color(0xFFA9C889),

                        foregroundColor:
                            const Color(0xFF49352A),

                        elevation: 2,

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(28),
                        ),
                      ),

                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.camera_alt_rounded,
                            size: 20,
                          ),

                          SizedBox(width: 8),

                          Text(
                            'Start Snapping',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}