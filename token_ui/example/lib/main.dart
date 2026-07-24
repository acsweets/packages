import 'package:flutter/material.dart';
import 'package:token_ui/token_ui.dart';

import 'brand_theme_demo.dart';
import 'gallery/gallery_home.dart';

void main() {
  runApp(const TokenUiExampleApp());
}

class TokenUiExampleApp extends StatefulWidget {
  const TokenUiExampleApp({super.key});

  @override
  State<TokenUiExampleApp> createState() => _TokenUiExampleAppState();
}

class _TokenUiExampleAppState extends State<TokenUiExampleApp> {
  ThemeMode _mode = ThemeMode.dark;
  bool _useBrand = false;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(750, 1624),
      minTextAdapt: true,
      builder: (context, child) {
        return TuTheme(
          mode: _mode,
          colors: _useBrand
              ? (_mode == ThemeMode.light
                    ? BrandColors.light
                    : BrandColors.dark)
              : null,
          child: MaterialApp(
            title: 'token_ui example',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: _mode == ThemeMode.light
                  ? Brightness.light
                  : Brightness.dark,
              scaffoldBackgroundColor: (_useBrand
                      ? (_mode == ThemeMode.light
                            ? BrandColors.light
                            : BrandColors.dark)
                      : TuColors.builtIn(_mode))
                  .bg
                  .page,
              useMaterial3: true,
            ),
            home: GalleryHome(
              mode: _mode,
              useBrand: _useBrand,
              onToggleMode: () {
                setState(() {
                  _mode = _mode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                });
              },
              onToggleBrand: () {
                setState(() => _useBrand = !_useBrand);
              },
            ),
          ),
        );
      },
    );
  }
}
