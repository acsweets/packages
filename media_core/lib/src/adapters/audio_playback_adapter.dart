import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../bootstrap/media_core_logger.dart';
import '../cache/media_cache.dart';
import '../model/media_playback_state.dart';
import '../model/media_ref.dart';
import '../model/media_result.dart';
import './media_playback_adapter.dart';

/// Audio adapter based on [FlutterSoundPlayer].
class AudioPlaybackAdapter extends MediaPlaybackAdapter {
  AudioPlaybackAdapter({required this.variants});

  final List<MediaVariant> variants;

  FlutterSoundPlayer? _player;
  bool _isInitialized = false;
  StreamSubscription<PlaybackDisposition>? _progressSubscription;

  MediaPlaybackState _state = MediaPlaybackState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _volume = 1.0;
  double _targetVolume = 1.0;
  Timer? _volumeFadeTimer;

  static const _fadeStepDuration = Duration(milliseconds: 20);
  static const _fadeSteps = 15;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Duration get totalDuration => _totalDuration;

  @override
  double get currentVolume => _volume;

  @override
  MediaPlaybackState get playbackState => _state;

  @override
  Future<MediaResult<void>> play() async {
    try {
      if (_state == MediaPlaybackState.paused && _isInitialized) {
        return _resumeWithFadeIn();
      }

      await _initPlayer();
      final file = await _getAudioFile();
      if (file == null) {
        return MediaErr(Exception('Unable to resolve audio file'));
      }

      _volume = 0.0;
      await _player?.setVolume(_volume);
      _updateState(MediaPlaybackState.buffering);

      await _player?.startPlayer(
        fromURI: file.path,
        whenFinished: _onPlayFinished,
      );

      if (_currentPosition > Duration.zero) {
        await _player?.seekToPlayer(_currentPosition);
      }

      _listenProgress();
      _updateState(MediaPlaybackState.playing);
      _fadeVolumeTo(_targetVolume);
      return const MediaOk(null);
    } catch (e, stackTrace) {
      mediaCoreLog.e('AudioPlaybackAdapter: play failed', e, stackTrace);
      _updateState(MediaPlaybackState.error);
      return MediaErr(Exception('Audio play failed: $e'));
    }
  }

  @override
  Future<MediaResult<void>> pause() async {
    if (_state != MediaPlaybackState.playing &&
        _state != MediaPlaybackState.buffering) {
      return const MediaOk(null);
    }
    try {
      await _fadeVolumeToAndWait(0.0);
      if (_player != null && _player!.isPlaying) {
        await _player!.pausePlayer();
      }
      _updateState(MediaPlaybackState.paused);
      return const MediaOk(null);
    } catch (e, stackTrace) {
      mediaCoreLog.e('AudioPlaybackAdapter: pause failed', e, stackTrace);
      return MediaErr(Exception('Audio pause failed: $e'));
    }
  }

  @override
  Future<MediaResult<void>> stop() async {
    if (_state == MediaPlaybackState.stopped) {
      return const MediaOk(null);
    }
    try {
      if (_state == MediaPlaybackState.playing) {
        await _fadeVolumeToAndWait(0.0);
      }
      _cancelProgressSubscription();
      if (_player != null && (_player!.isPlaying || _player!.isPaused)) {
        await _player?.stopPlayer();
      }
      _currentPosition = Duration.zero;
      _updateState(MediaPlaybackState.stopped);
      return const MediaOk(null);
    } catch (e, stackTrace) {
      mediaCoreLog.e('AudioPlaybackAdapter: stop failed', e, stackTrace);
      _currentPosition = Duration.zero;
      _updateState(MediaPlaybackState.stopped);
      return MediaErr(Exception('Audio stop failed: $e'));
    }
  }

  @override
  Future<MediaResult<void>> seek(Duration position) async {
    try {
      final normalized = position < Duration.zero ? Duration.zero : position;
      final clamped =
          _totalDuration > Duration.zero && normalized > _totalDuration
          ? _totalDuration
          : normalized;

      if (_player != null && (_player!.isPlaying || _player!.isPaused)) {
        await _player!.seekToPlayer(clamped);
      }
      _currentPosition = clamped;
      onPositionChanged?.call(clamped);
      if (_state == MediaPlaybackState.stopped) {
        _updateState(MediaPlaybackState.paused);
      }
      return const MediaOk(null);
    } catch (e, stackTrace) {
      mediaCoreLog.e('AudioPlaybackAdapter: seek failed', e, stackTrace);
      return MediaErr(Exception('Audio seek failed: $e'));
    }
  }

  @override
  Future<MediaResult<void>> setVolume(double volume) async {
    _targetVolume = volume.clamp(0.0, 1.0);
    if (_state == MediaPlaybackState.playing && _volumeFadeTimer == null) {
      _volume = _targetVolume;
      try {
        await _player?.setVolume(_volume);
      } catch (e) {
        mediaCoreLog.w('AudioPlaybackAdapter: setVolume failed: $e');
      }
    }
    return const MediaOk(null);
  }

  @override
  Future<void> dispose() async {
    _cancelVolumeTimer();
    _cancelProgressSubscription();
    try {
      if (_player != null) {
        if (_player!.isPlaying || _player!.isPaused) {
          await _player!.stopPlayer();
        }
        await _player!.closePlayer();
        _player = null;
      }
    } catch (e, stackTrace) {
      mediaCoreLog.e('AudioPlaybackAdapter: dispose failed', e, stackTrace);
    }
    _isInitialized = false;
  }

  Future<void> _initPlayer() async {
    if (_isInitialized && _player != null) return;

    final player = _player ??= FlutterSoundPlayer();
    await player.closePlayer();
    await player.openPlayer();
    await player.setSubscriptionDuration(const Duration(milliseconds: 50));

    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    _isInitialized = true;
  }

  Future<File?> _getAudioFile() async {
    for (final variant in variants) {
      try {
        return await MediaCache.instance.getFile(variant.url, variant.kind);
      } catch (e) {
        mediaCoreLog.w(
          'AudioPlaybackAdapter: resolve failed url=${variant.url}: $e',
        );
      }
    }
    return null;
  }

  Future<MediaResult<void>> _resumeWithFadeIn() async {
    try {
      _volume = 0.0;
      await _player?.setVolume(_volume);
      await _player?.resumePlayer();
      _updateState(MediaPlaybackState.playing);
      _fadeVolumeTo(_targetVolume);
      return const MediaOk(null);
    } catch (e, stackTrace) {
      mediaCoreLog.e('AudioPlaybackAdapter: resume failed', e, stackTrace);
      return MediaErr(Exception('Audio resume failed: $e'));
    }
  }

  void _listenProgress() {
    _cancelProgressSubscription();
    _progressSubscription = _player?.onProgress?.listen(
      (data) {
        _currentPosition = data.position;
        _totalDuration = data.duration;
        onPositionChanged?.call(data.position);
        onDurationChanged?.call(data.duration);
      },
      onError: (Object error, StackTrace stackTrace) {
        mediaCoreLog.e(
          'AudioPlaybackAdapter: progress error',
          error,
          stackTrace,
        );
      },
    );
  }

  void _onPlayFinished() {
    _currentPosition = Duration.zero;
    _updateState(MediaPlaybackState.stopped);
    onPositionChanged?.call(Duration.zero);
  }

  void _fadeVolumeTo(double target) {
    _cancelVolumeTimer();
    final startVolume = _volume;
    final diff = target - startVolume;
    var step = 0;
    _volumeFadeTimer = Timer.periodic(_fadeStepDuration, (timer) {
      step++;
      if (step >= _fadeSteps) {
        _volume = target;
        _player?.setVolume(_volume);
        timer.cancel();
        _volumeFadeTimer = null;
        return;
      }
      _volume = startVolume + diff * (step / _fadeSteps);
      _player?.setVolume(_volume);
    });
  }

  Future<void> _fadeVolumeToAndWait(double target) async {
    final completer = Completer<void>();
    _cancelVolumeTimer();
    final startVolume = _volume;
    final diff = target - startVolume;
    var step = 0;
    _volumeFadeTimer = Timer.periodic(_fadeStepDuration, (timer) {
      step++;
      if (step >= _fadeSteps) {
        _volume = target;
        _player?.setVolume(_volume);
        timer.cancel();
        _volumeFadeTimer = null;
        if (!completer.isCompleted) completer.complete();
        return;
      }
      _volume = startVolume + diff * (step / _fadeSteps);
      _player?.setVolume(_volume);
    });
    return completer.future;
  }

  void _updateState(MediaPlaybackState state) {
    if (_state == state) return;
    _state = state;
    onPlaybackStateChanged?.call(state);
  }

  void _cancelProgressSubscription() {
    _progressSubscription?.cancel();
    _progressSubscription = null;
  }

  void _cancelVolumeTimer() {
    _volumeFadeTimer?.cancel();
    _volumeFadeTimer = null;
  }
}
