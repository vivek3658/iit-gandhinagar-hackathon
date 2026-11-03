import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Interactive 3D WebGL Sparrow Mascot rendered live via Three.js.
///
/// Communicates two-ways with Flutter:
/// - Tap to pet triggers 3D heart particles and invokes [onSparrowPetted].
/// - Tap to wake from sleep triggers [onSparrowWoken].
/// - Allows programmatic triggers: [pet], [setExpression], [dress], [wear], [preview], [levelUp], [sleep], [wake], [setNight], [setWeather].
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
  final List<String> _pendingScripts = [];

  bool get isReady => _isReady;

  void _runOrQueue(String script) {
    final controller = _controller;
    if (controller == null) return;
    if (!_isReady) {
      _pendingScripts.add(script);
      return;
    }
    controller.runJavaScript(script);
  }

  void _flushPendingScripts() {
    final controller = _controller;
    if (controller == null || !_isReady) return;
    for (final script in _pendingScripts) {
      controller.runJavaScript(script);
    }
    _pendingScripts.clear();
  }

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
          } catch (error) {
            debugPrint('[SparrowWebView] Invalid bridge message: $error');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isReady = true);
              _flushPendingScripts();
              widget.onLoaded?.call(true);
            }
          },
          onWebResourceError: (error) {
            debugPrint('[SparrowWebView] Error: ${error.description}');
          },
        ),
      )
      ..loadFlutterAsset('assets/web/sparrow.html');

    _controller = controller;
  }

  /// Triggers the 3D pet reaction (heart particles + happy chirp animation).
  void pet() {
    _runOrQueue("if (window.Sparrow) window.Sparrow.pet();");
  }

  /// Puts the sparrow into sound sleep with floating Zzz particles.
  void sleep() {
    _runOrQueue(
      "if (window.Sparrow && window.Sparrow.sleep) window.Sparrow.sleep();",
    );
  }

  /// Prevents taps from waking the sparrow during its scheduled night sleep.
  void setSleepLocked(bool locked) {
    if (!_isReady) return;
    _runOrQueue(
      'if (window.Sparrow && window.Sparrow.setSleepLocked) window.Sparrow.setSleepLocked($locked);',
    );
  }

  /// Wakes the sparrow up with a joyful chirp.
  void wake() {
    _runOrQueue(
      "if (window.Sparrow && window.Sparrow.wake) window.Sparrow.wake();",
    );
  }

  /// Toggles night scene lighting (dims ambient lights and enhances glow).
  void setNight(bool isNight) {
    if (!_isReady) return;
    _runOrQueue(
      "if (window.Sparrow && window.Sparrow.setNight) window.Sparrow.setNight($isNight);",
    );
  }

  /// Applies ambient weather particles without changing the equipped wardrobe effect.
  void setWeather(String? mood) {
    if (!_isReady) return;
    final value = mood == null ? 'null' : jsonEncode(mood);
    _runOrQueue(
      'if (window.Sparrow && window.Sparrow.setWeather) window.Sparrow.setWeather($value);',
    );
  }

  /// Keeps synthesized companion sounds in sync with the user's sound setting.
  void setSoundEnabled(bool enabled) {
    if (!_isReady) return;
    _runOrQueue(
      'if (window.Sparrow && window.Sparrow.setSoundEnabled) window.Sparrow.setSoundEnabled($enabled);',
    );
  }

  /// Sets the 3D facial expression and body posture.
  /// Options: 'happy', 'excited', 'curious', 'thinking', 'cheering', 'resting',
  ///          'planting', 'watering', 'celebrating', 'exploring', 'nest', 'angry', 'sleep'.
  void setExpression(String expression) {
    _runOrQueue("if (window.Sparrow) window.Sparrow.set('$expression');");
  }

  /// Previews an accessory on the sparrow without purchasing or saving.
  void preview(String slot, String? itemKey) {
    final slotParam = jsonEncode(slot);
    final itemParam = itemKey == null ? 'null' : jsonEncode(itemKey);
    _runOrQueue(
      'if (window.Sparrow && window.Sparrow.preview) window.Sparrow.preview($slotParam, $itemParam);',
    );
  }

  /// Previews an entire outfit set on the sparrow.
  void previewOutfit(String outfitKey) {
    _runOrQueue(
      'if (window.Sparrow && window.Sparrow.previewOutfit) window.Sparrow.previewOutfit(${jsonEncode(outfitKey)});',
    );
  }

  /// Cancels any active preview and restores worn accessories.
  void cancelPreview() {
    _runOrQueue(
      "if (window.Sparrow && window.Sparrow.cancelPreview) window.Sparrow.cancelPreview();",
    );
  }

  /// Permanently equips a specific item on a slot:
  /// slot: 'head', 'face', 'neck', 'held', 'fx'
  /// key: item identifier or null to take off.
  void wear(String slot, String? itemKey) {
    final slotParam = jsonEncode(slot);
    final itemParam = itemKey == null ? 'null' : jsonEncode(itemKey);
    _runOrQueue(
      'if (window.Sparrow && window.Sparrow.wear) window.Sparrow.wear($slotParam, $itemParam);',
    );
  }

  /// Dresses the sparrow in a predefined outfit set:
  /// 'autumn', 'winter', 'rainy', 'festive'.
  void dress(String outfitKey) {
    _runOrQueue(
      'if (window.Sparrow && window.Sparrow.dress) window.Sparrow.dress(${jsonEncode(outfitKey)});',
    );
  }

  /// Triggers a celebratory level-up burst with golden light rings.
  void levelUp(int newLevel) {
    _runOrQueue(
      "if (window.Sparrow && window.Sparrow.levelUp) window.Sparrow.levelUp($newLevel);",
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(
        child: Text(
          '🐥 3D Sparrow Sanctuary (WebGL)',
          style: TextStyle(
            color: Color(0xFF1B6B44),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(
          controller: _controller!,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(() => TapGestureRecognizer()),
          },
        ),
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
