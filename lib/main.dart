import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'screens/home_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const PDFReaderApp());
}

class PDFReaderApp extends StatefulWidget {
  const PDFReaderApp({super.key});

  @override
  State<PDFReaderApp> createState() => _PDFReaderAppState();
}

class _PDFReaderAppState extends State<PDFReaderApp> {
  late StreamSubscription _intentDataStreamSubscription;
  String? _sharedText;

  @override
  void initState() {
    super.initState();
    // For sharing or opening pdf when app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (value) {
            if (value.isNotEmpty && value.first.path.endsWith('.pdf')) {
              setState(() {
                _sharedText = value.first.path;
              });
            }
          },
          onError: (err) {
            print("getIntentDataStream error: $err");
          },
        );

    // For sharing or opening pdf when app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty && value.first.path.endsWith('.pdf')) {
        setState(() {
          _sharedText = value.first.path;
        });
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KTP PDF Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.system,
      home: _sharedText != null
          ? PDFViewerScreen(
              filePath: _sharedText!,
              fileName: p.basename(_sharedText!),
            )
          : const HomeScreen(),
    );
  }
}
