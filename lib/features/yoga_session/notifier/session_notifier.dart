import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart'; // Import the audio player
import '../../../data/models/pose.dart';
import '../../../data/repositories/yoga_repository.dart';

// The enum and State class remain the same
enum SessionStatus { initial, loading, running, paused, finished }

class SessionState {
  final List<Pose> poses;
  final int currentPoseIndex;
  final SessionStatus status;

  SessionState({
    this.poses = const [],
    this.currentPoseIndex = 0,
    this.status = SessionStatus.initial,
  });

  SessionState copyWith({
    List<Pose>? poses,
    int? currentPoseIndex,
    SessionStatus? status,
  }) {
    return SessionState(
      poses: poses ?? this.poses,
      currentPoseIndex: currentPoseIndex ?? this.currentPoseIndex,
      status: status ?? this.status,
    );
  }
}

// The Notifier class is updated with new logic
class SessionNotifier extends StateNotifier<SessionState> {
  final YogaRepository _yogaRepository;
  Timer? _timer;
  final AudioPlayer _audioPlayer =
      AudioPlayer(); // Create an audio player instance

  SessionNotifier(this._yogaRepository) : super(SessionState()) {
    _loadPoses();
  }

  Future<void> _loadPoses() async {
    state = state.copyWith(status: SessionStatus.loading);
    try {
      final poses = await _yogaRepository.getPoses();
      state = state.copyWith(poses: poses, status: SessionStatus.initial);
    } catch (e) {
      state = state.copyWith(status: SessionStatus.initial);
    }
  }

  // NEW: Method to start the session
  void startSession() {
    if (state.poses.isEmpty || state.status == SessionStatus.running) return;

    state = state.copyWith(currentPoseIndex: 0, status: SessionStatus.running);
    _playCurrentPose();
  }

  // NEW: Private helper to play audio and start the timer for the current pose
  void _playCurrentPose() async {
    _timer?.cancel(); // Cancel any previous timer

    if (state.currentPoseIndex >= state.poses.length) {
      finishSession();
      return;
    }

    final currentPose = state.poses[state.currentPoseIndex];

    // Play the corresponding audio [cite: 25]
    try {
      await _audioPlayer.setAsset(currentPose.audioPath);
      _audioPlayer.play();
    } catch (e) {
      print("Error loading audio: $e");
    }

    // Move to the next pose after the given duration [cite: 26]
    _timer = Timer(Duration(seconds: currentPose.duration), _nextPose);
  }

  // NEW: Private helper to advance to the next pose
  void _nextPose() {
    if (state.currentPoseIndex < state.poses.length - 1) {
      state = state.copyWith(currentPoseIndex: state.currentPoseIndex + 1);
      _playCurrentPose();
    } else {
      finishSession();
    }
  }

  // NEW: Method to end the session
  void finishSession() {
    _timer?.cancel();
    _audioPlayer.stop();
    state = state.copyWith(status: SessionStatus.finished);
  }

  // Update dispose method to include the audio player
  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose(); // Dispose of the audio player to free resources
    super.dispose();
  }
}

// The provider remains the same
final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
      final yogaRepository = ref.watch(yogaRepositoryProvider);
      return SessionNotifier(yogaRepository);
    });
