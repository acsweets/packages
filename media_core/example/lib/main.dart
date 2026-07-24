import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart';

/// Sample public media URLs (no backend / ApiMedia).
const _sampleImage =
    'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg';
const _sampleVideo =
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
const _sampleAudio =
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureMediaCore(const MediaCoreConfig());
  runApp(const MediaCoreExampleApp());
}

class MediaCoreExampleApp extends StatelessWidget {
  const MediaCoreExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'media_core example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('media_core'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Image'),
              Tab(text: 'Video'),
              Tab(text: 'Audio'),
              Tab(text: 'Mutex'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ImageTab(),
            _VideoTab(),
            _AudioTab(),
            _MutexTab(),
          ],
        ),
      ),
    );
  }
}

class _ImageTab extends StatelessWidget {
  const _ImageTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('MediaView + MediaCache'),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: MediaView(ref: MediaRef.image(_sampleImage)),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            final file = await MediaCache.instance.getFile(
              _sampleImage,
              MediaKind.image,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cached: ${file.path}')),
            );
          },
          child: const Text('Download / hit cache'),
        ),
      ],
    );
  }
}

class _VideoTab extends StatelessWidget {
  const _VideoTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('MediaPlayerView (video)'),
        const SizedBox(height: 12),
        MediaPlayerView(
          media: MediaRef.video(_sampleVideo, coverUrl: _sampleImage),
        ),
      ],
    );
  }
}

class _AudioTab extends StatelessWidget {
  const _AudioTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('MediaPlayerView (audio)'),
        const SizedBox(height: 12),
        MediaPlayerView(
          media: MediaRef.audio(_sampleAudio, coverUrl: _sampleImage),
          aspectRatio: 1,
        ),
      ],
    );
  }
}

class _MutexTab extends StatelessWidget {
  const _MutexTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Two videos — only one should play at a time'),
        const SizedBox(height: 12),
        MediaPlayerView(
          media: MediaRef.video(_sampleVideo, id: 'v1'),
        ),
        const SizedBox(height: 24),
        MediaPlayerView(
          media: MediaRef.video(_sampleVideo, id: 'v2'),
        ),
      ],
    );
  }
}
