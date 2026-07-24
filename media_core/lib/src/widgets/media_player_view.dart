import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../model/media_kind.dart';
import '../model/media_playback_state.dart';
import '../model/media_ref.dart';
import '../player/media_player_controller.dart';
import '../player/media_session.dart';
import './media_view.dart';

/// Minimal player shell: bind [MediaRef], play/pause, optional video surface.
///
/// No GetX — uses [ValueListenableBuilder].
class MediaPlayerView extends StatefulWidget {
  const MediaPlayerView({
    super.key,
    required this.media,
    this.controller,
    this.autoPlay = false,
    this.showControls = true,
    this.aspectRatio,
  });

  final MediaRef media;
  final MediaPlayerController? controller;
  final bool autoPlay;
  final bool showControls;
  final double? aspectRatio;

  @override
  State<MediaPlayerView> createState() => _MediaPlayerViewState();
}

class _MediaPlayerViewState extends State<MediaPlayerView> {
  late final MediaPlayerController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? MediaPlayerController();
    _controller.bind(widget.media);
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.play();
      });
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    } else {
      _controller.unbind();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio ?? 16 / 9,
          child: _buildSurface(),
        ),
        if (widget.showControls) _buildControls(),
      ],
    );

    return MediaVisibilityScope(
      controllerKey: ValueKey('media_vis_${widget.media.url}'),
      onVisibilityChanged: (visible) {
        MediaSession.instance.onVisibilityChanged(
          _controller,
          visible: visible,
        );
      },
      child: body,
    );
  }

  Widget _buildSurface() {
    final kind = widget.media.kind;
    if (kind == MediaKind.image ||
        kind == MediaKind.coverImage ||
        kind == MediaKind.previewImage) {
      return MediaView(ref: widget.media);
    }

    return ValueListenableBuilder<MediaPlaybackState>(
      valueListenable: _controller.playbackState,
      builder: (context, state, _) {
        final video = _controller.videoAdapter?.videoPlayerController;
        if (video != null && video.value.isInitialized) {
          return FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: video.value.size.width,
              height: video.value.size.height,
              child: VideoPlayer(video),
            ),
          );
        }

        if (widget.media.coverUrl != null) {
          return MediaView(
            ref: MediaRef.image(widget.media.coverUrl!),
          );
        }

        if (state == MediaPlaybackState.buffering) {
          return const Center(child: CircularProgressIndicator());
        }
        return const ColoredBox(color: Color(0xFF111111));
      },
    );
  }

  Widget _buildControls() {
    return ValueListenableBuilder<MediaPlaybackState>(
      valueListenable: _controller.playbackState,
      builder: (context, state, _) {
        final playing = state == MediaPlaybackState.playing ||
            state == MediaPlaybackState.buffering;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                if (playing) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => _controller.stop(),
            ),
            ValueListenableBuilder<Duration>(
              valueListenable: _controller.position,
              builder: (context, pos, _) {
                return ValueListenableBuilder<Duration>(
                  valueListenable: _controller.duration,
                  builder: (context, dur, _) {
                    return Text(
                      '${_fmt(pos)} / ${_fmt(dur)}',
                      style: const TextStyle(fontSize: 12),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
