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
  late SharedPreferences _prefs;
  late Timer _goalIncreaseTimer;
  DateTime? _lastIncreaseTime;
  final FocusNode _focusNode = FocusNode();
  final double _volumeStep = 5.0; // 5cl per scroll step
  final double _minuteIncrement = 0.14; // 0.14cl par minute
  final double _maxDailyGoal = 200.0; // 200cl = 2L

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _focusNode.requestFocus();
    RawKeyboard.instance.addListener(_handleKeyEvent);
    
    _startGoalIncreaseTimer();
  }

  double _calculateGoalFromTime() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final minutesSinceMidnight = now.difference(midnight).inMinutes;
    return (minutesSinceMidnight * _minuteIncrement).clamp(0.0, _maxDailyGoal);
  }

  void _startGoalIncreaseTimer() {
    _goalIncreaseTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {
        _dailyGoal = _calculateGoalFromTime();
        _lastIncreaseTime = DateTime.now();
        _saveWaterIntake();
      });
    });
  }

  @override
  void dispose() {
    _goalIncreaseTimer.cancel(); // Cancel the timer when the widget is disposed
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
    _prefs.setDouble('water_intake', _currentWaterIntake);
    _prefs.setDouble('daily_goal', _dailyGoal);
    if (_lastIncreaseTime != null) {
      _prefs.setString('last_increase_time', _lastIncreaseTime!.toIso8601String());
    }
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentWaterIntake = _prefs.getDouble('water_intake') ?? 0.0;
      _dailyGoal = _calculateGoalFromTime();
      _lastIncreaseTime = DateTime.now();
      _saveWaterIntake();
    });
  }

  void _addWater(double amount) {
    _updateWaterIntake(_currentWaterIntake + amount);
  }

  void _resetDailyProgress() {
    // Cancel the current timer to prevent race conditions
    _goalIncreaseTimer.cancel();
    
    setState(() {
      // Calculate the time passed since last increase
      final now = DateTime.now();
      final lastIncreaseTime = _lastIncreaseTime ?? now;
      final timePassed = now.difference(lastIncreaseTime);
      
      // Calculate how many 30-second intervals have passed
      final intervalsPassed = timePassed.inSeconds ~/ 30;
      
      // Calculate the total automatic increase that should have happened (1cl per interval)
      final autoIncrease = intervalsPassed * 10.0; // 1cl per interval
      
      // Adjust the daily goal: subtract the submitted amount and add any automatic increases
      _dailyGoal = (_dailyGoal - _currentWaterIntake + autoIncrease).clamp(double.negativeInfinity, 100.0); // Allow negative values, keep max at 100.0
      
      _currentWaterIntake = 0.0;
      _lastIncreaseTime = now; // Reset the last increase time
      
      _prefs.setDouble('water_intake', _currentWaterIntake);
      _prefs.setDouble('daily_goal', _dailyGoal);
    });
    
    // Restart the timer
    _startGoalIncreaseTimer();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _dailyGoal > 0 ? (_currentWaterIntake / _dailyGoal).clamp(0.0, 1.0) : 0.0;
    // Convert to cl for display (1cl = 10ml, but we'll store in cl directly)
    final currentCl = _currentWaterIntake;
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
                                value: progress,
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
                                    width: 120,
                                    height: 8,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (goalCl - currentCl).clamp(0.0, _maxDailyGoal) / _maxDailyGoal,
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