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
  // Clé pour forcer la reconstruction de la barre de progression
  final GlobalKey _progressKey = GlobalKey();
  late Timer _goalIncreaseTimer;
  late Timer _dailyResetTimer;
  DateTime _lastResetDate = DateTime.now();
  final FocusNode _focusNode = FocusNode();
  final List<double> _volumeSteps = [0.0, 5.0, 15.0, 25.0, 33.0, 50.0, 75.0, 100.0, 125.0, 150.0, 200.0]; // Valeurs de volume prédéfinies
  int _currentVolumeIndex = 0; // Index de la valeur de volume actuelle
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;
  final double _minuteIncrement = 0.14; // 0.14cl par minute
  final double _maxDailyGoal = 200.0; // 200cl = 2L

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _startGoalIncreaseTimer();
    _startDailyResetTimer();
    RawKeyboard.instance.addListener(_handleKeyEvent);
    
    // Initialiser le contrôleur de défilement
    _scrollController.addListener(_onScroll);
    
    // Positionner le défilement sur la valeur actuelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentVolume(animate: false);
    });
    
    // Debug: Vérifier la valeur de _maxDailyGoal
    print('Valeur de _maxDailyGoal: $_maxDailyGoal');
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
    _scrollController.dispose();
    super.dispose();
    
    // Debug: Vérifier la valeur de _dailyConsumption à la fermeture
    print('Fermeture - Consommation quotidienne: $_dailyConsumption cl');
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.arrowUp) {
        // Passe à la valeur supérieure dans la liste
        _currentVolumeIndex = (_currentVolumeIndex + 1) % _volumeSteps.length;
        _updateWaterIntake(_volumeSteps[_currentVolumeIndex]);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        // Passe à la valeur inférieure dans la liste
        _currentVolumeIndex = (_currentVolumeIndex - 1) >= 0 
            ? _currentVolumeIndex - 1 
            : _volumeSteps.length - 1;
        _updateWaterIntake(_volumeSteps[_currentVolumeIndex]);
      }
    }
  }

  void _updateWaterIntake(double newValue) {
    // Trouve l'index de la valeur la plus proche dans la liste des volumes prédéfinis
    int newIndex = _volumeSteps.indexWhere((v) => v == newValue);
    if (newIndex == -1) {
      // Si la valeur n'est pas trouvée, on prend la plus proche
      newIndex = _volumeSteps.indexWhere((v) => v > newValue) - 1;
      if (newIndex < 0) newIndex = 0;
      if (newIndex >= _volumeSteps.length) newIndex = _volumeSteps.length - 1;
    }
    
    if (newIndex != _currentVolumeIndex) {
      _currentVolumeIndex = newIndex;
      setState(() {
        _currentWaterIntake = _volumeSteps[_currentVolumeIndex];
      });
      _saveWaterIntake();
      _scrollToCurrentVolume();
    }
  }
  
  void _scrollToCurrentVolume({bool animate = true}) {
    if (_scrollController.hasClients) {
      final itemHeight = 10.0; // Hauteur d'un élément
      final viewportHeight = 10.0; // Hauteur visible du ListView
      final targetOffset = _currentVolumeIndex * itemHeight - (viewportHeight - itemHeight) / 2;
      
      if (animate) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(targetOffset);
      }
    }
  }
  
  void _onScroll() {
    if (!_isScrolling) {
      _isScrolling = true;
      final scrollPosition = _scrollController.position.pixels;
      final itemHeight = 20.0; // Hauteur d'un élément
      final newIndex = (scrollPosition / itemHeight).round();
      
      // Gestion du défilement infini
      int actualIndex = newIndex % _volumeSteps.length;
      if (actualIndex < 0) actualIndex += _volumeSteps.length;
      
      if (actualIndex != _currentVolumeIndex) {
        _currentVolumeIndex = actualIndex;
        setState(() {
          _currentWaterIntake = _volumeSteps[_currentVolumeIndex];
        });
        _saveWaterIntake();
      }
      
      _isScrolling = false;
    }
  }

  Future<void> _saveWaterIntake() async {
    print('Sauvegarde - Consommation: $_dailyConsumption cl, Objectif: $_dailyGoal');
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
      
      print('Initialisation - Consommation chargée: $_dailyConsumption cl');
      
      if (lastResetDateStr != null) {
        _lastResetDate = DateTime.parse(lastResetDateStr);
        final lastResetDay = DateTime(_lastResetDate.year, _lastResetDate.month, _lastResetDate.day);
        
        if (lastResetDay.isBefore(today)) {
          // Nouveau jour, on réinitialise la consommation
          print('Nouveau jour - Réinitialisation de la consommation');
          _dailyConsumption = 0.0;
          _currentWaterIntake = 0.0;
          _lastResetDate = now;
        }
      } else {
        // Première utilisation
        print('Première utilisation - Initialisation des préférences');
        _lastResetDate = now;
      }
      
      _dailyGoal = _calculateGoalFromTime();
      print('Objectif quotidien initial: ${_dailyGoal.toStringAsFixed(2)} cl');
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
    if (_currentWaterIntake > 0) {  // Ne faire la mise à jour que si on a une valeur à ajouter
      // On ajoute la valeur actuelle à la consommation quotidienne
      final newConsumption = _dailyConsumption + _currentWaterIntake;
      
      // On met à jour l'état en une seule opération
      setState(() {
        _dailyConsumption = newConsumption;
        _currentWaterIntake = 0.0;
        _dailyGoal = _calculateGoalFromTime();
        // On force la recréation de la clé pour la barre de progression
        _progressKey.currentState?.setState(() {});
      });
      
      // On sauvegarde après la mise à jour de l'état
      _saveWaterIntake().then((_) {
        if (mounted) {
          setState(() {
            // On force une nouvelle mise à jour de l'état
            _progressKey.currentState?.setState(() {});
          });
        }
      });
      
      print('Nouvelle consommation quotidienne: $newConsumption cl');
    }
  }

  @override
  Widget build(BuildContext context) {
    // La progression est basée sur la consommation quotidienne par rapport à l'objectif max
    // Convert to cl for display
    final currentCl = _currentWaterIntake;
    // Le goal est la dette hydrique (peut être négatif)
    final goalCl = _dailyGoal;
    
    // Debug: Afficher les valeurs actuelles
    final progressValue = (_dailyConsumption / _maxDailyGoal).clamp(0.0, 1.0);
    print('Build - Progression: $progressValue ($_dailyConsumption / $_maxDailyGoal)');

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
                                // Utilise le premier pas de la liste des volumes prédéfinis comme incrément
                                final step = details.delta.dy > 0 ? -_volumeSteps[0] : _volumeSteps[0];
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
                                  // const SizedBox(height: 10),
                                  SizedBox(
                                    height: 20, // Hauteur du conteneur du carrousel
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      scrollDirection: Axis.vertical,
                                      itemCount: _volumeSteps.length * 3, // Pour l'effet de défilement infini
                                      itemBuilder: (context, index) {
                                        final actualIndex = index % _volumeSteps.length;
                                        final volume = _volumeSteps[actualIndex];
                                        final isSelected = volume == currentCl;
                                        
                                        return GestureDetector(
                                          onTap: () => _updateWaterIntake(volume),
                                          child: Container(
                                            height: 20, // Hauteur de chaque élément
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${volume.toInt()}cl',
                                              style: TextStyle(
                                                fontSize: isSelected ? 18 : 9,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isSelected ? AppColors.blue2 : AppColors.blue1,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // const SizedBox(height: 5),
                                 
                                  // Barre de progression avec une StatefulBuilder pour un contrôle précis
                                  StatefulBuilder(
                                    key: _progressKey,
                                    builder: (context, setState) {
                                      final progress = (_dailyConsumption / _maxDailyGoal).clamp(0.0, 1.0);
                                      print('Mise à jour UI - Progression: $progress ($_dailyConsumption / $_maxDailyGoal)');
                                      return Container(
                                        width: 100,
                                        height: 12,  // Hauteur légèrement augmentée
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          color: Colors.white24,  // Fond de la barre
                                          border: Border.all(color: Colors.white30, width: 0.5),  // Bordure pour mieux voir les limites
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Stack(
                                            children: [
                                              // Fond de la barre
                                              Container(color: Colors.white24),
                                              // Partie remplie
                                              FractionallySizedBox(
                                                widthFactor: progress,
                                                heightFactor: 1.0,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: AppColors.green,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
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