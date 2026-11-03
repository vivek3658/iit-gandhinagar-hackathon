import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme.dart';
import '../../services/citizen_api.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({required this.isActive, super.key});

  final bool isActive;

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  WebViewController? _controller;
  Map<String, dynamic>? _garden;
  String? _error;
  bool _ready = false;
  bool _loading = true;
  bool _buildMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _initializeWebView();
    _load();
  }

  @override
  void didUpdateWidget(covariant GardenScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    if (widget.isActive) {
      _initializeWebView();
    } else {
      _controller = null;
      _ready = false;
    }
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
            if (_buildMode &&
                value is Map &&
                value['type'] == 'selectEmptyTile') {
              final x = value['x'];
              final z = value['z'];
              if (x is num && z is num) {
                _chooseTile(x.toInt(), z.toInt());
              }
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
            _applyGardenState();
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(
                () => _error = '3D garden could not load: ${error.description}',
              );
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/web/garden.html');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _garden = await CitizenApi.instance.getGarden();
      if (mounted) {
        setState(() => _loading = false);
        _applyGardenState();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  void _applyGardenState() {
    final controller = _controller;
    if (!_ready || _garden == null || controller == null) return;
    final size = _garden!['gridSize'];
    final placed = _garden!['placedTiles'];
    if (size is num) {
      controller.runJavaScript(
        'if(window.Garden) window.Garden.setGridSize(${size.toInt()});',
      );
    }
    if (placed is! List) return;
    final offset = size is num ? (size.toInt() / 2).floor() : 1;
    final slots = placed
        .whereType<Map>()
        .map((raw) {
          final tile = Map<String, dynamic>.from(raw);
          final x = tile['x'];
          final y = tile['y'];
          final rotation = tile['rotation'];
          if (x is! num || y is! num) return null;
          return <String, Object>{
            'id': tile['tileId'] as String? ?? 'SPARROW_HOME',
            'x': x.toInt() - offset,
            'z': y.toInt() - offset,
            'r': rotation is num ? (rotation.toInt() ~/ 90) % 4 : 0,
          };
        })
        .whereType<Map<String, Object>>()
        .toList();
    controller.runJavaScript(
      'if(window.Garden) window.Garden.setIslandState(${jsonEncode(slots)});',
    );
  }

  Future<void> _chooseTile(int gardenX, int gardenZ) async {
    final data = _garden;
    final catalog = data?['catalog'];
    if (data == null || catalog is! List) return;
    final gridSize = data['gridSize'] is num
        ? (data['gridSize'] as num).toInt()
        : 3;
    final backendX = gardenX + (gridSize / 2).floor();
    final backendY = gardenZ + (gridSize / 2).floor();
    final available = catalog
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .where((tile) => tile['id'] != 'SPARROW_HOME')
        .toList();
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _TilePicker(
        catalog: available,
        coins: data['citizenCoins'] is num
            ? (data['citizenCoins'] as num).toInt()
            : null,
      ),
    );
    if (selected == null) return;
    final tileId = selected['id'];
    if (tileId is! String) return;
    try {
      final preview = await CitizenApi.instance.previewGardenTile(
        tileId: tileId,
        x: backendX,
        y: backendY,
        rotation: 0,
      );
      if (preview['isValid'] != true) {
        _toast(preview['message'] as String? ?? 'That plot is not available.');
        return;
      }
      if (!mounted) return;
      final cost = selected['cost'] is num
          ? (selected['cost'] as num).toInt()
          : 0;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Place ${selected['name'] ?? 'this garden tile'}?'),
          content: Text(
            'This will use $cost Green Coins. The server will check your balance and save the placement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Place · $cost 🪙'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      final result = await CitizenApi.instance.buyAndPlaceGardenTile(
        tileId: tileId,
        x: backendX,
        y: backendY,
        rotation: 0,
      );
      if (result['success'] != true) {
        _toast(
          result['message'] as String? ?? 'Garden purchase was not completed.',
        );
        return;
      }
      await _load();
      if (mounted) _toast('${selected['name'] ?? 'Garden tile'} added!');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _toggleBuildMode() {
    final controller = _controller;
    if (!_ready || controller == null) return;
    setState(() => _buildMode = !_buildMode);
    controller.runJavaScript(
      'if(window.Garden) window.Garden.setBuildMode($_buildMode);',
    );
    if (_buildMode) {
      _toast('Tap an empty plot to preview a garden item.');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final level = _garden?['mascotLevel'];
    final coins = _garden?['citizenCoins'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sparrow garden'),
        backgroundColor: UrjaColors.canvas,
        actions: [
          IconButton(
            onPressed: _ready
                ? () => _controller?.runJavaScript(
                    'if(window.Garden) window.Garden.resetView();',
                  )
                : null,
            tooltip: 'Reset view',
            icon: const Icon(Icons.center_focus_strong_rounded),
          ),
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh garden',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 7, 17, 12),
            child: Row(
              children: [
                Expanded(
                  child: _GardenStat(
                    icon: Icons.emoji_events_rounded,
                    label: 'Sparrow',
                    value: level is num ? 'Level ${level.toInt()}' : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GardenStat(
                    icon: Icons.toll_rounded,
                    label: 'Green Coins',
                    value: coins is num ? '${coins.toInt()}' : '—',
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: _ready ? _toggleBuildMode : null,
                  icon: Icon(
                    _buildMode
                        ? Icons.check_rounded
                        : Icons.construction_rounded,
                  ),
                  label: Text(_buildMode ? 'Done' : 'Build'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _buildMode
                        ? UrjaColors.forest
                        : UrjaColors.mint,
                    foregroundColor: _buildMode
                        ? Colors.white
                        : UrjaColors.forest,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(13, 0, 13, 11),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2DF),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: UrjaColors.line),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_controller case final controller?)
                    WebViewWidget(controller: controller),
                  if (!_ready) const Center(child: CircularProgressIndicator()),
                  if (_loading && _garden != null)
                    const Align(
                      alignment: Alignment.topCenter,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (_error != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: .93),
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF9D3429),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: Text(
              _buildMode
                  ? 'Tap an empty plot · preview the cost · confirm to place'
                  : 'Pinch to zoom · drag to explore · build when you’re ready',
              textAlign: TextAlign.center,
              style: const TextStyle(color: UrjaColors.muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _GardenStat extends StatelessWidget {
  const _GardenStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: UrjaColors.line),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: UrjaColors.forest),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: UrjaColors.muted, fontSize: 9),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TilePicker extends StatelessWidget {
  const _TilePicker({required this.catalog, required this.coins});

  final List<Map<String, dynamic>> catalog;
  final int? coins;

  @override
  Widget build(BuildContext context) {
    final available = catalog
        .where((tile) => tile['isUnlocked'] == true)
        .toList();
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        decoration: const BoxDecoration(
          color: UrjaColors.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a garden tile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              coins == null
                  ? 'Your coin balance is unavailable.'
                  : '$coins Green Coins available',
              style: const TextStyle(color: UrjaColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: available.isEmpty
                  ? const Center(
                      child: Text(
                        'No tiles unlocked yet. Keep growing your sparrow.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: available.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: UrjaColors.line),
                      itemBuilder: (context, index) {
                        final tile = available[index];
                        final cost = tile['cost'] is num
                            ? (tile['cost'] as num).toInt()
                            : 0;
                        final canAfford = coins == null || coins! >= cost;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tile['name'] as String? ?? 'Garden item'),
                          subtitle: Text(
                            '${tile['category'] ?? 'Garden'} · ${tile['description'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '$cost 🪙',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: canAfford
                                  ? UrjaColors.forest
                                  : UrjaColors.muted,
                            ),
                          ),
                          enabled: canAfford,
                          onTap: canAfford
                              ? () => Navigator.pop(context, tile)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
