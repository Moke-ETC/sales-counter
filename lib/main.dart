import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCie8MQ4WD6m8Lx3INRs8Dqv2_QlvJrCXk',
        appId: '1:450729365791:android:e848771a35ee48406b202a',
        messagingSenderId: '450729365791',
        projectId: 'merishiro-927ee',
        storageBucket: 'merishiro-927ee.firebasestorage.app',
      ),
    );
    runApp(const SalesApp());
  } catch (e, stack) {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text('⚠️ Firebase Error',
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('$e',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 20),
                  Text('$stack',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

// ==================== CONFIG ====================
const List<Map<String, String>> waiters = [
  {'name': 'የሮሳ', 'phone': '+251912810964'},
  {'name': 'ከድር', 'phone': '+251991590934'},
  {'name': 'አህመድ', 'phone': '+251950511508'},
  {'name': 'ይቻላል', 'phone': '+251931438831'},
];

const Map<String, String> ownerInfo = {
  'name': 'OWNER',
  'phone': '0904180455',
};

const List<Map<String, dynamic>> paymentMethods = [
  {'key': 'cash', 'label': 'ጥሬ ገንዘብ', 'icon': Icons.payments, 'color': Colors.green},
  {'key': 'cbe', 'label': 'CBE', 'icon': Icons.account_balance, 'color': Colors.purple},
  {'key': 'telebirr', 'label': 'ቴሌብር', 'icon': Icons.phone_android, 'color': Colors.lightBlue},
];

// ==================== APP ====================
class SalesApp extends StatelessWidget {
  const SalesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ሜሪ ሽሮ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ==================== SPLASH / ROUTER ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    final name = prefs.getString('waiterName');
    if (!mounted) return;

    if (role == null || name == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetupScreen()),
      );
    } else if (role == 'owner') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OwnerScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 100, color: Colors.amber),
            SizedBox(height: 20),
            Text('ሜሪ ሽሮ',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 36,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Colors.amber),
          ],
        ),
      ),
    );
  }
}

// ==================== SETUP (FIXED — ቀጥል ALWAYS VISIBLE) ====================
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? role;
  String? waiter;

  Future<void> _save() async {
    if (role == null) return;
    if (role == 'waiter' && waiter == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role!);
    await prefs.setString(
        'waiterName', role == 'owner' ? ownerInfo['name']! : waiter!);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) =>
              role == 'owner' ? const OwnerScreen() : const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.restaurant, size: 60, color: Colors.amber),
              const SizedBox(height: 10),
              const Text('ሜሪ ሽሮ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('ማዋቀር',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
              const Text('እርስዎ ማን ነዎት?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _roleCard('ባለቤት (Owner)', 'ሁሉንም ሽያጮች ይመልከቱ',
                  Icons.admin_panel_settings, role == 'owner',
                  () => setState(() {
                        role = 'owner';
                        waiter = null;
                      })),
              const SizedBox(height: 8),
              _roleCard('አስተናጋጅ (Waiter)', 'የራስዎን ሽያጭ ብቻ',
                  Icons.person, role == 'waiter',
                  () => setState(() => role = 'waiter')),
              if (role == 'waiter') ...[
                const SizedBox(height: 16),
                const Text('ስምዎን ይምረጡ:',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Scrollable waiter list
                Expanded(
                  child: ListView(
                    children: waiters
                        .map((w) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () =>
                                    setState(() => waiter = w['name']),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: waiter == w['name']
                                        ? Colors.amber.shade900
                                        : const Color(0xFF2A2A2A),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                      color: waiter == w['name']
                                          ? Colors.amber
                                          : Colors.white24,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person,
                                          color: waiter == w['name']
                                              ? Colors.black
                                              : Colors.amber),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(w['name']!,
                                                style: TextStyle(
                                                  color: waiter ==
                                                          w['name']
                                                      ? Colors.black
                                                      : Colors.white,
                                                  fontSize: 17,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                )),
                                            Text(w['phone']!,
                                                style: TextStyle(
                                                  color: waiter ==
                                                          w['name']
                                                      ? Colors.black54
                                                      : Colors.white54,
                                                  fontSize: 12,
                                                )),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ] else
                const Spacer(),
              const SizedBox(height: 12),
              // ቀጥል button always visible
              ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.black),
                label: const Text('ቀጥል',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: (role == 'owner' ||
                        (role == 'waiter' && waiter != null))
                    ? _save
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(
      String title, String sub, IconData icon, bool sel, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? Colors.amber.shade900 : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? Colors.amber : Colors.white24, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 36, color: sel ? Colors.black : Colors.amber),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: sel ? Colors.black : Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      )),
                  Text(sub,
                      style: TextStyle(
                        color: sel ? Colors.black87 : Colors.white60,
                        fontSize: 12,
                      )),
                ],
              ),
            ),
            if (sel)
              const Icon(Icons.check_circle,
                  color: Colors.black, size: 26),
          ],
        ),
      ),
    );
  }
}

// ==================== DATABASE ====================
class DB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = p.join(await getDatabasesPath(), 'meri_shiro.db');
    _db = await openDatabase(dbPath,
        version: 6, onCreate: _create, onUpgrade: _upgrade);
    return _db!;
  }

  static Future _create(Database db, int v) async {
    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        served_with TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        waiter TEXT NOT NULL,
        customer TEXT NOT NULL DEFAULT '',
        served_with TEXT NOT NULL DEFAULT '',
        is_credit INTEGER NOT NULL DEFAULT 0,
        is_paid INTEGER NOT NULL DEFAULT 1,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        timestamp TEXT NOT NULL
      )
    ''');

    final menu = [
      {'name': 'የርማል ፉል', 'price': 110.0, 'category': 'ቁርስ', 'served_with': 'ዳቦ'},
      {'name': 'ስፔሻል ፉል', 'price': 140.0, 'category': 'ቁርስ', 'served_with': 'ዳቦ'},
      {'name': 'አንጀራ ፍርፍር', 'price': 110.0, 'category': 'ቁርስ', 'served_with': 'እንጀራ'},
      {'name': 'ስፔሻል ፍርፍር', 'price': 170.0, 'category': 'ቁርስ', 'served_with': 'እንጀራ'},
      {'name': 'አንቁላል ፍርፍር', 'price': 170.0, 'category': 'ቁርስ', 'served_with': 'እንጀራ'},
      {'name': 'አንቁላል ስልስ', 'price': 170.0, 'category': 'ቁርስ', 'served_with': 'ዳቦ'},
      {'name': 'አንቁላል በስጋ', 'price': 250.0, 'category': 'ቁርስ', 'served_with': 'እንጀራ'},
      {'name': 'በያይነት', 'price': 130.0, 'category': 'ምሳ', 'served_with': 'እንጀራ'},
      {'name': 'ፓስታ በስጋ', 'price': 110.0, 'category': 'ምሳ', 'served_with': ''},
      {'name': 'ፓስታ ባትካልት', 'price': 130.0, 'category': 'ምሳ', 'served_with': ''},
      {'name': 'የርማል ድንች', 'price': 110.0, 'category': 'ምሳ', 'served_with': 'እንጀራ'},
      {'name': 'ጎመን', 'price': 130.0, 'category': 'ምሳ', 'served_with': 'እንጀራ'},
      {'name': 'ሽሮ ፋስክ', 'price': 110.0, 'category': 'ምሳ', 'served_with': 'እንጀራ'},
      {'name': 'ቲማቲም ለብለብ', 'price': 130.0, 'category': 'ምሳ', 'served_with': 'እንጀራ'},
      {'name': 'ተጋቢኖ', 'price': 150.0, 'category': 'ምሳ', 'served_with': 'እንጀራ'},
      {'name': 'ስፔሻል', 'price': 230.0, 'category': 'የፍስክ ምግብ', 'served_with': 'እንጀራ'},
      {'name': 'ጥብስ', 'price': 350.0, 'category': 'የፍስክ ምግብ', 'served_with': 'እንጀራ'},
      {'name': 'ዱለት', 'price': 300.0, 'category': 'የፍስክ ምግብ', 'served_with': 'እንጀራ'},
      {'name': 'ድንች በስጋ', 'price': 180.0, 'category': 'የፍስክ ምግብ', 'served_with': 'እንጀራ'},
      {'name': 'ሽሮ ባይባይ', 'price': 170.0, 'category': 'የፍስክ ምግብ', 'served_with': 'እንጀራ'},
      {'name': 'ሽሮ በቅቤ', 'price': 150.0, 'category': 'የፍስክ ምግብ', 'served_with': 'እንጀራ'},
      {'name': 'ቅቅል', 'price': 300.0, 'category': 'የፍስክ ምግብ', 'served_with': 'እንጀራ'},
      {'name': 'ጎመን አንጀራ', 'price': 20.0, 'category': 'ተጨማሪ', 'served_with': 'እንጀራ'},
      {'name': 'ዳቦ', 'price': 15.0, 'category': 'ተጨማሪ', 'served_with': 'ዳቦ'},
      {'name': '2 ሊትር ውሃ', 'price': 60.0, 'category': 'መጠጦች', 'served_with': ''},
      {'name': '1 ሊትር ውሃ', 'price': 40.0, 'category': 'መጠጦች', 'served_with': ''},
      {'name': '0.5 ሊትር ውሃ', 'price': 25.0, 'category': 'መጠጦች', 'served_with': ''},
      {'name': 'ለስላሳ መጠጦች', 'price': 50.0, 'category': 'መጠጦች', 'served_with': ''},
    ];
    for (var item in menu) {
      await db.insert('menu_items', item);
    }
  }

  static Future _upgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      try {
        await db.execute(
            'ALTER TABLE sales ADD COLUMN waiter TEXT NOT NULL DEFAULT ""');
      } catch (_) {}
    }
    if (oldV < 4) {
      try {
        await db.execute(
            'ALTER TABLE sales ADD COLUMN customer TEXT NOT NULL DEFAULT ""');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE sales ADD COLUMN is_credit INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE sales ADD COLUMN is_paid INTEGER NOT NULL DEFAULT 1');
      } catch (_) {}
    }
    if (oldV < 5) {
      try {
        await db.execute(
            'ALTER TABLE sales ADD COLUMN served_with TEXT NOT NULL DEFAULT ""');
      } catch (_) {}
      try {
        await db.execute(
            'ALTER TABLE menu_items ADD COLUMN served_with TEXT NOT NULL DEFAULT ""');
      } catch (_) {}
    }
    if (oldV < 6) {
      try {
        await db.execute(
            'ALTER TABLE sales ADD COLUMN payment_method TEXT NOT NULL DEFAULT "cash"');
      } catch (_) {}
    }
  }

  static Future<List<Map<String, dynamic>>> getMenu() async {
    final db = await database;
    return db.query('menu_items', orderBy: 'category, id');
  }

  static Future<int> addItem(Map<String, dynamic> item) async {
    final db = await database;
    return db.insert('menu_items', item);
  }

  static Future<void> updateItem(int id, Map<String, dynamic> item) async {
    final db = await database;
    await db.update('menu_items', item, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete('menu_items', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> saveSales(List<Map<String, dynamic>> rows) async {
    final db = await database;
    final batch = db.batch();
    for (var r in rows) {
      batch.insert('sales', r);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> updateSaleQty(int saleId, int qty) async {
    final db = await database;
    if (qty <= 0) {
      await db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
      return;
    }
    final row = await db.query('sales', where: 'id = ?', whereArgs: [saleId]);
    if (row.isEmpty) return;
    final unit = (row.first['unit_price'] as num).toDouble();
    await db.update(
      'sales',
      {'quantity': qty, 'total_price': unit * qty},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  static Future<void> deleteSale(int saleId) async {
    final db = await database;
    await db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
  }

  static Future<List<Map<String, dynamic>>> getAllSales() async {
    final db = await database;
    return db.query('sales', orderBy: 'timestamp DESC');
  }

  static Future<List<Map<String, dynamic>>> getOrdersToday() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59)
        .toIso8601String();
    return db.rawQuery('''
      SELECT customer,
             SUM(quantity) as total_qty,
             SUM(total_price) as total_revenue,
             MIN(is_paid) as all_paid,
             MIN(is_credit) as is_credit,
             MAX(timestamp) as last_time
      FROM sales
      WHERE customer != ''
        AND timestamp BETWEEN ? AND ?
      GROUP BY customer
      ORDER BY last_time DESC
    ''', [start, end]);
  }

  static Future<List<Map<String, dynamic>>> getCustomerItems(
      String customer) async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59)
        .toIso8601String();
    return db.query('sales',
        where: 'customer = ? AND timestamp BETWEEN ? AND ?',
        whereArgs: [customer, start, end],
        orderBy: 'timestamp DESC');
  }

  static Future<List<Map<String, dynamic>>> getCreditList() async {
    final db = await database;
    return db.rawQuery('''
      SELECT customer,
             SUM(total_price) as total_revenue,
             SUM(quantity) as total_qty,
             COUNT(*) as num_items,
             MAX(timestamp) as last_time,
             waiter
      FROM sales
      WHERE customer != ''
        AND is_credit = 1
        AND is_paid = 0
      GROUP BY customer
      ORDER BY last_time DESC
    ''');
  }

  static Future<void> markCustomerPaid(String customer) async {
    final db = await database;
    await db.update('sales', {'is_paid': 1},
        where: 'customer = ? AND is_credit = 1 AND is_paid = 0',
        whereArgs: [customer]);
  }
}

// ==================== CLOUD (FIRESTORE) ====================
class Cloud {
  static final _db = FirebaseFirestore.instance;

  static Future<void> pushSale(Map<String, dynamic> row) async {
    try {
      await _db.collection('sales').add({
        ...row,
        'serverTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Cloud push failed: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> allSalesTodayStream() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    return _db
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {...d.data(), 'id': d.id})
            .toList());
  }

  static Stream<List<Map<String, dynamic>>> waiterSalesTodayStream(
      String waiter) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    return _db
        .collection('sales')
        .where('waiter', isEqualTo: waiter)
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {...d.data(), 'id': d.id})
            .toList());
  }
}

// ==================== CART MODEL ====================
class CartItem {
  final int id;
  final String name;
  final String category;
  final double price;
  final String servedWith;
  int qty;
  CartItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.servedWith,
    this.qty = 0,
  });
}

// ==================== HOME SCREEN (Waiter) ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CartItem> cart = [];
  bool loading = true;
  String waiterName = '';
  final customerCtrl = TextEditingController();
  bool isCredit = false;
  String paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    customerCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    waiterName = prefs.getString('waiterName') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final rows = await DB.getMenu();
    cart = rows
        .map((r) => CartItem(
              id: r['id'] as int,
              name: r['name'] as String,
              category: r['category'] as String,
              price: (r['price'] as num).toDouble(),
              servedWith: (r['served_with'] as String?) ?? '',
            ))
        .toList();
    setState(() => loading = false);
  }

  double get subtotal => cart.fold(0.0, (s, c) => s + c.price * c.qty);
  int get totalItems => cart.fold(0, (s, c) => s + c.qty);

  int get enjeraCount => cart
      .where((c) => c.servedWith == 'እንጀራ')
      .fold(0, (s, c) => s + c.qty);

  int get breadCount =>
      cart.where((c) => c.servedWith == 'ዳቦ').fold(0, (s, c) => s + c.qty);

  int get water1L =>
      cart.where((c) => c.name == '1 ሊትር ውሃ').fold(0, (s, c) => s + c.qty);
  int get water2L =>
      cart.where((c) => c.name == '2 ሊትር ውሃ').fold(0, (s, c) => s + c.qty);
  int get water05L =>
      cart.where((c) => c.name.contains('0.5')).fold(0, (s, c) => s + c.qty);

  Map<String, List<CartItem>> get grouped {
    final map = <String, List<CartItem>>{};
    for (var c in cart) {
      map.putIfAbsent(c.category, () => []).add(c);
    }
    return map;
  }

  Future<void> _confirm() async {
    final cartRows = cart.where((c) => c.qty > 0).toList();
    if (cartRows.isEmpty) return;

    final customer = customerCtrl.text.trim();

    if (isCredit && customer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ዱቤ ለመመዝገብ የደንበኛ ስም ያስፈልጋል'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final timestamp = DateTime.now().toIso8601String();

    final rows = cartRows
        .map((c) => {
              'item_id': c.id,
              'item_name': c.name,
              'category': c.category,
              'quantity': c.qty,
              'unit_price': c.price,
              'total_price': c.price * c.qty,
              'waiter': waiterName,
              'customer': customer,
              'served_with': c.servedWith,
              'is_credit': isCredit ? 1 : 0,
              'is_paid': isCredit ? 0 : 1,
              'payment_method': isCredit ? 'credit' : paymentMethod,
              'timestamp': timestamp,
            })
        .toList();

    await DB.saveSales(rows);

    for (var r in rows) {
      Cloud.pushSale(r);
    }

    setState(() {
      for (var c in cart) c.qty = 0;
      customerCtrl.clear();
      isCredit = false;
      paymentMethod = 'cash';
    });

    if (!mounted) return;
    final payLabel = isCredit
        ? 'ዱቤ'
        : paymentMethods
            .firstWhere((p) => p['key'] == paymentMethod)['label'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ሽያጭ ተመዝግቧል ✅ ($waiterName) • $payLabel'
          '${customer.isNotEmpty ? " — $customer" : ""}',
        ),
        backgroundColor: isCredit ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedPhone = waiters
        .firstWhere((w) => w['name'] == waiterName,
            orElse: () => {'phone': ''})['phone']!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: Text('ሜሪ ሽሮ — $waiterName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_done),
            tooltip: 'ሽያጮቼ',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WaiterHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'ዛሬ ትዕዛዞች',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.credit_card),
            tooltip: 'ዱቤ ዝርዝር',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreditScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'ታሪክ',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MenuScreen()),
              );
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFF0F0F0F),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip(Icons.local_dining, 'እንጀራ', enjeraCount, Colors.amber),
                _chip(Icons.bakery_dining, 'ዳቦ', breadCount, Colors.brown),
                _chip(Icons.local_drink, '2L', water2L,
                    Colors.lightBlueAccent),
                _chip(Icons.local_drink, '1L', water1L,
                    Colors.lightBlueAccent),
                _chip(Icons.local_drink, '0.5L', water05L,
                    Colors.lightBlueAccent),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF1F1F1F),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(waiterName,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: Opacity(
                    opacity: isCredit ? 0.35 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.teal, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: paymentMethod,
                          isExpanded: true,
                          isDense: true,
                          dropdownColor: const Color(0xFF2A2A2A),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.teal, size: 18),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          items: paymentMethods
                              .map((pm) => DropdownMenuItem(
                                    value: pm['key'] as String,
                                    child: Row(
                                      children: [
                                        Icon(pm['icon'] as IconData,
                                            color: pm['color'] as Color,
                                            size: 14),
                                        const SizedBox(width: 4),
                                        Text(pm['label'] as String),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: isCredit
                              ? null
                              : (v) => setState(
                                  () => paymentMethod = v!),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => setState(() => isCredit = !isCredit),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCredit
                          ? Colors.orange.withOpacity(0.3)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCredit
                            ? Colors.orange
                            : Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.credit_card,
                            color: isCredit
                                ? Colors.orange
                                : Colors.white60,
                            size: 16),
                        const SizedBox(width: 4),
                        Text('ዱቤ',
                            style: TextStyle(
                                color: isCredit
                                    ? Colors.orange
                                    : Colors.white60,
                                fontSize: 12,
                                fontWeight: isCredit
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedPhone.isNotEmpty)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              color: const Color(0xFF1F1F1F),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  const Icon(Icons.phone, color: Colors.green, size: 12),
                  const SizedBox(width: 6),
                  Text(selectedPhone,
                      style: const TextStyle(
                          color: Colors.green, fontSize: 11)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                const Icon(Icons.person_outline,
                    color: Colors.lightBlueAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: customerCtrl,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'የደንበኛ ስም (ካልተፈለገ ባዶ)',
                        hintStyle: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                              color: Colors.lightBlueAccent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                              color: Colors.lightBlueAccent, width: 1),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: grouped.entries.expand((entry) {
                return [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    color: Colors.amber.shade900.withOpacity(0.3),
                    child: Text(entry.key,
                        style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  ...entry.value.map((item) => Card(
                        color: const Color(0xFF2A2A2A),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          title: Text(item.name,
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.white)),
                          subtitle: Row(
                            children: [
                              Text('${item.price.toStringAsFixed(0)} ብር',
                                  style: const TextStyle(
                                      color: Colors.amber, fontSize: 13)),
                              if (item.servedWith.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: item.servedWith == 'እንጀራ'
                                        ? Colors.amber.shade900
                                            .withOpacity(0.4)
                                        : Colors.brown.withOpacity(0.4),
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                  child: Text('በ${item.servedWith}',
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10)),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.redAccent, size: 30),
                                onPressed: () => setState(() {
                                  if (item.qty > 0) item.qty--;
                                }),
                              ),
                              SizedBox(
                                width: 36,
                                child: Text('${item.qty}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.greenAccent, size: 30),
                                onPressed: () =>
                                    setState(() => item.qty++),
                              ),
                            ],
                          ),
                        ),
                      )),
                ];
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF1F1F1F),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ዕቃዎች: $totalItems',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                  Text('ጠቅላላ: ${subtotal.toStringAsFixed(0)} ብር',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber)),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(isCredit ? Icons.credit_card : Icons.check,
                  size: 20),
              label: Text(isCredit ? 'በዱቤ' : 'አረጋግጥ'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                backgroundColor: isCredit ? Colors.orange : Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: totalItems == 0 ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.7), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text('$label: ',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('$value',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ==================== OWNER SCREEN ====================
class OwnerScreen extends StatelessWidget {
  const OwnerScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('ሜሪ ሽሮ — ባለቤት'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OwnerHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Cloud.allSalesTodayStream(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error,
                        color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text('ስህተት:\n${snap.error}',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.amber),
                  SizedBox(height: 16),
                  Text('በመገናኘት ላይ...',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }

          final sales = snap.data!;
          final byWaiter = <String, Map<String, dynamic>>{};
          double grandTotal = 0;
          int grandQty = 0;
          double cashT = 0, cbeT = 0, teleT = 0, creditT = 0;

          for (var s in sales) {
            final w = (s['waiter'] ?? 'unknown') as String;
            byWaiter.putIfAbsent(
                w, () => {'qty': 0, 'total': 0.0, 'count': 0});
            byWaiter[w]!['qty'] =
                (byWaiter[w]!['qty'] as int) + ((s['quantity'] ?? 0) as int);
            byWaiter[w]!['total'] =
                (byWaiter[w]!['total'] as double) +
                    ((s['total_price'] ?? 0) as num).toDouble();
            byWaiter[w]!['count'] = (byWaiter[w]!['count'] as int) + 1;

            final amt = ((s['total_price'] ?? 0) as num).toDouble();
            grandTotal += amt;
            grandQty += (s['quantity'] ?? 0) as int;

            final pm = (s['payment_method'] ?? 'cash') as String;
            if (pm == 'cbe') {
              cbeT += amt;
            } else if (pm == 'telebirr') {
              teleT += amt;
            } else if (pm == 'credit') {
              creditT += amt;
            } else {
              cashT += amt;
            }
          }

          return ListView(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                color: Colors.amber.shade900.withOpacity(0.3),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.circle,
                            color: Colors.green, size: 10),
                        SizedBox(width: 6),
                        Text('ቀጥታ (LIVE)',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${grandTotal.toStringAsFixed(0)} ብር',
                        style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 34,
                            fontWeight: FontWeight.bold)),
                    Text('$grandQty ዕቃ • ${sales.length} ሽያጭ',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                color: const Color(0xFF1F1F1F),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('በክፍያ ዘዴ:',
                        style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _payRow(Icons.payments, 'ጥሬ ገንዘብ', cashT,
                        Colors.green),
                    _payRow(Icons.account_balance, 'CBE', cbeT,
                        Colors.purple),
                    _payRow(Icons.phone_android, 'ቴሌብር', teleT,
                        Colors.lightBlue),
                    _payRow(Icons.credit_card, 'ዱቤ', creditT,
                        Colors.orange),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('በአስተናጋጅ:',
                    style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              if (byWaiter.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('ምንም ሽያጭ የለም እስካሁን',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ...byWaiter.entries.map((e) {
                return Card(
                  color: const Color(0xFF2A2A2A),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade900,
                      child: Text(
                        e.key.isEmpty ? '?' : e.key.substring(0, 1),
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(e.key,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${e.value['count']} ሽያጭ • ${e.value['qty']} ዕቃ',
                      style:
                          const TextStyle(color: Colors.white60),
                    ),
                    trailing: Text(
                      '${(e.value['total'] as double).toStringAsFixed(0)} ብር',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _payRow(IconData icon, String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white)),
          ),
          Text('${amount.toStringAsFixed(0)} ብር',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }
}

// ==================== OWNER HISTORY ====================
class OwnerHistoryScreen extends StatelessWidget {
  const OwnerHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('ሁሉም ሽያጮች'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Cloud.allSalesTodayStream(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sales = snap.data!;
          if (sales.isEmpty) {
            return const Center(
              child: Text('ምንም ሽያጭ የለም',
                  style: TextStyle(color: Colors.white70)),
            );
          }
          sales.sort((a, b) {
            final ta = (a['timestamp'] ?? '') as String;
            final tb = (b['timestamp'] ?? '') as String;
            return tb.compareTo(ta);
          });
          return ListView.builder(
            itemCount: sales.length,
            itemBuilder: (ctx, i) {
              final s = sales[i];
              final w = (s['waiter'] ?? '') as String;
              final c = (s['customer'] ?? '') as String;
              final ts =
                  DateTime.tryParse((s['timestamp'] ?? '') as String);
              final isCredit = (s['is_credit'] ?? 0) == 1;
              return Card(
                color: const Color(0xFF2A2A2A),
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.shade900,
                    child: Text(
                      w.isEmpty ? '?' : w.substring(0, 1),
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    '${s['item_name']} × ${s['quantity']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '$w${c.isNotEmpty ? " → $c" : ""}${ts != null ? " • ${DateFormat('HH:mm').format(ts)}" : ""}'
                    '${isCredit ? " • ዱቤ" : ""}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                  trailing: Text(
                    '${((s['total_price'] ?? 0) as num).toStringAsFixed(0)} ብር',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==================== WAITER CLOUD HISTORY ====================
class WaiterHistoryScreen extends StatefulWidget {
  const WaiterHistoryScreen({super.key});
  @override
  State<WaiterHistoryScreen> createState() => _WaiterHistoryScreenState();
}

class _WaiterHistoryScreenState extends State<WaiterHistoryScreen> {
  String waiter = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => waiter = prefs.getString('waiterName') ?? '');
  }

  @override
  Widget build(BuildContext context) {
    if (waiter.isEmpty) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: Text('$waiter — ሽያጮቼ'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Cloud.waiterSalesTodayStream(waiter),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sales = snap.data!;
          if (sales.isEmpty) {
            return const Center(
              child: Text('ምንም ሽያጭ የለም',
                  style: TextStyle(color: Colors.white70)),
            );
          }
          sales.sort((a, b) {
            final ta = (a['timestamp'] ?? '') as String;
            final tb = (b['timestamp'] ?? '') as String;
            return tb.compareTo(ta);
          });
          double total = 0;
          for (var s in sales) {
            total += ((s['total_price'] ?? 0) as num).toDouble();
          }
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: Colors.amber.shade900.withOpacity(0.3),
                child: Column(
                  children: [
                    Text('${total.toStringAsFixed(0)} ብር',
                        style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    Text('${sales.length} ሽያጭ',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (ctx, i) {
                    final s = sales[i];
                    final c = (s['customer'] ?? '') as String;
                    final ts = DateTime.tryParse(
                        (s['timestamp'] ?? '') as String);
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(
                          '${s['item_name']} × ${s['quantity']}',
                          style:
                              const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${c.isNotEmpty ? "$c • " : ""}${ts != null ? DateFormat('HH:mm').format(ts) : ""}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        trailing: Text(
                          '${((s['total_price'] ?? 0) as num).toStringAsFixed(0)} ብር',
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==================== ORDERS SCREEN ====================
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    orders = await DB.getOrdersToday();
    setState(() => loading = false);
  }

  void _showDetails(String customer) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (ctx) => _CustomerEditorSheet(
        customer: customer,
        onChanged: _load,
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('ዛሬ ትዕዛዞች'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(
                  child: Text('ዛሬ ምንም የደንበኛ ትዕዛዝ የለም',
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (ctx, i) {
                    final o = orders[i];
                    final isCredit =
                        (o['is_credit'] ?? 0) == 1 &&
                            (o['all_paid'] ?? 1) == 0;
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        onTap: () =>
                            _showDetails(o['customer'] as String),
                        leading: CircleAvatar(
                          backgroundColor: isCredit
                              ? Colors.orange
                              : Colors.amber.shade900,
                          child: Text(
                            (o['customer'] as String)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(o['customer'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${o['total_qty']} ዕቃ${isCredit ? " • ዱቤ" : ""}',
                          style: TextStyle(
                              color: isCredit
                                  ? Colors.orange
                                  : Colors.white60),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(o['total_revenue'] as num).toStringAsFixed(0)} ብር',
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit,
                                color: Colors.white38, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ==================== CUSTOMER EDITOR SHEET ====================
class _CustomerEditorSheet extends StatefulWidget {
  final String customer;
  final VoidCallback onChanged;
  const _CustomerEditorSheet({
    required this.customer,
    required this.onChanged,
  });
  @override
  State<_CustomerEditorSheet> createState() => _CustomerEditorSheetState();
}

class _CustomerEditorSheetState extends State<_CustomerEditorSheet> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    items = await DB.getCustomerItems(widget.customer);
    setState(() => loading = false);
  }

  Future<void> _changeQty(int saleId, int newQty) async {
    await DB.updateSaleQty(saleId, newQty);
    await _load();
    widget.onChanged();
  }

  Future<void> _deleteItem(int saleId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title:
            const Text('ማረጋገጫ', style: TextStyle(color: Colors.amber)),
        content: const Text('ይሰረዝ?',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('አይ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('አዎ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DB.deleteSale(saleId);
      await _load();
      widget.onChanged();
    }
  }

  Future<void> _addItem() async {
    final menu = await DB.getMenu();
    if (!mounted) return;
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx2, scrollCtrl) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.amber.shade900,
              child: const Text('ዕቃ ጨምር',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: menu.length,
                itemBuilder: (ctx3, i) {
                  final m = menu[i];
                  return ListTile(
                    title: Text(m['name'] as String,
                        style:
                            const TextStyle(color: Colors.white)),
                    subtitle: Text(
                        '${m['category']} • ${(m['price'] as num).toStringAsFixed(0)} ብር',
                        style: const TextStyle(color: Colors.white54)),
                    onTap: () => Navigator.pop(ctx, m),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;

    final existing = items.firstWhere(
      (it) => it['item_name'] == picked['name'],
      orElse: () => {},
    );

    if (existing.isNotEmpty) {
      final newQty = (existing['quantity'] as int) + 1;
      await _changeQty(existing['id'] as int, newQty);
    } else {
      final now = DateTime.now().toIso8601String();
      await DB.saveSales([
        {
          'item_id': picked['id'],
          'item_name': picked['name'],
          'category': picked['category'],
          'quantity': 1,
          'unit_price': picked['price'],
          'total_price': picked['price'],
          'waiter': items.isNotEmpty ? items.first['waiter'] : 'OWNER',
          'customer': widget.customer,
          'served_with': picked['served_with'] ?? '',
          'is_credit': items.isNotEmpty ? items.first['is_credit'] : 0,
          'is_paid': items.isNotEmpty ? items.first['is_paid'] : 1,
          'payment_method': items.isNotEmpty
              ? items.first['payment_method']
              : 'cash',
          'timestamp': now,
        }
      ]);
      await _load();
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = 0;
    int qty = 0;
    for (var it in items) {
      total += ((it['total_price'] ?? 0) as num).toDouble();
      qty += (it['quantity'] ?? 0) as int;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx2, scrollCtrl) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade900,
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.customer,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$qty ዕቃ',
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 12)),
                    Text('${total.toStringAsFixed(0)} ብር',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          if (loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (items.isEmpty)
            const Expanded(
              child: Center(
                child: Text('ምንም ዕቃ የለም',
                    style: TextStyle(color: Colors.white70)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: items.length,
                itemBuilder: (ctx3, i) {
                  final it = items[i];
                  final ts = DateTime.tryParse(it['timestamp'] ?? '');
                  return Card(
                    color: const Color(0xFF2A2A2A),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: ListTile(
                      title: Text('${it['item_name']}',
                          style:
                              const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        '${it['waiter']} • ${ts != null ? DateFormat('HH:mm').format(ts) : ''} • ${(it['unit_price'] as num).toStringAsFixed(0)} ብር/ዕቃ',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.redAccent, size: 26),
                            onPressed: () => _changeQty(
                                it['id'] as int,
                                (it['quantity'] as int) - 1),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text('${it['quantity']}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: Colors.greenAccent, size: 26),
                            onPressed: () => _changeQty(
                                it['id'] as int,
                                (it['quantity'] as int) + 1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent, size: 22),
                            onPressed: () =>
                                _deleteItem(it['id'] as int),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F0F0F),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('ዕቃ ጨምር'),
                    onPressed: _addItem,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CREDIT SCREEN ====================
class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});
  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  List<Map<String, dynamic>> credits = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    credits = await DB.getCreditList();
    setState(() => loading = false);
  }

  Future<void> _markPaid(String customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('ማረጋገጫ',
            style: TextStyle(color: Colors.amber)),
        content: Text('$customer ተከፍሏል?',
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('አይ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('አዎ'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DB.markCustomerPaid(customer);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    double grandTotal = 0;
    for (var c in credits) {
      grandTotal += ((c['total_revenue'] ?? 0) as num).toDouble();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('ዱቤ ዝርዝር'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.shade900.withOpacity(0.4),
                  child: Column(
                    children: [
                      const Text('ጠቅላላ ዱቤ',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 16)),
                      Text('${grandTotal.toStringAsFixed(0)} ብር',
                          style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 32,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: credits.isEmpty
                      ? const Center(
                          child: Text('ምንም ዱቤ የለም ✅',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 18)))
                      : ListView.builder(
                          itemCount: credits.length,
                          itemBuilder: (ctx, i) {
                            final c = credits[i];
                            final ts = DateTime.tryParse(
                                (c['last_time'] ?? '') as String);
                            return Card(
                              color: const Color(0xFF2A2A2A),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange,
                                  child: Text(
                                    (c['customer'] as String)
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(c['customer'] as String,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${c['num_items']} ሽያጭ • ${c['total_qty']} ዕቃ\n${ts != null ? DateFormat('MMM d, HH:mm').format(ts) : ''}',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12),
                                ),
                                isThreeLine: true,
                                trailing: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${(c['total_revenue'] as num).toStringAsFixed(0)} ብር',
                                      style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () => _markPaid(
                                          c['customer'] as String),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text('ተከፍሏል ✓',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ==================== MENU SCREEN ====================
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    items = await DB.getMenu();
    setState(() => loading = false);
  }

  void _showForm({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final priceCtrl = TextEditingController(
        text: existing != null
            ? (existing['price'] as num).toStringAsFixed(0)
            : '');
    final catCtrl =
        TextEditingController(text: existing?['category'] ?? '');
    String servedWith = (existing?['served_with'] as String?) ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(existing == null ? 'አዲስ ምግብ' : 'አርትዕ',
              style: const TextStyle(color: Colors.amber)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'ስም',
                      labelStyle: TextStyle(color: Colors.amber)),
                ),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'ዋጋ (ብር)',
                      labelStyle: TextStyle(color: Colors.amber)),
                ),
                TextField(
                  controller: catCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'ምድብ',
                      labelStyle: TextStyle(color: Colors.amber)),
                ),
                const SizedBox(height: 12),
                const Text('በምን ይቀርባል?',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('እንጀራ'),
                      selected: servedWith == 'እንጀራ',
                      selectedColor: Colors.amber,
                      onSelected: (v) => setStateDialog(
                          () => servedWith = v ? 'እንጀራ' : ''),
                    ),
                    ChoiceChip(
                      label: const Text('ዳቦ'),
                      selected: servedWith == 'ዳቦ',
                      selectedColor: Colors.brown,
                      onSelected: (v) => setStateDialog(
                          () => servedWith = v ? 'ዳቦ' : ''),
                    ),
                    ChoiceChip(
                      label: const Text('ሌላ'),
                      selected: servedWith == '',
                      selectedColor: Colors.grey,
                      onSelected: (v) =>
                          setStateDialog(() => servedWith = ''),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ሰርዝ'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                final cat =
                    catCtrl.text.trim().isEmpty ? 'ሌላ' : catCtrl.text.trim();
                if (name.isEmpty || price <= 0) return;
                if (existing == null) {
                  await DB.addItem({
                    'name': name,
                    'price': price,
                    'category': cat,
                    'served_with': servedWith,
                  });
                } else {
                  await DB.updateItem(existing['id'], {
                    'name': name,
                    'price': price,
                    'category': cat,
                    'served_with': servedWith,
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('አስቀምጥ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title:
            const Text('ማረጋገጫ', style: TextStyle(color: Colors.amber)),
        content: Text('${item['name']} ይሰረዝ?',
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('አይ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('አዎ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DB.deleteItem(item['id']);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('ምናሌ አስተዳደር'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.add, color: Colors.black),
        label:
            const Text('አዲስ ጨምር', style: TextStyle(color: Colors.black)),
        onPressed: () => _showForm(),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final sw = (item['served_with'] as String?) ?? '';
                return Card(
                  color: const Color(0xFF2A2A2A),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(item['name'] as String,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Row(
                      children: [
                        Text(
                          '${item['category']} • ${(item['price'] as num).toStringAsFixed(0)} ብር',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        if (sw.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sw == 'እንጀራ'
                                  ? Colors.amber.shade900
                                      .withOpacity(0.4)
                                  : Colors.brown.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('በ$sw',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11)),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.amber),
                          onPressed: () => _showForm(existing: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.redAccent),
                          onPressed: () => _delete(item),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==================== LOCAL HISTORY SCREEN ====================
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> sales = [];
  bool loading = true;
  String waiterName = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    waiterName = prefs.getString('waiterName') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final all = await DB.getAllSales();
    sales = all
        .where((s) => (s['waiter'] ?? '') == waiterName)
        .toList();
    setState(() => loading = false);
  }

  Future<void> _exportCsv() async {
    try {
      final allSales = await DB.getAllSales();
      final mine =
          allSales.where((s) => s['waiter'] == waiterName).toList();
      if (mine.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ምንም ሽያጭ የለም'),
              backgroundColor: Colors.orange),
        );
        return;
      }
      final rows = <List<dynamic>>[
        ['ID', 'Date', 'Time', 'Waiter', 'Customer', 'Category', 'Item', 'Served With', 'Qty', 'Unit Price', 'Total', 'Credit', 'Paid', 'Payment']
      ];
      for (var s in mine) {
        final ts = DateTime.parse(s['timestamp'] as String);
        rows.add([
          s['id'],
          DateFormat('yyyy-MM-dd').format(ts),
          DateFormat('HH:mm:ss').format(ts),
          s['waiter'],
          s['customer'] ?? '',
          s['category'],
          s['item_name'],
          s['served_with'] ?? '',
          s['quantity'],
          s['unit_price'],
          s['total_price'],
          (s['is_credit'] ?? 0) == 1 ? 'YES' : 'NO',
          (s['is_paid'] ?? 1) == 1 ? 'YES' : 'NO',
          s['payment_method'] ?? 'cash',
        ]);
      }
      final csvData = const ListToCsvConverter().convert(rows);
      final fileName =
          'waiter_${waiterName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      File file;
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        file = File('${downloadsDir.path}/$fileName');
      } else {
        final appDir = await getDatabasesPath();
        file = File('$appDir/$fileName');
      }
      await file.writeAsString(csvData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('CSV ተቀምጧል:\n${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('ስህተት: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _payLabel(String key) {
    for (var p in paymentMethods) {
      if (p['key'] == key) return p['label'] as String;
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('የኔ ሽያጮች'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
              icon: const Icon(Icons.download), onPressed: _exportCsv),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : sales.isEmpty
              ? const Center(
                  child: Text('ምንም ታሪክ የለም',
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (ctx, i) {
                    final s = sales[i];
                    final ts = DateTime.parse(s['timestamp'] as String);
                    final customer = (s['customer'] as String?) ?? '';
                    final isCredit = (s['is_credit'] ?? 0) == 1;
                    final isPaid = (s['is_paid'] ?? 1) == 1;
                    final pm =
                        (s['payment_method'] as String?) ?? 'cash';
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(
                          '${s['item_name']} × ${s['quantity']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${customer.isNotEmpty ? "$customer • " : ""}${DateFormat('MMM d, HH:mm').format(ts)}'
                          '${isCredit ? " • ዱቤ ${isPaid ? "✓" : "⏳"}" : " • ${_payLabel(pm)}"}',
                          style: TextStyle(
                              color: isCredit && !isPaid
                                  ? Colors.orangeAccent
                                  : Colors.white54,
                              fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          '${(s['total_price'] as num).toStringAsFixed(0)} ብር',
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ==================== REPORTS SCREEN ====================
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> summary = [];
  double grandTotal = 0;
  int grandQty = 0;
  int grandEnjera = 0;
  int grandBread = 0;
  double cashTotal = 0;
  double cbeTotal = 0;
  double telebirrTotal = 0;
  double creditTotal = 0;
  String waiterName = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    waiterName = prefs.getString('waiterName') ?? '';
    await _load();
  }

  Future<void> _load() async {
    final all = await DB.getAllSales();
    final rows =
        all.where((s) => (s['waiter'] ?? '') == waiterName).toList();
    double t = 0, cash = 0, cbe = 0, tele = 0, credit = 0;
    int q = 0, enj = 0, brd = 0;
    for (var r in rows) {
      final amt = ((r['total_price'] ?? 0) as num).toDouble();
      t += amt;
      q += (r['quantity'] ?? 0) as int;
      final sw = (r['served_with'] ?? '') as String;
      if (sw == 'እንጀራ') enj += (r['quantity'] ?? 0) as int;
      if (sw == 'ዳቦ') brd += (r['quantity'] ?? 0) as int;
      final pm = (r['payment_method'] ?? 'cash') as String;
      if (pm == 'cbe') {
        cbe += amt;
      } else if (pm == 'telebirr') {
        tele += amt;
      } else if (pm == 'credit') {
        credit += amt;
      } else {
        cash += amt;
      }
    }
    setState(() {
      summary = rows;
      grandTotal = t;
      grandQty = q;
      grandEnjera = enj;
      grandBread = brd;
      cashTotal = cash;
      cbeTotal = cbe;
      telebirrTotal = tele;
      creditTotal = credit;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: Text('ሪፖርት — $waiterName'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade900.withOpacity(0.3),
            child: Column(
              children: [
                const Text('የኔ ጠቅላላ ሽያጭ',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 15)),
                Text('${grandTotal.toStringAsFixed(0)} ብር',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🍽️ እንጀራ: $grandEnjera',
                        style: const TextStyle(
                            color: Colors.amber, fontSize: 13)),
                    const SizedBox(width: 12),
                    Text('🍞 ዳቦ: $grandBread',
                        style: const TextStyle(
                            color: Colors.brown, fontSize: 13)),
                    const SizedBox(width: 12),
                    Text('ዕቃዎች: $grandQty',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF1F1F1F),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('በክፍያ ዘዴ:',
                    style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _payRow(Icons.payments, 'ጥሬ ገንዘብ', cashTotal,
                    Colors.green),
                _payRow(Icons.account_balance, 'CBE', cbeTotal,
                    Colors.purple),
                _payRow(Icons.phone_android, 'ቴሌብር', telebirrTotal,
                    Colors.lightBlue),
                _payRow(Icons.credit_card, 'ዱቤ (Credit)', creditTotal,
                    Colors.orange),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('ዝርዝር:',
                style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
          ...summary.map((s) {
            final ts = DateTime.tryParse((s['timestamp'] ?? '') as String);
            return ListTile(
              title: Text('${s['item_name']} × ${s['quantity']}',
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                '${(s['customer'] as String?)?.isNotEmpty == true ? "${s['customer']} • " : ""}'
                '${ts != null ? DateFormat('MMM d, HH:mm').format(ts) : ""}',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
              ),
              trailing: Text(
                '${((s['total_price'] ?? 0) as num).toStringAsFixed(0)} ብር',
                style: const TextStyle(
                    color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _payRow(IconData icon, String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white)),
          ),
          Text('${amount.toStringAsFixed(0)} ብር',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }
}
