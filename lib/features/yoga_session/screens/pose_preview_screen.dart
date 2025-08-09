import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifier/session_notifier.dart';

class PosePreviewScreen extends ConsumerWidget {
  const PosePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionNotifierProvider);
    final poses = sessionState.poses;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Select a Pose'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6D9EEB), Color(0xFFB4AEE8), Color(0xFFFED6E3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 100),
            itemCount: poses.length,
            itemBuilder: (context, index) {
              final pose = poses[index];
              return _PoseTile(
                pose: pose,
                index: index,
                textTheme: textTheme,
                onTap: () => Navigator.pop(context, index),
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              heroTag: 'start_begin',
              onPressed: poses.isEmpty ? null : () => Navigator.pop(context, 0),
              label: const Text('Start First'),
              icon: const Icon(Icons.play_circle),
            ),
            FloatingActionButton.extended(
              heroTag: 'close_preview',
              backgroundColor: Colors.black.withValues(alpha: 0.3),
              onPressed: () => Navigator.pop(context),
              label: const Text('Cancel'),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoseTile extends StatelessWidget {
  final dynamic
  pose; // Pose type but keep dynamic to avoid extra import comment noise
  final int index;
  final TextTheme textTheme;
  final VoidCallback onTap;
  const _PoseTile({
    required this.pose,
    required this.index,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.60),
                    Colors.white.withValues(alpha: 0.30),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                leading: Hero(
                  tag: 'pose_${pose.name}_img',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      pose.imagePath,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  pose.name,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.deepPurple.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Duration: ${pose.duration}s',
                  style: textTheme.labelMedium,
                ),
                trailing: const Icon(
                  Icons.play_arrow,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
