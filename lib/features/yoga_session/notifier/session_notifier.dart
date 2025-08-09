import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../data/models/pose.dart';
import '../../../data/repositories/yoga_repository.dart';

enum SessionStatus { initial, loading, running, paused, finished }

class SessionState {
  final List<Pose> poses;
  final int currentPoseIndex;
  final SessionStatus status;
  final int streakCount;
  final double progress;
  final bool backgroundMusicEnabled;
  final DateTime? poseStartTime;
  final Duration? remainingDuration;
  final double poseVolume; // 0.0 - 1.0
  final double backgroundVolume; // 0.0 - 1.0

  SessionState({
    this.poses = const [],
    this.currentPoseIndex = 0,
    this.status = SessionStatus.initial,
    this.streakCount = 0,
    this.progress = 0.0,
    this.backgroundMusicEnabled = true,
    this.poseStartTime,
    this.remainingDuration,
    this.poseVolume = 1.0,
    this.backgroundVolume = 0.3,
  });

  SessionState copyWith({
    List<Pose>? poses,
    int? currentPoseIndex,
    SessionStatus? status,
    int? streakCount,
    double? progress,
    bool? backgroundMusicEnabled,
    DateTime? poseStartTime,
    Duration? remainingDuration,
    double? poseVolume,
    double? backgroundVolume,
  }) {
    return SessionState(
      poses: poses ?? this.poses,
      currentPoseIndex: currentPoseIndex ?? this.currentPoseIndex,
      status: status ?? this.status,
      streakCount: streakCount ?? this.streakCount,
      progress: progress ?? this.progress,
      backgroundMusicEnabled:
          backgroundMusicEnabled ?? this.backgroundMusicEnabled,
      poseStartTime: poseStartTime ?? this.poseStartTime,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      poseVolume: poseVolume ?? this.poseVolume,
      backgroundVolume: backgroundVolume ?? this.backgroundVolume,
    );
  }

  double get sessionProgress {
    if (poses.isEmpty) return 0.0;
    return (currentPoseIndex + 1) / poses.length;
  }

  double get currentPoseProgress {
    if (poseStartTime == null || currentPoseIndex >= poses.length) return 0.0;

    final currentPose = poses[currentPoseIndex];
    final elapsed = DateTime.now().difference(poseStartTime!);
    final total = Duration(seconds: currentPose.duration);

    return (elapsed.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final YogaRepository _yogaRepository;
  Timer? _timer;
  Timer? _progressTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Separate audio player for looping background music
  final AudioPlayer _backgroundPlayer = AudioPlayer();
  bool _isDisposed = false;

  SessionNotifier(this._yogaRepository) : super(SessionState()) {
    _loadPoses();
  }

  Future<void> _loadPoses() async {
    if (_isDisposed) return;

    state = state.copyWith(status: SessionStatus.loading);

    try {
      final poses = await _yogaRepository.getPoses();
      if (!_isDisposed) {
        state = state.copyWith(
          poses: poses,
          status: SessionStatus.initial,
          progress: 0.0,
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(status: SessionStatus.initial, progress: 0.0);
      }
    }
  }

  void startSession({int startIndex = 0}) {
    if (state.poses.isEmpty ||
        state.status == SessionStatus.running ||
        _isDisposed) {
      return;
    }

    if (startIndex < 0 || startIndex >= state.poses.length) {
      startIndex = 0; // fallback safety
    }

    state = state.copyWith(
      currentPoseIndex: startIndex,
      status: SessionStatus.running,
      poseStartTime: DateTime.now(),
      progress: 0.0,
    );

    _playCurrentPose();
    _startProgressTimer();
    _startBackgroundMusicIfNeeded();
  }

  // Convenience wrapper for clarity when starting at a specific pose
  void startSessionAt(int index) => startSession(startIndex: index);

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isDisposed) {
        // Update progress without creating new state unless necessary
        final newProgress = state.currentPoseProgress;
        if ((newProgress - state.progress).abs() > 0.01) {
          state = state.copyWith(progress: newProgress);
        }
      }
    });
  }

  Future<void> _playCurrentPose() async {
    if (_isDisposed) return;

    _timer?.cancel();

    if (state.currentPoseIndex >= state.poses.length) {
      finishSession();
      return;
    }

    final currentPose = state.poses[state.currentPoseIndex];

    try {
      await _audioPlayer.setAsset(currentPose.audioPath);
      await _audioPlayer.setVolume(state.poseVolume);
      if (!_isDisposed && state.status == SessionStatus.running) {
        await _audioPlayer.play();
      }
    } catch (e) {
      // Log error but continue session
      // ignore: avoid_print
      print("Error loading audio: $e");
    }

    // Set timer for pose duration
    _timer = Timer(Duration(seconds: currentPose.duration), () {
      if (!_isDisposed) {
        _nextPose();
      }
    });
  }

  void _nextPose() {
    if (_isDisposed) return;

    if (state.currentPoseIndex < state.poses.length - 1) {
      state = state.copyWith(
        currentPoseIndex: state.currentPoseIndex + 1,
        poseStartTime: DateTime.now(),
      );
      _playCurrentPose();
    } else {
      finishSession();
    }
  }

  void nextPose() {
    if (_isDisposed) return;

    _timer?.cancel();
    _nextPose();
  }

  void pauseSession() {
    if (state.status != SessionStatus.running || _isDisposed) return;

    _timer?.cancel();
    _progressTimer?.cancel();
    _audioPlayer.pause();
    // Pause (not stop) background music so we can resume seamlessly
    if (state.backgroundMusicEnabled) {
      _backgroundPlayer.pause();
    }

    // Calculate remaining time for current pose
    final elapsed = state.poseStartTime != null
        ? DateTime.now().difference(state.poseStartTime!)
        : Duration.zero;
    final currentPose = state.poses[state.currentPoseIndex];
    final remaining = Duration(seconds: currentPose.duration) - elapsed;

    state = state.copyWith(
      status: SessionStatus.paused,
      remainingDuration: remaining.isNegative ? Duration.zero : remaining,
    );
  }

  void resumeSession() {
    if (state.status != SessionStatus.paused || _isDisposed) return;

    state = state.copyWith(
      status: SessionStatus.running,
      poseStartTime: DateTime.now(),
    );

    _audioPlayer.play();
    if (state.backgroundMusicEnabled) {
      _backgroundPlayer.play();
    }
    _startProgressTimer();

    // Resume timer with remaining duration
    final remainingDuration =
        state.remainingDuration ??
        Duration(seconds: state.poses[state.currentPoseIndex].duration);

    _timer = Timer(remainingDuration, () {
      if (!_isDisposed) {
        _nextPose();
      }
    });
  }

  void toggleBackgroundMusic(bool enabled) {
    if (_isDisposed) return;

    state = state.copyWith(backgroundMusicEnabled: enabled);
    if (enabled) {
      _startBackgroundMusicIfNeeded(fadeIn: true);
    } else {
      _fadeVolume(
        _backgroundPlayer,
        _backgroundPlayer.volume,
        0.0,
        duration: const Duration(milliseconds: 400),
      ).then((_) {
        if (!_isDisposed) _backgroundPlayer.stop();
      });
    }
  }

  Future<void> _startBackgroundMusicIfNeeded({bool fadeIn = false}) async {
    if (_isDisposed) return;
    if (!state.backgroundMusicEnabled) return;
    // Only start/ensure playing during an active (running) session
    if (state.status != SessionStatus.running) return;
    try {
      // If nothing loaded yet, set the asset. (Provide your own ambient track.)
      if (_backgroundPlayer.audioSource == null) {
        const bgPath = 'assets/audio/background_music.mp3';
        try {
          await _backgroundPlayer.setAsset(bgPath);
        } catch (_) {
          // fallback to first pose audio if custom bg missing
          if (state.poses.isNotEmpty) {
            await _backgroundPlayer.setAsset(state.poses.first.audioPath);
          } else {
            return; // nothing to play
          }
        }
        await _backgroundPlayer.setLoopMode(LoopMode.all);
        await _backgroundPlayer.setVolume(
          fadeIn ? 0.0 : state.backgroundVolume,
        ); // start silent if fade
      }
      if (!_backgroundPlayer.playing) {
        await _backgroundPlayer.play();
      }
      if (fadeIn) {
        _fadeVolume(
          _backgroundPlayer,
          0.0,
          state.backgroundVolume,
          duration: const Duration(milliseconds: 700),
        );
      } else if (_backgroundPlayer.volume != state.backgroundVolume) {
        await _backgroundPlayer.setVolume(state.backgroundVolume);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Background music error: $e');
    }
  }

  void finishSession() {
    if (_isDisposed) return;

    _timer?.cancel();
    _progressTimer?.cancel();
    _audioPlayer.stop();
    _backgroundPlayer.stop();

    state = state.copyWith(
      status: SessionStatus.finished,
      progress: 1.0,
      streakCount: state.streakCount + 1,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _progressTimer?.cancel();
    _audioPlayer.dispose();
    _backgroundPlayer.dispose();
    super.dispose();
  }

  // Lifecycle hook from app wrapper to control audio when app is backgrounded.
  void handleLifecycle(AppLifecycleState lifecycle) {
    if (_isDisposed) return;
    switch (lifecycle) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // Pause both players (background music should not continue while app not visible)
        if (_audioPlayer.playing) {
          _audioPlayer.pause();
        }
        if (_backgroundPlayer.playing) {
          _backgroundPlayer.pause();
        }
        break;
      case AppLifecycleState.resumed:
        // Resume only if session is running; background music only if enabled
        if (state.status == SessionStatus.running) {
          _audioPlayer.play();
          if (state.backgroundMusicEnabled) {
            _startBackgroundMusicIfNeeded(fadeIn: true);
          }
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Stop everything (cleanup scenario)
        _audioPlayer.stop();
        _backgroundPlayer.stop();
        break;
    }
  }

  // Public setters for volumes
  void setPoseVolume(double value) {
    final v = value.clamp(0.0, 1.0);
    state = state.copyWith(poseVolume: v);
    _audioPlayer.setVolume(v);
  }

  void setBackgroundVolume(double value) {
    final v = value.clamp(0.0, 1.0);
    state = state.copyWith(backgroundVolume: v);
    if (state.backgroundMusicEnabled) {
      _backgroundPlayer.setVolume(v);
    }
  }

  Future<void> _fadeVolume(
    AudioPlayer player,
    double from,
    double to, {
    Duration duration = const Duration(milliseconds: 600),
    int steps = 10,
  }) async {
    if (steps <= 0) return;
    final stepDur = duration ~/ steps;
    final delta = (to - from) / steps;
    double current = from;
    for (var i = 0; i < steps; i++) {
      if (_isDisposed) return;
      current += delta;
      player.setVolume(current.clamp(0.0, 1.0));
      await Future.delayed(stepDur);
    }
    if (!_isDisposed) player.setVolume(to.clamp(0.0, 1.0));
  }
}

// The provider remains the same
final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
      final yogaRepository = ref.watch(yogaRepositoryProvider);
      return SessionNotifier(yogaRepository);
    });
