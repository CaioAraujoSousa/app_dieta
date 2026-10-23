import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'package:intl/intl.dart';
import 'database/db_helper.dart';
import 'models/meal.dart';
import 'models/daily_log.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Se as notificações falharem (ex.: permissão de alarme), o app abre mesmo assim.
  try {
    await NotificationService.init();
    await NotificationService.scheduleMealNotifications();
  } catch (e) {
    debugPrint('Erro ao configurar notificações: $e');
  }

  runApp(const DietApp());
}

class DietApp extends StatelessWidget {
  const DietApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dieta & Hipertrofia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Azul minimalista e limpo
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TodayTab(),
    MenuTab(),
    ProgressTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mostra só a aba atual: assim cada aba recarrega os dados do banco
      // toda vez que é aberta (o IndexedStack deixava a Disciplina congelada).
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Hoje',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Cardápio',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Disciplina',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 1. TELA "HOJE" (REGISTRO E PROGRESSO DIÁRIO)
// ==========================================
class TodayTab extends StatefulWidget {
  const TodayTab({super.key});

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  // dd = dia do mês (DD seria o dia do ano e geraria datas como 2026-10-296)
  final String _todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  Map<String, DailyLog> _todayLogs = {};
  bool _isLoading = true;

  final List<Map<String, String>> _periods = [
    {'key': 'cafe', 'label': 'Café da Manhã', 'time': '07:30'},
    {'key': 'almoco', 'label': 'Almoço', 'time': '12:00'},
    {'key': 'lanche', 'label': 'Lanche da Tarde', 'time': '15:30'},
    {'key': 'jantar', 'label': 'Jantar', 'time': '19:30'},
    {'key': 'ceia', 'label': 'Ceia', 'time': '22:00'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayLogs();
  }

  Future<void> _loadTodayLogs() async {
    final logs = await DBHelper.getLogsByDate(_todayDate);
    final Map<String, DailyLog> logMap = {};
    for (var log in logs) {
      logMap[log.mealPeriod] = log;
    }
    if (!mounted) return;
    setState(() {
      _todayLogs = logMap;
      _isLoading = false;
    });
  }

  Future<void> _recordLog(String periodKey, double percentage, String option) async {
    final log = DailyLog(
      date: _todayDate,
      mealPeriod: periodKey,
      optionChosen: option,
      percentage: percentage,
    );
    await DBHelper.saveLog(log);
    await _loadTodayLogs();
  }

  double _calculateDayScore() {
    if (_todayLogs.isEmpty) return 0.0;
    double total = 0.0;
    _todayLogs.forEach((key, log) {
      total += log.percentage;
    });
    return (total / _periods.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    double dayScore = _calculateDayScore();

    return Scaffold(
      appBar: AppBar(title: const Text('Hoje')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Card de Progresso do Dia
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meta do Dia',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${dayScore.toStringAsFixed(0)}% Concluído',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: dayScore / 100,
                                strokeWidth: 6,
                                backgroundColor: Colors.grey[300],
                              ),
                            ),
                            Text(
                              '${_todayLogs.length}/${_periods.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Refeições',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Lista de Refeições do Dia
                ..._periods.map((p) {
                  final log = _todayLogs[p['key']];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        p['label']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Horário: ${p['time']}'),
                      trailing: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.check_circle,
                                color: log?.percentage == 1.0 ? Colors.green : Colors.grey[300],
                              ),
                              onPressed: () => _recordLog(p['key']!, 1.0, 'A'),
                              tooltip: 'Comi tudo (100%)',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.pie_chart,
                                color: log?.percentage == 0.5 ? Colors.orange : Colors.grey[300],
                              ),
                              onPressed: () => _recordLog(p['key']!, 0.5, 'A'),
                              tooltip: 'Comi metade (50%)',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.cancel,
                                color: log?.percentage == 0.0 ? Colors.red : Colors.grey[300],
                              ),
                              onPressed: () => _recordLog(p['key']!, 0.0, 'A'),
                              tooltip: 'Não comi (0%)',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

// ==========================================
// 2. TELA "CARDÁPIO & RECEITAS" (OPÇÃO A / B)
// ==========================================
class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  String _selectedPeriod = 'cafe';
  String _selectedOption = 'A';

  final List<Map<String, String>> _periodOptions = [
    {'key': 'cafe', 'label': 'Café'},
    {'key': 'almoco', 'label': 'Almoço'},
    {'key': 'lanche', 'label': 'Lanche'},
    {'key': 'jantar', 'label': 'Jantar'},
    {'key': 'ceia', 'label': 'Ceia'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receitas & Dieta')),
      body: Column(
        children: [
          // Seletor de Período
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _periodOptions.map((p) {
                bool isSelected = p['key'] == _selectedPeriod;
                return ChoiceChip(
                  label: Text(p['label']!),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedPeriod = p['key']!);
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // Seletor Opção A / Opção B
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'A', label: Text('Opção A')),
                ButtonSegment(value: 'B', label: Text('Opção B')),
              ],
              selected: {_selectedOption},
              onSelectionChanged: (Set<String> selection) {
                setState(() => _selectedOption = selection.first);
              },
            ),
          ),
          // Exibição do Cardápio Selecionado
          Expanded(
            child: FutureBuilder<List<Meal>>(
              future: DBHelper.getMealsByPeriod(_selectedPeriod),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Erro ao carregar o cardápio:\n${snapshot.error}'),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final meals = snapshot.data!;
                if (meals.isEmpty) {
                  return const Center(child: Text('Nenhuma refeição encontrada.'));
                }
                final meal = meals.firstWhere(
                  (m) => m.option == _selectedOption,
                  orElse: () => meals.first,
                );

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      meal.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          avatar: const Icon(Icons.local_fire_department, size: 16),
                          label: Text('${meal.minCalories}-${meal.maxCalories} kcal'),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: const Icon(Icons.fitness_center, size: 16),
                          label: Text('${meal.minProtein}-${meal.maxProtein}g Proteína'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Ingredientes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(meal.ingredients, style: const TextStyle(height: 1.4)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Modo de Preparo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(meal.instructions, style: const TextStyle(height: 1.4)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. TELA "DISCIPLINA & HISTÓRICO"
// ==========================================
class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  double _weeklyScore = 0.0;
  int _totalLogs = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await DBHelper.getWeeklyStats();
    if (!mounted) return;
    setState(() {
      _weeklyScore = stats['percentage'];
      _totalLogs = stats['totalLogs'];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evolução & Disciplina')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                // Sem isso, o puxar-para-atualizar não funciona com lista curta no Android.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.workspace_premium, size: 48, color: Colors.amber),
                          const SizedBox(height: 12),
                          const Text(
                            'Consistência Semanal',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_weeklyScore.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_totalLogs refeições registradas nos últimos 7 dias.',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}