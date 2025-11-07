import 'package:flutter/material.dart';
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
  double _dailyGoal = 1.0; // Default to 1L
  final double _increment = 0.25; // 25cl increment
  late SharedPreferences _prefs;

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
    _startGoalIncrement();
  }

  void _startGoalIncrement() {
    // Increase goal every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          if (_dailyGoal < 2.0) { // Cap at 2L
            _dailyGoal += 0.15; // Increment by 15cl
            if (_dailyGoal > 2.0) _dailyGoal = 2.0; // Ensure we don't exceed 2L
            _prefs.setDouble('daily_goal', _dailyGoal);
          }
        });
        _startGoalIncrement(); // Schedule next increment
      }
    });
  }

  void _addWater(double amount) async {
    setState(() {
      _currentWaterIntake += amount;
      if (_currentWaterIntake < 0) _currentWaterIntake = 0;
      _prefs.setDouble('water_intake', _currentWaterIntake);
    });
  }

  void _resetDailyProgress() {
    setState(() {
      _currentWaterIntake = 0.0;
      _dailyGoal = 0.1; // Reset to 10cl
      _prefs.setDouble('water_intake', _currentWaterIntake);
      _prefs.setDouble('daily_goal', _dailyGoal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _dailyGoal > 0 ? (_currentWaterIntake / _dailyGoal).clamp(0.0, 1.0) : 0.0;
    
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final circleSize = isSmallScreen ? screenSize.width * 0.7 : 250.0;
    
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
                              style: TextStyle(
                                fontSize: isSmallScreen ? 24 : 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                              ),
                            ),
                            Text(
                              'of ${(_dailyGoal * 1000).toInt()}ml',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 16,
                                color: Colors.grey
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Add water buttons - Wrap in SingleChildScrollView if needed
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildWaterButton(0.25, '250ml', isSmallScreen),
                        const SizedBox(width: 8),
                        _buildWaterButton(0.5, '500ml', isSmallScreen),
                        const SizedBox(width: 8),
                        _buildWaterButton(1.0, '1L', isSmallScreen),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
  }

  Widget _buildWaterButton(double amount, String label, [bool isSmall = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => _addWater(amount),
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: isSmall ? const EdgeInsets.all(16) : const EdgeInsets.all(20),
              backgroundColor: Colors.blue,
            ),
            child: Text(
              '+$label',
              style: TextStyle(
                fontSize: isSmall ? 12 : 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 10 : 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
