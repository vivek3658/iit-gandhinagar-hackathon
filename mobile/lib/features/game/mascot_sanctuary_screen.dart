import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/game_state_service.dart';
import '../../services/notification_service.dart';
import '../../services/weather_service.dart';
import '../../constants/auth_config.dart';
import '../auth/google_login_screen.dart';
import '../dashboard/carbon_dashboard_sheet.dart';
import '../dashboard/monthly_electricity_tracker_sheet.dart';
import '../appliances/appliance_registry_sheet.dart';
import '../commute/commute_travel_sheet.dart';
import '../onboarding/energy_setup_sheet.dart';
import '../water/water_conservation_sheet.dart';
import '../menu/sanctuary_menu_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../dashboard/daily_quests_sheet.dart';
import 'sparrow_3d_stage.dart';

/// Screen 1: 3D Mascot Sanctuary & Interactive Companion (WebGL Three.js Game UI)
///
/// Features:
/// - Mascot starts at Level 1 and grows strictly from verified CO2e saved.
/// - Live Weather API automatically applies ambient weather FX leaving outfits intact.
/// - 2-minute idle timer: bird nods off to sleep; tap sleeping bird to wake up!
/// - Real Android system notifications posted to device notification shade.
/// - Night screen dimming and lighting shifts at night or user's bedtime.
/// - Navigation: Slide Left to Activity Feed, Slide Right to Wardrobe, Scroll Down to 3D Garden Island.
class MascotSanctuaryScreen extends StatefulWidget {
  final VoidCallback onScrollToGarden;
  final VoidCallback onSlideToWardrobe;
  final VoidCallback onSlideToActivity;

  const MascotSanctuaryScreen({
    super.key,
    required this.onScrollToGarden,
    required this.onSlideToWardrobe,
    required this.onSlideToActivity,
  });

  @override
  State<MascotSanctuaryScreen> createState() => _MascotSanctuaryScreenState();
}

class _MascotSanctuaryScreenState extends State<MascotSanctuaryScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<Sparrow3DStageState> _sparrowKey =
      GlobalKey<Sparrow3DStageState>();
  final GameStateService _state = GameStateService.instance;

  WeatherData? _currentWeather;
  String _currentDialogue =
      "Chirp! 🌿 Welcome to URJA ONE! Tap me to pet or check our carbon dashboard!";
  Timer? _dialogueResetTimer;
  Timer? _idleSleepTimer;
  Timer? _expressionResetTimer;

  late final AnimationController _bubbleAnimController;
  late final Animation<double> _bubbleScale;

  // In-app Ambient Nudge Banner State
  Map<String, dynamic>? _activeNudgeAlert;
  bool _backendMascotLoading = false;
  DateTime _lastInteractionTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool get _isInteractionCooldown =>
      DateTime.now().difference(_lastInteractionTime).inMilliseconds < 2500;

  final List<String> _startupTips = [
    "Setting your AC thermostat to 24°C saves ~24% electricity and ₹1,800/yr in Gujarat! ❄️",
    "Unplugging idle laptop & phone chargers stops 'vampire power' standby loss! 🔌",
    "Switching off your vehicle engine at red lights >30s saves ~₹150/month in fuel! 🚦",
    "Soaking dal/chana for 30 minutes cuts LPG gas cooking stove time in half! 🥘",
    "A clean refrigerator door seal stops cooling leaks and saves ₹200/month! 🧊",
  ];
  int _tipIndex = 0;

  bool get _isNightTime {
    if (!_state.enableNightDimming) return false;
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 21 || hour < 6 || (_state.enableSleepReminder && hour >= _state.sleepTime.hour);
  }

  bool get _isNightTimeNestSleep {
    final hour = DateTime.now().hour;
    return hour >= 23 || hour < 6;
  }

  @override
  void initState() {
    super.initState();
    _bubbleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bubbleScale = CurvedAnimation(
      parent: _bubbleAnimController,
      curve: Curves.easeOutBack,
    );
    _bubbleAnimController.forward();

    _state.addListener(_onStateChange);
    _loadWeatherAndStartupTip();
    _loadBackendMascot();
    _resetIdleTimer();

  }

  @override
  void dispose() {
    _dialogueResetTimer?.cancel();
    _idleSleepTimer?.cancel();
    _expressionResetTimer?.cancel();
    _bubbleAnimController.dispose();
    _state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _showExpression(String expression, {Duration duration = const Duration(seconds: 5)}) {
    _expressionResetTimer?.cancel();
    _sparrowKey.currentState?.setExpression(expression);
    if (expression == 'sleep' || expression == 'resting' || expression == 'nest') return;
    _expressionResetTimer = Timer(duration, () {
      if (mounted && !_state.isSleeping) {
        _sparrowKey.currentState?.setExpression('happy');
      }
    });
  }

  void _resetIdleTimer() {
    _idleSleepTimer?.cancel();
    _idleSleepTimer = Timer(Duration(seconds: _state.idleTimeoutSeconds), () {
      if (mounted && !_state.isSleeping) {
        _putSparrowToSleep();
      }
    });
  }

  void _putSparrowToSleep() {
    _state.setSleeping(true);
    _sparrowKey.currentState?.sleep();
    _say("Zzz... (Sparrow dozed off after 2 min. Tap me to wake up! 😴)", duration: const Duration(seconds: 10));
  }

  void _wakeUpSparrow() {
    _state.setSleeping(false);
    HapticFeedback.mediumImpact();
    _sparrowKey.currentState?.wake();
    _showExpression('curious');
    _say("Yawn... Chirp! 🌿 I'm awake and ready to guard your energy! ⚡");
    _resetIdleTimer();
  }

  Future<void> _loadWeatherAndStartupTip() async {
    final weather = await WeatherService.fetchCurrentWeather();
    if (!mounted) return;

    setState(() {
      _currentWeather = weather;
      _state.setWeatherFx(weather.weatherFx);
    });

    if (weather.weatherFx != null) {
      _sparrowKey.currentState?.wear('fx', weather.weatherFx);
    }

    _sparrowKey.currentState?.setNight(_isNightTime);

    if (_isNightTimeNestSleep) {
      _state.setSleeping(true);
      _sparrowKey.currentState?.sleep();
      _say("Zzz... 🌙 Cheechee is cozy asleep in the sanctuary nest (11 PM - 6 AM). Shhh, resting for tomorrow's green quests!", duration: const Duration(seconds: 10));
    } else if (_isNightTime) {
      _say("Good evening! 🌙 Checking all idle appliances before bedtime keeps Gujarat green!");
    } else {
      final tip = _startupTips[_tipIndex % _startupTips.length];
      _say("Chirp! 🌿 Weather today: ${weather.condition} (${weather.temperature}°C). $tip");
    }
  }

  void _say(String text, {Duration duration = const Duration(seconds: 5)}) {
    _dialogueResetTimer?.cancel();
    setState(() => _currentDialogue = text);

    _bubbleAnimController.reset();
    _bubbleAnimController.forward();

    _dialogueResetTimer = Timer(duration, () {
      if (mounted && !_state.isSleeping) {
        setState(() {
          _currentDialogue = _isNightTime
              ? "Good night! 🌙 Standing watch over your energy sanctuary."
              : "Keeping watch over your energy sanctuary! Level ${_state.mascotLevel} Companion 🌿";
        });
      }
    });
  }

  void _onSparrowPetted(String expression) {
    if (_isInteractionCooldown) return;
    _lastInteractionTime = DateTime.now();
    _resetIdleTimer();
    if (_isNightTimeNestSleep) {
      if (_state.soundEnabled) HapticFeedback.lightImpact();
      _say("Zzz... 💤 Cheechee is resting in the nest until 6:00 AM! Shhh... 🌙", duration: const Duration(seconds: 4));
      return;
    }

    if (_state.isSleeping) {
      _wakeUpSparrow();
      return;
    }

    if (_state.soundEnabled) HapticFeedback.selectionClick();
    _interactWithBackendMascot();
    _state.setVitality((_state.vitality + 0.05).clamp(0.0, 1.0));


    final tone = _state.mascotBehaviorTone;
    String petMsg = "Aww! 🥰 Purr-chirp! You petted me! Energy boosted!";
    if (tone == 'Coach') {
      petMsg = "Chirp! ⚡ Feeling energized! Let's hit our daily kWh reduction goal!";
    } else if (tone == 'Zen Guardian') {
      petMsg = "Breathe in peace, breathe out carbon. 🍃 Thank you, guardian.";
    }

    _say(petMsg);
  }

  Future<void> _loadBackendMascot() async {
    final token = AuthService.instance.accessToken;
    if (token == null || token.isEmpty || _backendMascotLoading) return;
    _backendMascotLoading = true;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(Uri.parse('${AuthConfig.apiBaseUrl}/mascot/state'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      if (response.statusCode < 200 || response.statusCode >= 300 || !mounted) return;
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final data = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded;
      final vitality = data['vitality'];
      if (vitality is num) _state.setVitality((vitality > 1 ? vitality / 100 : vitality).toDouble());
      final expression = data['expression'] as String?;
      if (expression != null && expression.isNotEmpty) _showExpression(expression.toLowerCase());
      final dialogue = data['dialogue'];
      final line = dialogue is Map<String, dynamic> ? dialogue['text'] as String? : dialogue as String?;
      if (line != null && line.isNotEmpty) _say(line, duration: const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[Mascot] Backend state unavailable: $e');
    } finally {
      _backendMascotLoading = false;
    }
  }

  Future<void> _interactWithBackendMascot() async {
    final token = AuthService.instance.accessToken;
    if (token == null || token.isEmpty) return;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(Uri.parse('${AuthConfig.apiBaseUrl}/mascot/interact'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.headers.contentType = ContentType.json;
      request.write('{}');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      if (response.statusCode < 200 || response.statusCode >= 300 || !mounted) return;
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final data = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded;
      final dialogue = data['dialogue'];
      final line = dialogue is Map<String, dynamic> ? dialogue['text'] as String? : dialogue as String?;
      if (line != null && line.isNotEmpty) _say(line);
    } catch (e) {
      debugPrint('[Mascot] Backend interaction unavailable: $e');
    }
  }

  void triggerPet() {
    if (_isInteractionCooldown) return;
    _lastInteractionTime = DateTime.now();
    _resetIdleTimer();
    if (_state.isSleeping) {
      _wakeUpSparrow();
      return;
    }
    if (_state.soundEnabled) HapticFeedback.mediumImpact();
    _sparrowKey.currentState?.pet();
    _state.setVitality((_state.vitality + 0.05).clamp(0.0, 1.0));
    _interactWithBackendMascot();
    _say("Aww! 🥰 Purr-chirp! You petted Cheechee! Vitality boosted!");
  }

  void triggerWater() {
    if (_isInteractionCooldown) return;
    _lastInteractionTime = DateTime.now();
    _resetIdleTimer();
    if (_state.isSleeping) {
      _wakeUpSparrow();
      return;
    }
    if (_state.soundEnabled) HapticFeedback.mediumImpact();
    _showExpression('watering');
    _state.addCoins(5);
    _say("Nurturing the green sapling! 💧 Every drop saved protects Gujarat's Narmada basin!");
  }

  void triggerCelebrate() {
    if (_isInteractionCooldown) return;
    _lastInteractionTime = DateTime.now();
    _resetIdleTimer();
    if (_state.isSleeping) {
      _wakeUpSparrow();
      return;
    }
    if (_state.soundEnabled) HapticFeedback.heavyImpact();
    _showExpression('celebrating');
    _say("Chirp hooray! 🎉 +${_state.co2eSavedKg.toStringAsFixed(1)} kg CO2e saved! Level ${_state.mascotLevel} Companion!");
  }

  // Trigger nest
  void triggerNest() {
    if (_isInteractionCooldown) return;
    _lastInteractionTime = DateTime.now();
    _resetIdleTimer();
    if (_state.soundEnabled) HapticFeedback.selectionClick();
    _showExpression('nest');
    _say("Resting cozy in the sanctuary nest 🪺 Vampire load standby switches are OFF!");
  }


  void triggerFeed() {
    if (_isInteractionCooldown) return;
    _lastInteractionTime = DateTime.now();
    _resetIdleTimer();
    if (_state.isSleeping) {
      _wakeUpSparrow();
      return;
    }
    if (_state.soundEnabled) HapticFeedback.mediumImpact();
    _state.setVitality((_state.vitality + 0.15).clamp(0.0, 1.0));
    _showExpression('happy');
    _say("Nom nom! 🌾 Delicious organic seeds! Vitality restored to ${(_state.vitality * 100).toInt()}%!");
  }

  void triggerNextTip() {
    if (_isInteractionCooldown) return;
    _lastInteractionTime = DateTime.now();
    _resetIdleTimer();
    if (_state.isSleeping) {
      _wakeUpSparrow();
      return;
    }
    if (_state.soundEnabled) HapticFeedback.selectionClick();
    _tipIndex++;
    final tip = _startupTips[_tipIndex % _startupTips.length];
    _showExpression('thinking');
    _say("Mission LiFE Tip: $tip", duration: const Duration(seconds: 7));
  }

  void _openDashboard() {
    _resetIdleTimer();
    if (_state.soundEnabled) HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CarbonDashboardSheet(
        onActionCompleted: () {
          _showExpression('cheering');
          _say("Carbon prevented! 🍃 Every kg keeps Gujarat green!");
        },
      ),
    );
  }

  void _openElectricityTracker() {
    _resetIdleTimer();
    if (_state.soundEnabled) HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const MonthlyElectricityTrackerSheet(),
    );
  }

  void _openFullMenuScreen() {
    _resetIdleTimer();
    if (_state.soundEnabled) HapticFeedback.selectionClick();
    SanctuaryMenuScreen.show(
      context,
      onSlideToActivity: widget.onSlideToActivity,
      onSlideToWardrobe: widget.onSlideToWardrobe,
    );
  }

  void _openLeaderboard() {
    _resetIdleTimer();
    if (_state.soundEnabled) HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }

  void _openDailyQuests() {
    _resetIdleTimer();
    if (_state.soundEnabled) HapticFeedback.selectionClick();
    DailyQuestsSheet.show(context);
  }

  /// Displays both an in-app banner AND a real Android System Notification in the notification center
  void displayAmbientNudgeBanner({
    required String title,
    required String message,
    required int coinsAwarded,
    required double co2Saved,
  }) {
    HapticFeedback.heavyImpact();
    setState(() {
      _activeNudgeAlert = {
        'title': title,
        'message': message,
        'coins': coinsAwarded,
        'co2': co2Saved,
      };
    });

    // 1. Post real Android system notification
    NotificationService.instance.showSystemNotification(
      title: title,
      message: message,
    );

    // 2. Add to notification history in state
    _state.addNotification(
      title: title,
      message: message,
      type: 'nudge',
    );

    _say("Sparrow alert: $title Check your notification shade! ⚡");
  }

  void _confirmNudgeAction() {
    if (_activeNudgeAlert == null) return;
    HapticFeedback.mediumImpact();

    final title = _activeNudgeAlert!['title'] as String;
    final coins = _activeNudgeAlert!['coins'] as int;
    final co2 = _activeNudgeAlert!['co2'] as double;

    final didLevelUp = _state.recordEcoAction(
      actionName: title,
      co2Saved: co2,
      coinsAwarded: coins,
    );

    setState(() {
      _activeNudgeAlert = null;
    });

    if (didLevelUp) {
      _sparrowKey.currentState?.levelUp(_state.mascotLevel);
      _say("🎉 LEVEL UP! I'm now Level ${_state.mascotLevel}! Real carbon saved! 🌟");
    } else {
      _showExpression('excited');
      _say("Awesome! +$coins 🪙 & +${co2}kg CO2e prevented! 🍃");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetIdleTimer(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Atmospheric Dynamic Sky Gradient (Switches to Night Ambiance when dark)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isNightTime
                      ? const [
                          Color(0xFF0F172A), // Dark starry night navy
                          Color(0xFF064E3B), // Deep twilight forest emerald
                          Color(0xFF022C22), // Deep night ground
                        ]
                      : const [
                          Color(0xFFBAE6FD), // Light sunlit sky blue
                          Color(0xFFD1FAE5), // Soft nature meadow green
                          Color(0xFFF0FDF4), // Warm ground cream
                        ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Soft environmental wash keeps the existing 3D Sparrow readable
            // while matching the warm, storybook surfaces in the app reference.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x120B132B), Colors.transparent, Color(0x330B132B)],
                  stops: [0, 0.48, 1],
                ),
              ),
            ),

            // Interactive 3D WebGL Sparrow Mascot Canvas
            Sparrow3DStage(
              key: _sparrowKey,
              onSparrowPetted: _onSparrowPetted,
              onSparrowWoken: _wakeUpSparrow,
            ),

            // Top Game Bar HUD & Settings Menu Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: _buildTopGameHud(),
            ),

            // Live Weather Status Pill (Top Left under HUD)
            if (_currentWeather != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 76,
                left: 20,
                child: _buildWeatherPill(),
              ),

            // In-App Ambient Nudge Banner (e.g. Charger Unplug / Bedtime Sweep)
            if (_activeNudgeAlert != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 124,
                left: 16,
                right: 16,
                child: _buildAmbientNudgeBanner(),
              ),

            // Companion Speech Bubble
            if (_activeNudgeAlert == null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 124,
                left: 20,
                right: 20,
                child: _buildSpeechBubble(),
              ),

            // Floating Action Pills (Left side: Domains)
            Positioned(
              left: 16,
              bottom: MediaQuery.of(context).size.height < 720 ? 205 : 236,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDomainPill(
                    icon: '💧',
                    label: 'Water',
                    color: const Color(0xFF0284C7),
                    onTap: () => WaterConservationSheet.show(context),
                  ),
                  const SizedBox(height: 6),
                  _buildDomainPill(
                    icon: '📱',
                    label: 'Devices',
                    color: const Color(0xFF059669),
                    onTap: () => ApplianceRegistrySheet.show(context),
                  ),
                  const SizedBox(height: 6),
                  _buildDomainPill(
                    icon: '🚴',
                    label: 'Commute',
                    color: const Color(0xFFD97706),
                    onTap: () => CommuteTravelSheet.show(context),
                  ),
                  const SizedBox(height: 6),
                  _buildDomainPill(
                    icon: '⚡',
                    label: 'Solar',
                    color: const Color(0xFFEAB308),
                    onTap: () => EnergySetupSheet.show(context),
                  ),
                ],
              ),
            ),

            // Floating Action Pills (Right side)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).size.height < 720 ? 205 : 236,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildFloatingPlotButton(),
                  const SizedBox(height: 8),
                  _buildFloatingDashboardButton(),
                ],
              ),
            ),

            // Cozy Nest Indicator (11 PM - 6 AM)
            if (_isNightTimeNestSleep)
              Positioned(
                top: MediaQuery.of(context).padding.top + 76,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF818CF8), width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🌙', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        'Nest Sleep (11 PM - 6 AM)',
                        style: TextStyle(
                          color: Color(0xFFC7D2FE),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Vitality Bar & Clean Navigation to Garden
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCompanionActionDock(),
                  const SizedBox(height: 8),
                  _buildVitalityCard(),
                  const SizedBox(height: 12),
                  _buildScrollToGardenButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainPill({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F0DE).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: const [
            BoxShadow(color: Color(0x66321D10), blurRadius: 12, offset: Offset(0, 4)),
            BoxShadow(color: Colors.white70, blurRadius: 0, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF344033),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopGameHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F0DE).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x66321D10), offset: Offset(0, 4), blurRadius: 14),
          BoxShadow(color: Colors.white70, offset: Offset(0, 1), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          // Activity Feed Capsule
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onSlideToActivity();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F2CB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC5D8A4)),
              ),
              child: const Icon(Icons.bolt_rounded, color: Color(0xFF9A6A10), size: 18),
            ),
          ),
          const SizedBox(width: 8),

          // Player Level & Progress
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE4D1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0D5C0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lv ${_state.mascotLevel} Sparrow',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF276C42),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        value: _state.levelProgress,
                        backgroundColor: Color(0xFFD3D0BE),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Coins Capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0xFF92400E), offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '${_state.coins}',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Leaderboard Trophy Button
          InkWell(
            onTap: _openLeaderboard,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 14)),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Daily Quests Button
          InkWell(
            onTap: _openDailyQuests,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB8D39B)),
              ),
              child: const Center(
                child: Text('🎯', style: TextStyle(fontSize: 14)),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Command Hub / Menu Button
          InkWell(
            onTap: _openFullMenuScreen,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF0A3612), offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Color(0xFF05200E),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out from URJA ONE?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AuthService.instance.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const GoogleLoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherPill() {
    final w = _currentWeather!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x331B6B44)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2B1A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(w.icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            '${w.district} • ${w.temperature}°C • ${w.condition}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2B1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientNudgeBanner() {
    final alert = _activeNudgeAlert!;
    final title = alert['title'] as String;
    final message = alert['message'] as String;
    final coins = alert['coins'] as int;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2417),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33F59E0B),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _activeNudgeAlert = null),
                child: const Icon(Icons.close, color: Colors.white60, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _confirmNudgeAction,
              icon: const Icon(Icons.check, size: 14),
              label: Text(
                'Turn Off Now (+$coins 🪙)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble() {
    return ScaleTransition(
      scale: _bubbleScale,
      alignment: Alignment.bottomCenter,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x181B6B44),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_state.isSleeping ? '😴' : '🐥', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _currentDialogue,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF344033),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingPlotButton() {
    return GestureDetector(
      onTap: _openElectricityTracker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F0DE).withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📈', style: TextStyle(fontSize: 13)),
            SizedBox(width: 5),
            Text(
              'Meter Plot',
              style: TextStyle(
                color: Color(0xFF344033),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  Widget _buildFloatingDashboardButton() {
    return GestureDetector(
      onTap: _openDashboard,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F0DE).withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📊', style: TextStyle(fontSize: 13)),
            SizedBox(width: 5),
            Text(
              'CO2e Ledger',
              style: TextStyle(
                color: Color(0xFF344033),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  Widget _buildCompanionActionDock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x181B6B44),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionDockButton(icon: '🐥', label: 'Pet', onTap: triggerPet),
          _buildActionDockButton(icon: '🌾', label: 'Feed', onTap: triggerFeed),
          _buildActionDockButton(icon: '💧', label: 'Water', onTap: triggerWater),
          _buildActionDockButton(icon: '🥳', label: 'Cheer', onTap: triggerCelebrate),
          _buildActionDockButton(icon: '💡', label: 'Tip', onTap: triggerNextTip),
          _buildActionDockButton(icon: '🪺', label: 'Nest', onTap: triggerNest),
        ],
      ),
    );
  }

  Widget _buildActionDockButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD1FAE5), width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1B6B44),
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalityCard() {
    final percentInt = (_state.vitality * 100).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E9).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F2B1A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('💚', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Sparrow Vitality',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              color: Color(0xFF344033),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$percentInt%',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            height: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _state.vitality,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF22C55E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollToGardenButton() {
    return GestureDetector(
      onTap: () {
        if (_state.soundEnabled) HapticFeedback.selectionClick();
        widget.onScrollToGarden();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF16A34A), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3316A34A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Scroll Down to 3D Garden Island 🗺️',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_downward, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  
}
