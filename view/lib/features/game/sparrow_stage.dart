import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SparrowStage extends StatefulWidget {
  const SparrowStage({
    this.onPet,
    this.expression = 'happy',
    this.isActive = true,
    this.backgroundColor = const Color(0xFFE7F2DF),
    this.borderRadius = 24,
    super.key,
  });

  final Future<void> Function()? onPet;
  final String expression;
  final bool isActive;
  final Color backgroundColor;
  final double borderRadius;

  @override
  State<SparrowStage> createState() => SparrowStageState();
}

class SparrowStageState extends State<SparrowStage> {
  WebViewController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _initializeWebView();
  }

  void _initializeWebView() {
    _ready = false;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (message) {
          try {
            final value = jsonDecode(message.message);
            if (value is Map && value['type'] == 'pet') {
              widget.onPet?.call();
            }
          } on FormatException {
            return;
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _ready = true);
            setExpression(widget.expression);
          },
          onWebResourceError: (error) {
            debugPrint('Sparrow model failed to load: ${error.description}');
          },
        ),
      )
      ..loadFlutterAsset('assets/web/sparrow.html');
  }

  @override
  void didUpdateWidget(covariant SparrowStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _initializeWebView();
      } else {
        _controller = null;
        _ready = false;
      }
    } else if (oldWidget.expression != widget.expression) {
      setExpression(widget.expression);
    }
  }

  void setExpression(String expression) {
    final controller = _controller;
    if (!_ready || controller == null) return;
    final safeExpression = jsonEncode(expression);
    controller.runJavaScript(
      'if(window.Sparrow) window.Sparrow.set($safeExpression);',
    );
  }

  void setNight(bool value) {
    final controller = _controller;
    if (!_ready || controller == null) return;
    controller.runJavaScript(
      'if(window.Sparrow) window.Sparrow.setNight($value);',
    );
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(widget.borderRadius),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: widget.backgroundColor),
        if (_controller case final controller?)
          WebViewWidget(controller: controller),
        if (_controller != null && !_ready)
          const Center(
            child: SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
      ],
    ),
  );
}
