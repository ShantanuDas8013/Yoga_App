import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifier/session_notifier.dart';
import 'pose_preview_screen.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionNotifierProvider);
    final textTheme = Theme.of(context).textTheme;
    final currentPose = sessionState.poses.isEmpty
        ? null
        : sessionState.poses[sessionState.currentPoseIndex];

    final int streakCount = sessionState.streakCount;
    final double sessionProgress = sessionState.sessionProgress;
    final double poseProgress = sessionState.currentPoseProgress;
    final bool backgroundMusicEnabled = sessionState.backgroundMusicEnabled;

    // Modern gradient background
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Yoga Flow'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedContainer(
        duration: const Duration(seconds: 6),
        curve: Curves.easeInOut,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6D9EEB), Color(0xFFB4AEE8), Color(0xFFFED6E3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: switch (sessionState.status) {
                SessionStatus.loading => const CircularProgressIndicator(),

                SessionStatus.finished => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Text(
                              'Session Complete! 🎉',
                              style: textTheme.headlineMedium?.copyWith(
                                color: Colors.deepPurple.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => ref
                                  .read(sessionNotifierProvider.notifier)
                                  .startSession(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Restart Flow'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Streaks display
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.deepPurple.shade50,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.deepOrange,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text('Streak: ', style: textTheme.titleMedium),
                            Text(
                              '$streakCount days',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                _ when currentPose != null => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Streaks display
                    Align(
                      alignment: Alignment.topRight,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.deepPurple.shade50,
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.deepOrange,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text('Streak: ', style: textTheme.labelLarge),
                              Text(
                                '$streakCount',
                                style: textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          children: [
                            Text(
                              currentPose.name,
                              style: textTheme.headlineMedium?.copyWith(
                                color: Colors.deepPurple.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                currentPose.imagePath,
                                fit: BoxFit.contain,
                                height: 240,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 240,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Duration: ${currentPose.duration} seconds',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 20),
                            // Progress bar - show current pose progress
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pose Progress',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: Colors.deepPurple.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _AnimatedLinearProgress(
                                  value: poseProgress,
                                  background: Colors.deepPurple.shade100,
                                  foreground: Colors.deepPurple,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Session Progress',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: Colors.deepPurple.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _AnimatedLinearProgress(
                                  value: sessionProgress,
                                  background: Colors.orange.shade100,
                                  foreground: Colors.orange,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pose ${sessionState.currentPoseIndex + 1} of ${sessionState.poses.length}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Play/Pause controls
                            _ControlBar(
                              isPaused:
                                  sessionState.status == SessionStatus.paused,
                              onPlayPause: () {
                                if (sessionState.status ==
                                    SessionStatus.running) {
                                  ref
                                      .read(sessionNotifierProvider.notifier)
                                      .pauseSession();
                                } else if (sessionState.status ==
                                    SessionStatus.paused) {
                                  ref
                                      .read(sessionNotifierProvider.notifier)
                                      .resumeSession();
                                }
                              },
                              onNext: () => ref
                                  .read(sessionNotifierProvider.notifier)
                                  .nextPose(),
                            ),
                            const SizedBox(height: 10),
                            // Background music controls (placeholder)
                            _MusicToggle(
                              enabled: backgroundMusicEnabled,
                              onChanged: (val) => ref
                                  .read(sessionNotifierProvider.notifier)
                                  .toggleBackgroundMusic(val),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                _ => const Text(
                  'No yoga poses found. Please check your assets.',
                ),
              },
            ),
          ),
        ),
      ),
      floatingActionButton: sessionState.status == SessionStatus.initial
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PosePreviewScreen(),
                  ),
                );
                if (result is int) {
                  ref
                      .read(sessionNotifierProvider.notifier)
                      .startSession(startIndex: result);
                } else if (result == true) {
                  // Fallback support if older boolean logic somehow used
                  ref.read(sessionNotifierProvider.notifier).startSession();
                }
              },
              label: const Text('Preview & Start'),
              icon: const Icon(Icons.visibility),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// --- Helper UI Widgets ---

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.65),
                Colors.white.withValues(alpha: 0.35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AnimatedLinearProgress extends StatelessWidget {
  final double value;
  final Color background;
  final Color foreground;
  const _AnimatedLinearProgress({
    required this.value,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, val, _) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: val,
          minHeight: 8,
          backgroundColor: background,
          color: foreground,
        ),
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  const _ControlBar({
    required this.isPaused,
    required this.onPlayPause,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: onPlayPause,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(18),
          ),
          child: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 28),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(18),
          ),
          child: const Icon(Icons.skip_next, size: 26),
        ),
      ],
    );
  }
}

class _MusicToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _MusicToggle({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text('Background music', style: textTheme.labelLarge),
          const SizedBox(width: 8),
          Switch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}
