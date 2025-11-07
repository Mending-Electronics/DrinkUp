import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wear/wear.dart';

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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _currentWaterIntake = 0.0;
  double _dailyGoal = 1.0;
  late SharedPreferences _prefs;
  bool _isAmbient = false;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentWaterIntake = _prefs.getDouble('water_intake') ?? 0.0;
      _dailyGoal = _prefs.getDouble('daily_goal') ?? 1.0;
    });
  }

  void _addWater(double amount) {
    setState(() {
      _currentWaterIntake = (_currentWaterIntake + amount).clamp(0.0, _dailyGoal * 1.5);
      _prefs.setDouble('water_intake', _currentWaterIntake);
    });
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

    return WatchShape(
      builder: (BuildContext context, WearShape shape, Widget? child) {
        return AmbientMode(
          builder: (context, mode, child) {
            _isAmbient = mode == WearMode.ambient;
            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
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
                              // Progress circle
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 10,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                              // Center text
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${(_currentWaterIntake * 1000).toInt()}ml',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'of ${(_dailyGoal * 1000).toInt()}ml',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Rotary input instructions
                        if (!_isAmbient)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Rotate the bezel to adjust',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Current: +${_getIncrementAmount()}ml per click',
                                  style: TextStyle(
                                    color: Colors.blue[300],
                                    fontSize: 12,
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
              floatingActionButton: FloatingActionButton(
                onPressed: _resetDailyProgress,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.refresh, color: Colors.white),
              ),
            );
          },
        );
      },
    );
  }

  // Get the current increment amount based on the daily goal
  String _getIncrementAmount() {
    if (_dailyGoal <= 0.5) return '50';  // 50ml for goals <= 500ml
    if (_dailyGoal <= 1.0) return '100'; // 100ml for goals <= 1L
    return '200'; // 200ml for goals > 1L
  }
}