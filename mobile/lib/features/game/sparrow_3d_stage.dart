import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Interactive 3D WebGL Sparrow Mascot rendered live via Three.js.
///
/// Communicates two-ways with Flutter:
/// - Tap to pet triggers 3D heart particles and invokes [onSparrowPetted].
/// - Tap to wake from sleep triggers [onSparrowWoken].
/// - Allows programmatic triggers: [pet], [setExpression], [dress], [wear], [preview], [levelUp], [sleep], [wake], [setNight].
class Sparrow3DStage extends StatefulWidget {
  final ValueChanged<String>? onSparrowPetted;
  final VoidCallback? onSparrowWoken;
  final ValueChanged<bool>? onLoaded;

  const Sparrow3DStage({
    super.key,
    this.onSparrowPetted,
    this.onSparrowWoken,
    this.onLoaded,
  });

  @override
  State<Sparrow3DStage> createState() => Sparrow3DStageState();
}

class Sparrow3DStageState extends State<Sparrow3DStage> {
  WebViewController? _controller;
  bool _isReady = false;

  bool get isReady => _isReady;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (WebViewPlatform.instance == null) {
      // Running in headless widget test environment without webview plugin
      _isReady = true;
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            if (data['type'] == 'wake') {
              widget.onSparrowWoken?.call();
            } else if (data['type'] == 'pet') {
              final expr = data['expression'] as String? ?? 'petted';
              widget.onSparrowPetted?.call(expr);
            }
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isReady = true);
              widget.onLoaded?.call(true);
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/web/sparrow.html');

    _controller = controller;
  }

  /// Triggers the 3D pet reaction (heart particles + happy chirp animation).
  void pet() {
    _controller?.runJavaScript("if (window.Sparrow) window.Sparrow.pet();");
  }

  /// Puts the sparrow into sound sleep with floating Zzz particles.
  void sleep() {
    _controller?.runJavaScript("if (window.Sparrow && window.Sparrow.sleep) window.Sparrow.sleep();");
  }

  /// Wakes the sparrow up with a joyful chirp.
  void wake() {
    _controller?.runJavaScript("if (window.Sparrow && window.Sparrow.wake) window.Sparrow.wake();");
  }

  /// Toggles night scene lighting (dims ambient lights and enhances glow).
  void setNight(bool isNight) {
    _controller?.runJavaScript(
      "if (window.Sparrow && window.Sparrow.setNight) window.Sparrow.setNight($isNight);",
    );
  }

  /// Sets the 3D facial expression and body posture.
  /// Options: 'happy', 'excited', 'curious', 'thinking', 'cheering', 'resting',
  ///          'planting', 'watering', 'celebrating', 'exploring', 'nest', 'angry', 'sleep'.
  void setExpression(String expression) {
    _controller?.runJavaScript(
      "if (window.Sparrow) window.Sparrow.set('$expression');",
    );
  }

  /// Previews an accessory on the sparrow without purchasing or saving.
  void preview(String slot, String? itemKey) {
    final itemParam = itemKey == null ? 'null' : "'$itemKey'";
    _controller?.runJavaScript(
      "if (window.Sparrow && window.Sparrow.preview) window.Sparrow.preview('$slot', $itemParam);",
    );
  }

  /// Previews an entire outfit set on the sparrow.
  void previewOutfit(String outfitKey) {
    _controller?.runJavaScript(
      "if (window.Sparrow && window.Sparrow.previewOutfit) window.Sparrow.previewOutfit('$outfitKey');",
    );
  }

  /// Cancels any active preview and restores worn accessories.
  void cancelPreview() {
    _controller?.runJavaScript(
      "if (window.Sparrow && window.Sparrow.cancelPreview) window.Sparrow.cancelPreview();",
    );
  }

  /// Permanently equips a specific item on a slot:
  /// slot: 'head', 'face', 'neck', 'held', 'fx'
  /// key: item identifier or null to take off.
  void wear(String slot, String? itemKey) {
    final itemParam = itemKey == null ? 'null' : "'$itemKey'";
    _controller?.runJavaScript(
      "if (window.Sparrow && window.Sparrow.wear) window.Sparrow.wear('$slot', $itemParam);",
    );
  }

  /// Dresses the sparrow in a predefined outfit set:
  /// 'autumn', 'winter', 'rainy', 'festive'.
  void dress(String outfitKey) {
    _controller?.runJavaScript(
      "if (window.Sparrow && window.Sparrow.dress) window.Sparrow.dress('$outfitKey');",
    );
  }

  /// Triggers a celebratory level-up burst with golden light rings.
  void levelUp(int newLevel) {
    _controller?.runJavaScript(
      "if (window.Sparrow && window.Sparrow.levelUp) window.Sparrow.levelUp($newLevel);",
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(
        child: Text(
          '🐥 3D Sparrow Sanctuary (WebGL)',
          style: TextStyle(color: Color(0xFF1B6B44), fontWeight: FontWeight.bold),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller!),
        if (!_isReady)
          const Center(
            child: SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B6B44)),
              ),
            ),
          ),
      ],
    );
  }
}
