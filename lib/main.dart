import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
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
  double _dailyGoal = 1.0;
  late SharedPreferences _prefs;
  final FocusNode _focusNode = FocusNode();
  final double _volumeStep = 0.1; // 100ml per scroll step

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _focusNode.requestFocus();
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  @override
  void dispose() {
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
    if (newValue > 10) newValue = 10; // 10L max
    
    setState(() {
      _currentWaterIntake = double.parse(newValue.toStringAsFixed(1));
      _prefs.setDouble('water_intake', _currentWaterIntake);
    });
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentWaterIntake = _prefs.getDouble('water_intake') ?? 0.0;
      _dailyGoal = _prefs.getDouble('daily_goal') ?? 1.0;
    });
  }

  Widget _buildWaterButton(double amount, String label) {
    return ElevatedButton(
      onPressed: () => _updateWaterIntake(_currentWaterIntake + amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[800],
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  void _addWater(double amount) {
    _updateWaterIntake(_currentWaterIntake + amount);
  }

  void _resetDailyProgress() {
    setState(() {
      _currentWaterIntake = 0.0;
      _dailyGoal = 0.1;
      _prefs.setDouble('water_intake', _currentWaterIntake);
      _prefs.setDouble('daily_goal', _dailyGoal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _dailyGoal > 0 ? (_currentWaterIntake / _dailyGoal).clamp(0.0, 1.0) : 0.0;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final circleSize = isSmallScreen ? screenSize.width * 0.7 : 200.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Focus(
          autofocus: true,
          focusNode: _focusNode,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Progress circle
                  SizedBox(
                    width: circleSize,
                    height: circleSize,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background circle
                        CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[800],
                        ),
                        // Progress circle with rotation gesture
                        GestureDetector(
                          onVerticalDragUpdate: (details) {
                            // Convert vertical drag to volume change
                            final delta = -details.delta.dy / 100; // Scale down the sensitivity
                            _updateWaterIntake(_currentWaterIntake + delta);
                          },
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 10,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        // Add "check" icon button here to 
                        IconButton(
                          onPressed: _resetDailyProgress,
                          icon: const Icon(Icons.check, color: Colors.white),
                          color: Colors.white,
                          iconSize: 15,
                          padding: EdgeInsets.all(5),
                        ),
                        
                        // Center text
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(_currentWaterIntake * 1000).toInt()}ml',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'of ${(_dailyGoal * 1000).toInt()}ml',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}