import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/theme.dart';

import 'package:lottie/lottie.dart';

void main() {
  runApp(const DrinKUpApp());
}

class DrinKUpApp extends StatelessWidget {
  const DrinKUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrinKUp',
      debugShowCheckedModeBanner: false,
      theme: drinkUpTheme,
      home: const HomeScreen().withRotaryScaffold(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

extension RotaryScaffold on Widget {
  Widget withRotaryScaffold() {
    return Builder(
      builder: (context) {
        return Scaffold(
          body: SafeArea(
            child: Focus(
              autofocus: true,
              child: this,
            ),
          ),
        );
      },
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  double _currentWaterIntake = 0.0;
  double _dailyGoal = 0.0;
  double _dailyConsumption = 0.0; // Somme des valeurs soumises depuis minuit
  late SharedPreferences _prefs;
  late Timer _goalIncreaseTimer;
  late Timer _dailyResetTimer;
  DateTime _lastResetDate = DateTime.now();
  final FocusNode _focusNode = FocusNode();
  final double _volumeStep = 5.0; // 5cl par incrément
  final double _minuteIncrement = 0.14; // 0.14cl par minute
  final double _maxDailyGoal = 200.0; // 200cl = 2L

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _focusNode.requestFocus();
    RawKeyboard.instance.addListener(_handleKeyEvent);
    
    _startGoalIncreaseTimer();
    _startDailyResetTimer();
  }

  double _calculateGoalFromTime() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final minutesSinceMidnight = now.difference(midnight).inMinutes;
    final timeBasedGoal = minutesSinceMidnight * _minuteIncrement;
    
    // On retourne la dette hydrique (peut être négative si l'utilisateur a bu plus que nécessaire)
    return timeBasedGoal - _dailyConsumption;
  }

  void _startGoalIncreaseTimer() {
    _goalIncreaseTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {
        _dailyGoal = _calculateGoalFromTime();
        _saveWaterIntake();
      });
    });
  }

  @override
  void dispose() {
    _goalIncreaseTimer.cancel();
    _dailyResetTimer.cancel();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.arrowUp) {
        _updateWaterIntake(_currentWaterIntake + _volumeStep);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        _updateWaterIntake(_currentWaterIntake - _volumeStep);
      }
    }
  }

  void _updateWaterIntake(double newValue) {
    if (newValue < 0) newValue = 0;
    if (newValue > 250) newValue = 250; // 250cl (2.5L) max
    
    setState(() {
      _currentWaterIntake = double.parse(newValue.toStringAsFixed(1));
    });
    _saveWaterIntake();
  }

  Future<void> _saveWaterIntake() async {
    await _prefs.setDouble('water_intake', _currentWaterIntake);
    await _prefs.setDouble('daily_goal', _dailyGoal);
    await _prefs.setDouble('daily_consumption', _dailyConsumption);
    await _prefs.setString('last_reset_date', _lastResetDate.toIso8601String());
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Vérifier si c'est un nouveau jour
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastResetDateStr = _prefs.getString('last_reset_date');
    
    setState(() {
      _currentWaterIntake = _prefs.getDouble('water_intake') ?? 0.0;
      _dailyConsumption = _prefs.getDouble('daily_consumption') ?? 0.0;
      
      if (lastResetDateStr != null) {
        _lastResetDate = DateTime.parse(lastResetDateStr);
        final lastResetDay = DateTime(_lastResetDate.year, _lastResetDate.month, _lastResetDate.day);
        
        if (lastResetDay.isBefore(today)) {
          // Nouveau jour, on réinitialise la consommation
          _dailyConsumption = 0.0;
          _currentWaterIntake = 0.0;
          _lastResetDate = now;
        }
      } else {
        // Première utilisation
        _lastResetDate = now;
      }
      
      _dailyGoal = _calculateGoalFromTime();
      _saveWaterIntake();
    });
  }

  void _addWater(double amount) {
    _updateWaterIntake(_currentWaterIntake + amount);
  }

  void _startDailyResetTimer() {
    // Planifie la vérification quotidienne à minuit
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final durationUntilMidnight = midnight.difference(now);
    
    _dailyResetTimer = Timer(durationUntilMidnight, () {
      // À minuit, on réinitialise la consommation
      setState(() {
        _dailyConsumption = 0.0;
        _lastResetDate = DateTime.now();
        _saveWaterIntake();
      });
      
      // On reprogramme pour le prochain jour
      _startDailyResetTimer();
    });
  }

  void _resetDailyProgress() {
    setState(() {
      // On ajoute la valeur actuelle à la consommation quotidienne
      _dailyConsumption += _currentWaterIntake;
      // On réinitialise la valeur actuelle
      _currentWaterIntake = 0.0;
      // On met à jour le goal
      _dailyGoal = _calculateGoalFromTime();
      // On sauvegarde
      _saveWaterIntake();
    });
  }

  @override
  Widget build(BuildContext context) {
    // La progression est basée sur la consommation quotidienne par rapport à l'objectif max
    // Convert to cl for display
    final currentCl = _currentWaterIntake;
    // Le goal est la dette hydrique (peut être négatif)
    final goalCl = _dailyGoal;

    return Stack(
      children: [
        // Lottie background with scaling
        Positioned.fill(
          child: Transform.scale(
            scale: 1.15, // Scale up by 20%
            child: Lottie.asset(
              'assets/water_animation.json',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              repeat: true,
              animate: true,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading Lottie animation: $error');
                return Container(color: AppColors.dark);
              },
            ),
          ),
        ),
        // Main content
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Focus(
              autofocus: true,
              focusNode: _focusNode,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(11.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Progress circle - responsive size
                      SizedBox(
                        width: MediaQuery.of(context).size.shortestSide * 0.9, // 90% of the shortest side
                        height: MediaQuery.of(context).size.shortestSide * 0.9,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            GestureDetector(
                              onVerticalDragUpdate: (details) {
                                // Convert vertical drag to volume change (1px = 0.1L or 10cl)
                                final step = details.delta.dy > 0 ? -_volumeStep : _volumeStep;
                                _updateWaterIntake(_currentWaterIntake + step);
                              },
                              onVerticalDragEnd: (_) {
                                // Save the updated value when user stops dragging
                                _saveWaterIntake();
                              },
                              child: CircularProgressIndicator(
                                value: goalCl != 0 
                                    ? (_currentWaterIntake / goalCl).clamp(0.0, 1.0)
                                    : 0.0,
                                strokeWidth: 8,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue2),
                              ),
                            ),
                            
                            // Center text
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${goalCl.toInt()}cl',
                                    style: TextStyle(
                                      fontSize: 28,
                                      color: goalCl.toInt() > 100 
                                          ? AppColors.danger 
                                          : goalCl.toInt() > 50 
                                              ? AppColors.warning 
                                              : goalCl.toInt() < 1 
                                                  ? AppColors.success 
                                                  : AppColors.white,
                                    ),
                                  ),
                                  // Add "check" icon button validate user declaration
                                  IconButton(
                                    onPressed: _resetDailyProgress,
                                    icon: const Icon(Icons.check, color: AppColors.white),
                                    color: AppColors.white,
                                    iconSize: 20,
                                  ),
                                  // const SizedBox(height: 5),
                                  Text(
                                    '${currentCl.toInt()}cl',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),  
                                  ),
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    width: 100,
                                    height: 8,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (_dailyConsumption / _maxDailyGoal).clamp(0.0, 1.0),
                                        backgroundColor: Colors.white24,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue2),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                                  //
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}