import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Interactive 3D WebGL Floating Garden Island rendered live via Three.js.
///
/// Features:
/// - 3x3 Floating Eco Island with centerpiece Sparrow Home.
/// - Full touch orbit rotation and double-finger pinch-to-zoom.
/// - Dynamic Build Mode: tap empty slots to open catalog and place objects.
/// - Raycasting tile detection invoking [onTileTapped] or [onEmptyTileTapped].
/// - Programmatic controls: [setBuildMode], [previewPlacement], [confirmPlacement],
///   [cancelPreview], [rotateTile], [removeTile], [moveTile], [rotate90], [toggleSpin], [resetView].
class Garden3DStage extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onTileTapped;
  final void Function(int x, int z)? onEmptyTileTapped;
  final ValueChanged<List<dynamic>>? onIslandUpdated;
  final ValueChanged<bool>? onLoaded;

  const Garden3DStage({
    super.key,
    this.onTileTapped,
    this.onEmptyTileTapped,
    this.onIslandUpdated,
    this.onLoaded,
  });

  @override
  State<Garden3DStage> createState() => Garden3DStageState();
}

class Garden3DStageState extends State<Garden3DStage> {
  WebViewController? _controller;
  bool _isReady = false;
  bool _isAutoSpinning = false;

  bool get isReady => _isReady;
  bool get isAutoSpinning => _isAutoSpinning;

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
            final type = data['type'] as String?;
            if (type == 'selectTile' || type == 'tileTap') {
              widget.onTileTapped?.call(data);
            } else if (type == 'selectEmptyTile') {
              final x = data['x'] as int? ?? 0;
              final z = data['z'] as int? ?? 0;
              widget.onEmptyTileTapped?.call(x, z);
            } else if (type == 'islandUpdated') {
              final slots = data['slots'] as List<dynamic>? ?? [];
              widget.onIslandUpdated?.call(slots);
            } else if (type == 'spin') {
              setState(() {
                _isAutoSpinning = data['spin'] as bool? ?? false;
              });
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
      ..loadFlutterAsset('assets/web/garden.html');

    _controller = controller;
  }

  /// Toggles build mode visual state in the 3D scene.
  void setBuildMode(bool isBuildMode) {
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.setBuildMode) window.Garden.setBuildMode($isBuildMode);",
    );
  }

  /// Displays a temporary placement preview on a specific grid plot.
  void previewPlacement(int x, int z, String tileId, int rotation) {
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.previewPlacement) window.Garden.previewPlacement($x, $z, '$tileId', $rotation);",
    );
  }

  /// Cancels any active tile placement preview.
  void cancelPreview() {
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.cancelPreview) window.Garden.cancelPreview();",
    );
  }

  /// Permanently confirms placement of an item on the grid plot.
  void confirmPlacement(int x, int z, String tileId, int rotation) {
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.confirmPlacement) window.Garden.confirmPlacement($x, $z, '$tileId', $rotation);",
    );
  }

  /// Rotates the object on the given tile by 90 degrees.
  void rotateTile(int x, int z) {
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.rotateTile) window.Garden.rotateTile($x, $z);",
    );
  }

  /// Removes an object from the grid plot (cannot remove SPARROW_HOME).
  void removeTile(int x, int z) {
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.removeTile) window.Garden.removeTile($x, $z);",
    );
  }

  /// Moves an object from one grid plot to a free grid plot.
  void moveTile(int fromX, int fromZ, int toX, int toZ) {
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.moveTile) window.Garden.moveTile($fromX, $fromZ, $toX, $toZ);",
    );
  }

  /// Synchronizes island grid slots with Flutter state.
  void setIslandState(List<Map<String, dynamic>> slots) {
    final encoded = jsonEncode(slots);
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.setIslandState) window.Garden.setIslandState($encoded);",
    );
  }

  /// Zooms camera in towards the island.
  void zoomIn() {
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.zoomIn) window.Garden.zoomIn();",
    );
  }

  /// Zooms camera out from the island.
  void zoomOut() {
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.zoomOut) window.Garden.zoomOut();",
    );
  }

  /// Rotates the floating island camera by 90 degrees.
  void rotate90() {
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.rotate90) window.Garden.rotate90();",
    );
  }

  /// Toggles automatic gentle rotation of the 3D island.
  void toggleSpin() {
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.toggleSpin) window.Garden.toggleSpin();",
    );
  }

  /// Resets the camera to default view.
  void resetView() {
    _controller?.runJavaScript(
      "if (window.Garden && window.Garden.resetView) window.Garden.resetView();",
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(
        child: Text(
          '🏝️ 3D Floating Garden Island (WebGL)',
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
