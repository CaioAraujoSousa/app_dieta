import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/meal.dart';
import '../models/daily_log.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'dieta_massa.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE meals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            period TEXT,
            option TEXT,
            title TEXT,
            time TEXT,
            ingredients TEXT,
            instructions TEXT,
            minCalories INTEGER,
            maxCalories INTEGER,
            minProtein INTEGER,
            maxProtein INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE daily_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            mealPeriod TEXT,
            optionChosen TEXT,
            percentage REAL
          )
        ''');

        await _seedMeals(db);
      },
    );
  }

  static Future<void> _seedMeals(Database db) async {
    List<Meal> initialMeals = [
      // Café da Manhã
      Meal(
        period: 'cafe',
        option: 'A',
        title: 'Mingau, ovos e fruta',
        time: '07:30',
        ingredients: '- 50 g de aveia\n- 200 ml de leite zero lactose\n- 1 banana média\n- 2 ovos\n- 10 g de pasta de amendoim',
        instructions: '1. Misture a aveia com o leite e cozinhe em fogo baixo, mexendo até engrossar.\n2. Coloque a banana fatiada por cima e misture a pasta de amendoim.\n3. Prepare os dois ovos separadamente, cozidos ou mexidos.',
        minCalories: 520, maxCalories: 580, minProtein: 23, maxProtein: 27,
      ),
      Meal(
        period: 'cafe',
        option: 'B',
        title: 'Pão, ovos, leite e fruta',
        time: '07:30',
        ingredients: '- 2 fatias de pão (50-60 g)\n- 2 ovos mexidos ou cozidos\n- 200 ml de leite zero lactose\n- 1 porção de mamão (150g) ou 1 banana\n- 10 g de pasta de amendoim',
        instructions: 'Coma os ovos separadamente, beba o leite e consuma a fruta como acompanhamento.',
        minCalories: 450, maxCalories: 550, minProtein: 22, maxProtein: 28,
      ),
      // Almoço
      Meal(
        period: 'almoco',
        option: 'A',
        title: 'Arroz, feijão e frango',
        time: '12:00',
        ingredients: '- 200 g de arroz cozido\n- 150 g de feijão cozido com caldo\n- 100 g de frango cozido/grelhado\n- 150 g de vegetais (cenoura, couve)\n- 1 colher de chá de óleo (5 g)',
        instructions: 'Coloque o arroz e feijão no prato, acrescente o frango e vegetais. Tempere com alho, cebola e ervas.\nSobremesa: 1 laranja média ou mamão (150 g).',
        minCalories: 600, maxCalories: 700, minProtein: 38, maxProtein: 45,
      ),
      Meal(
        period: 'almoco',
        option: 'B',
        title: 'Arroz, feijão e ovos',
        time: '12:00',
        ingredients: '- 200 g de arroz cozido\n- 150 g de feijão cozido com caldo\n- 3 ovos\n- 150 g de vegetais\n- Até 1 colher de chá de óleo',
        instructions: 'Prepare os ovos cozidos ou mexidos e sirva com o arroz, feijão e vegetais.\nSobremesa: 1 banana, maçã ou laranja.',
        minCalories: 650, maxCalories: 750, minProtein: 30, maxProtein: 35,
      ),
      // Lanche
      Meal(
        period: 'lanche',
        option: 'A',
        title: 'Vitamina reforçada',
        time: '15:30',
        ingredients: '- 200 ml de leite zero lactose\n- 1 banana média\n- 40 g de aveia\n- 20 g de pasta de amendoim',
        instructions: 'Bata tudo no liquidificador até ficar homogêneo. Não acrescente açúcar.',
        minCalories: 450, maxCalories: 500, minProtein: 17, maxProtein: 20,
      ),
      Meal(
        period: 'lanche',
        option: 'B',
        title: 'Sanduíche com ovo',
        time: '15:30',
        ingredients: '- 2 fatias de pão (50-60 g)\n- 1 ovo\n- 10 g de pasta de amendoim\n- 200 ml de leite zero lactose\n- 1 maçã ou laranja',
        instructions: 'Faça o ovo cozido ou mexido e coloque no pão. Beba o leite e coma a fruta.',
        minCalories: 400, maxCalories: 500, minProtein: 18, maxProtein: 23,
      ),
      // Jantar
      Meal(
        period: 'jantar',
        option: 'A',
        title: 'Arroz, feijão e sardinha',
        time: '19:30',
        ingredients: '- 180 g de arroz cozido\n- 100 g de feijão cozido\n- 1 lata de sardinha (~84 g drenados)\n- 100 g de vegetais',
        instructions: 'Sirva o arroz, feijão, sardinha e vegetais. A sardinha fornece ômega-3, B12 e cálcio.\nSobremesa: 1 laranja ou mamão.',
        minCalories: 500, maxCalories: 600, minProtein: 28, maxProtein: 35,
      ),
      Meal(
        period: 'jantar',
        option: 'B',
        title: 'Arroz, feijão e ovos',
        time: '19:30',
        ingredients: '- 180 g de arroz cozido\n- 100 g de feijão cozido\n- 2 ovos\n- 100 g de vegetais\n- 1 colher de chá de óleo',
        instructions: 'Prepare os ovos cozidos ou mexidos e sirva com os demais alimentos.\nSobremesa: 1 banana ou maçã.',
        minCalories: 450, maxCalories: 550, minProtein: 22, maxProtein: 27,
      ),
      // Ceia
      Meal(
        period: 'ceia',
        option: 'A',
        title: 'Leite, fruta e pasta de amendoim',
        time: '22:00',
        ingredients: '- 200 ml de leite zero lactose\n- 1 porção de mamão (150 g) ou banana\n- 10 g de pasta de amendoim',
        instructions: 'Beba o leite, coma a fruta e consuma a pasta de amendoim.',
        minCalories: 220, maxCalories: 300, minProtein: 8, maxProtein: 10,
      ),
      Meal(
        period: 'ceia',
        option: 'B',
        title: 'Ovo, leite e fruta',
        time: '22:00',
        ingredients: '- 1 ovo cozido\n- 200 ml de leite zero lactose\n- 1 maçã pequena ou laranja',
        instructions: 'Coma o ovo cozido, beba o leite e consuma a fruta.',
        minCalories: 210, maxCalories: 260, minProtein: 13, maxProtein: 15,
      ),
    ];

    for (var meal in initialMeals) {
      await db.insert('meals', meal.toMap());
    }
  }

  static Future<List<Meal>> getMealsByPeriod(String period) async {
    final dbClient = await db;
    final res = await dbClient.query('meals', where: 'period = ?', whereArgs: [period]);
    return res.map((e) => Meal.fromMap(e)).toList();
  }

  // Cada refeição do dia tem um único registro: tocar de novo substitui o anterior.
  // (A tabela não tem UNIQUE, então só o ConflictAlgorithm.replace duplicava linhas.)
  static Future<void> saveLog(DailyLog log) async {
    final dbClient = await db;
    await dbClient.transaction((txn) async {
      await txn.delete(
        'daily_logs',
        where: 'date = ? AND mealPeriod = ?',
        whereArgs: [log.date, log.mealPeriod],
      );
      await txn.insert('daily_logs', log.toMap());
    });
  }

  static Future<List<DailyLog>> getLogsByDate(String date) async {
    final dbClient = await db;
    final res = await dbClient.query('daily_logs', where: 'date = ?', whereArgs: [date]);
    return res.map((e) => DailyLog.fromMap(e)).toList();
  }

  static Future<Map<String, dynamic>> getWeeklyStats() async {
    final dbClient = await db;

    // Hoje + os 6 dias anteriores (as datas yyyy-MM-dd comparam certo como texto).
    final String since = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 6)));

    final List<Map<String, dynamic>> res = await dbClient.query(
      'daily_logs',
      columns: ['percentage'],
      where: 'date >= ?',
      whereArgs: [since],
    );

    if (res.isEmpty) {
      return {'percentage': 0.0, 'totalLogs': 0};
    }

    double total = 0;
    for (var row in res) {
      total += (row['percentage'] as num).toDouble();
    }

    double average = (total / res.length) * 100;
    return {
      'percentage': average,
      'totalLogs': res.length,
    };
  }
}