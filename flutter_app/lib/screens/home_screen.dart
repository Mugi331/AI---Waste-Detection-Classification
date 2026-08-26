import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';
import 'scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 64,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- WE Snap logo -----------------------------------
                    Image.asset(
                      'assets/branding/we_snap_logo.png',
                      width: 185,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.recycling_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'WE Snap',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.brownPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Waste Detection & Recycling AI Assistant :3',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.brownSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Snap or upload a photo to identify recyclable materials.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.brownSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 26),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _MaterialChip(label: 'Plastic', color: Color.fromARGB(255, 255, 220, 195)),
                        _MaterialChip(label: 'Metal', color: Color.fromARGB(255, 207, 229, 244)),
                        _MaterialChip(label: 'Paper / Cardboard', color: Color.fromARGB(255, 213, 208, 255)),
                        _MaterialChip(label: 'Glass', color: Color.fromARGB(255, 205, 240, 193)),
                      ],
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await AppAudioService.instance.playClick();

                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScanScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Scan Waste'),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'University coursework prototype · AI results may be imperfect.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.brownSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Soft pastel pill chip used to list a supported material class.
/// Decorative only — see the colour-concept note in app_theme.dart.
class _MaterialChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MaterialChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.brownPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
