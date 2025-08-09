import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifier/session_notifier.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the SessionNotifierProvider to get the current state
    final sessionState = ref.watch(sessionNotifierProvider);
    final textTheme = Theme.of(context).textTheme;

    // Get the current pose, if available
    final currentPose = sessionState.poses.isEmpty
        ? null
        : sessionState.poses[sessionState.currentPoseIndex];

    // ... inside the build method of SessionScreen

    return Scaffold(
      appBar: AppBar(title: const Text('Yoga Session'), centerTitle: true),
      body: Center(
        child: switch (sessionState.status) {
          SessionStatus.loading => const CircularProgressIndicator(),

          // Display a "Finished" message
          SessionStatus.finished => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Session Complete!', style: textTheme.headlineMedium),
              const SizedBox(height: 20),
              ElevatedButton(
                // Use .read on the notifier to call methods
                onPressed: () =>
                    ref.read(sessionNotifierProvider.notifier).startSession(),
                child: const Text('Start Again'),
              ),
            ],
          ),

          // Show the main content for initial and running states
          _ when currentPose != null => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(currentPose.name, style: textTheme.headlineMedium),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    currentPose.imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Duration: ${currentPose.duration} seconds',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 50),
            ],
          ),
          _ => const Text('No yoga poses found. Please check your assets.'),
        },
      ),
      // NEW: Add a FloatingActionButton to start the session
      floatingActionButton: sessionState.status == SessionStatus.initial
          ? FloatingActionButton.extended(
              onPressed: () {
                // Use ref.read(...).notifier to call methods on your SessionNotifier
                ref.read(sessionNotifierProvider.notifier).startSession();
              },
              label: const Text('Start Session'),
              icon: const Icon(Icons.play_arrow),
            )
          : null, // Hide button when session is not in the initial state
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
