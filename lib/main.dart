import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Firebase Error: $e',
                style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    ));
  }
}

// ==================== CONFIG ====================
const List<Map<String, String>> defaultWaiters = [
  {'name': 'የሮሳ', 'phone': '+251912810964'},
  {'name': 'ከድር', 'phone': '+251991590934'},
  {'name': 'አህመድ', 'phone': '+251950511508'},
  {'name': 'ይቻላል', 'phone': '+251931438831'},
];

const Map<String, String> ownerInfo = {
  'name': 'OWNER',
  'phone': '0904180455',
};

const String defaultPin = '1234';

const List<Map<String, dynamic>> paymentMethods = [
  {'key': 'cash', 'label': 'ጥሬ ገንዘብ', 'short': 'ጥሬ', 'icon': Icons.payments, 'color': Colors.green},
  {'key': 'cbe', 'label': 'CBE', 'short': 'CBE', 'icon': Icons.account_balance, 'color': Colors.purple},
  {'key': 'telebirr', 'label': 'ቴሌብር', 'short': 'ቴሌ', 'icon': Icons.phone_android, 'color': Colors.lightBlue},
];

// Helper functions
String payLabel(String key) {
  for (var p in paymentMethods) {
    if (p['key'] == key) return p['label'] as String;
  }
  return key;
}

String payShort(String key) {
  for (var p in paymentMethods) {
    if (p['key'] == key) return p['short'] as String;
  }
  return key;
}

IconData payIcon(String key) {
  for (var p in paymentMethods) {
    if (p['key'] == key) return p['icon'] as IconData;
  }
  return Icons.payments;
}

Color payColor(String key) {
  for (var p in paymentMethods) {
    if (p['key'] == key) return p['color'] as Color;
  }
  return Colors.grey;
}

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
            seedColor: Colors.amber, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ==================== SPLASH ====================
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
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const SetupScreen()));
    } else if (role == 'owner') {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PinScreen(next: 'owner')));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
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

// ==================== PIN ====================
class PinScreen extends StatefulWidget {
  final String next;
  const PinScreen({super.key, required this.next});
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String input = '';

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('ownerPin') ?? defaultPin;
    if (input == stored) {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const OwnerScreen()));
    } else {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ ስህተት ፒን'), backgroundColor: Colors.red));
      setState(() => input = '');
    }
  }

  void _tap(String digit) {
    if (input.length >= 4) return;
    setState(() => input += digit);
    if (input.length == 4) _check();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.lock, color: Colors.amber, size: 60),
            const SizedBox(height: 12),
            const Text('ፒን ያስገቡ',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Default: 1234',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < input.length ? Colors.amber : Colors.white24,
                  ),
                );
              }),
            ),
            const Spacer(),
            ..._keypad(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  List<Widget> _keypad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return rows.map((row) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((d) {
            if (d.isEmpty) return const SizedBox(width: 80, height: 60);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: InkWell(
                onTap: () {
                  if (d == '⌫') {
                    if (input.isNotEmpty) {
                      setState(
                          () => input = input.substring(0, input.length - 1));
                    }
                  } else {
                    _tap(d);
                  }
                },
                child: Container(
                  width: 80,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(d,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }
}

// ==================== SETUP ====================
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? role;
  String? waiter;
  List<Map<String, dynamic>> waiters = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadWaiters();
  }

  Future<void> _loadWaiters() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('waiters').get();
      if (snap.docs.isEmpty) {
        for (var w in defaultWaiters) {
          await FirebaseFirestore.instance
              .collection('waiters')
              .doc(w['name'])
              .set(w);
        }
        waiters =
            defaultWaiters.map((w) => Map<String, dynamic>.from(w)).toList();
      } else {
        waiters = snap.docs.map((d) => d.data()).toList();
        waiters.sort((a, b) =>
            (a['name'] as String).compareTo(b['name'] as String));
      }
    } catch (e) {
      waiters =
          defaultWaiters.map((w) => Map<String, dynamic>.from(w)).toList();
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    if (role == null) return;
    if (role == 'waiter' && waiter == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role!);
    await prefs.setString('waiterName',
        role == 'owner' ? ownerInfo['name']! : waiter!);
    if (!mounted) return;
    if (role == 'owner') {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PinScreen(next: 'owner')));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
          backgroundColor: Color(0xFF1A1A1A),
          body:
              Center(child: CircularProgressIndicator(color: Colors.amber)));
    }
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.restaurant, size: 50, color: Colors.amber),
              const SizedBox(height: 8),
              const Text('ሜሪ ሽሮ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('ማዋቀር',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              const Text('እርስዎ ማን ነዎት?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _roleCard('ባለቤት (Owner)', 'ሁሉንም ሽያጮች ይመልከቱ',
                  Icons.admin_panel_settings, role == 'owner',
                  () => setState(() {
                        role = 'owner';
                        waiter = null;
                      })),
              const SizedBox(height: 6),
              _roleCard('አስተናጋጅ (Waiter)', 'የራስዎን ሽያጭ ብቻ',
                  Icons.person, role == 'waiter',
                  () => setState(() => role = 'waiter')),
              if (role == 'waiter') ...[
                const SizedBox(height: 12),
                const Text('ስምዎን ይምረጡ:',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: waiters
                        .map((w) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: InkWell(
                                onTap: () => setState(
                                    () => waiter = w['name'] as String),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: waiter == w['name']
                                        ? Colors.amber.shade900
                                        : const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: waiter == w['name']
                                            ? Colors.amber
                                            : Colors.white24,
                                        width: 2),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.person,
                                          color: waiter == w['name']
                                              ? Colors.black
                                              : Colors.amber),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(w['name'] as String,
                                            style: TextStyle(
                                                color: waiter == w['name']
                                                    ? Colors.black
                                                    : Colors.white,
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w600)),
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
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.black),
                label: const Text('ቀጥል',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sel ? Colors.amber.shade900 : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? Colors.amber : Colors.white24, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: sel ? Colors.black : Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: sel ? Colors.black : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  Text(sub,
                      style: TextStyle(
                          color: sel ? Colors.black87 : Colors.white60,
                          fontSize: 11)),
                ],
              ),
            ),
            if (sel)
              const Icon(Icons.check_circle,
                  color: Colors.black, size: 22),
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
        version: 9, onCreate: _create, onUpgrade: _upgrade);
    return _db!;
  }

  static Future _create(Database db, int v) async {
    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL, price REAL NOT NULL,
        category TEXT NOT NULL, served_with TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL, item_name TEXT NOT NULL,
        category TEXT NOT NULL, quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL, total_price REAL NOT NULL,
        waiter TEXT NOT NULL, customer TEXT NOT NULL DEFAULT '',
        served_with TEXT NOT NULL DEFAULT '',
        is_credit INTEGER NOT NULL DEFAULT 0,
        is_paid INTEGER NOT NULL DEFAULT 1,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        voided INTEGER NOT NULL DEFAULT 0,
        firestore_id TEXT NOT NULL DEFAULT '',
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
      {'name': 'አንጀራ', 'price': 20.0, 'category': 'ተጨማሪ', 'served_with': 'እንጀራ'},
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
      try { await db.execute('ALTER TABLE sales ADD COLUMN waiter TEXT NOT NULL DEFAULT ""'); } catch (_) {}
    }
    if (oldV < 4) {
      try { await db.execute('ALTER TABLE sales ADD COLUMN customer TEXT NOT NULL DEFAULT ""'); } catch (_) {}
      try { await db.execute('ALTER TABLE sales ADD COLUMN is_credit INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE sales ADD COLUMN is_paid INTEGER NOT NULL DEFAULT 1'); } catch (_) {}
    }
    if (oldV < 5) {
      try { await db.execute('ALTER TABLE sales ADD COLUMN served_with TEXT NOT NULL DEFAULT ""'); } catch (_) {}
      try { await db.execute('ALTER TABLE menu_items ADD COLUMN served_with TEXT NOT NULL DEFAULT ""'); } catch (_) {}
    }
    if (oldV < 6) {
      try { await db.execute('ALTER TABLE sales ADD COLUMN payment_method TEXT NOT NULL DEFAULT "cash"'); } catch (_) {}
    }
    if (oldV < 7) {
      try { await db.execute('ALTER TABLE sales ADD COLUMN voided INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE sales ADD COLUMN firestore_id TEXT NOT NULL DEFAULT ""'); } catch (_) {}
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

  static Future<int> saveSaleRow(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('sales', row);
  }

  static Future<void> updateSaleFirestoreId(int id, String fsId) async {
    final db = await database;
    await db.update('sales', {'firestore_id': fsId}, where: 'id = ?', whereArgs: [id]);
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
    await db.update('sales', {'quantity': qty, 'total_price': unit * qty},
        where: 'id = ?', whereArgs: [saleId]);
  }

  static Future<void> deleteSale(int saleId) async {
    final db = await database;
    await db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
  }

  static Future<List<Map<String, dynamic>>> getAllSales() async {
    final db = await database;
    return db.query('sales',
        where: 'voided = 0 AND category != "payment"',
        orderBy: 'timestamp DESC');
  }

  static Future<List<Map<String, dynamic>>> getOrdersToday() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
    return db.rawQuery('''
      SELECT customer, SUM(quantity) as total_qty,
             SUM(total_price) as total_revenue,
             MIN(is_paid) as all_paid, MIN(is_credit) as is_credit,
             MAX(timestamp) as last_time
      FROM sales WHERE customer != '' AND voided = 0 AND category != 'payment'
        AND timestamp BETWEEN ? AND ?
      GROUP BY customer ORDER BY last_time DESC
    ''', [start, end]);
  }

  static Future<List<Map<String, dynamic>>> getCustomerItems(String customer) async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
    return db.query('sales',
        where: 'customer = ? AND voided = 0 AND category != "payment" AND timestamp BETWEEN ? AND ?',
        whereArgs: [customer, start, end],
        orderBy: 'timestamp DESC');
  }
}

// ==================== CLOUD ====================
class Cloud {
  static final _db = FirebaseFirestore.instance;

  static Future<String?> pushSale(Map<String, dynamic> row) async {
    try {
      final ref = await _db.collection('sales').add({
        ...row,
        'serverTime': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5));
      return ref.id;
    } catch (e) {
      return null;
    }
  }

  static Future<void> voidSale(String fsId) async {
    try {
      await _db.collection('sales').doc(fsId).update({'voided': 1})
          .timeout(const Duration(seconds: 5));
    } catch (e) {}
  }

  static Stream<List<Map<String, dynamic>>> allSalesStream() {
    return _db.collection('sales').snapshots().map((snap) => snap.docs
        .map((d) => {...d.data(), 'id': d.id})
        .where((s) => (s['voided'] ?? 0) != 1)
        .toList());
  }

  static Stream<List<Map<String, dynamic>>> waiterSalesStream(String waiter) {
    return _db.collection('sales').snapshots().map((snap) => snap.docs
        .map((d) => {...d.data(), 'id': d.id})
        .where((s) =>
            s['waiter'] == waiter &&
            (s['voided'] ?? 0) != 1 &&
            (s['category'] ?? '') != 'payment')
        .toList());
  }

  static Stream<List<Map<String, dynamic>>> waitersStream() {
    return _db.collection('waiters').snapshots().map(
        (snap) => snap.docs.map((d) => d.data()).toList());
  }
}

// ==================== INVENTORY ====================
class Inventory {
  static final _db = FirebaseFirestore.instance;

  static Stream<Map<String, int>> stockStream() {
    return _db.collection('inventory').doc('stock').snapshots().map((snap) {
      final d = snap.data() ?? {};
      return {
        'enjera': (d['enjera'] ?? 0) as int,
        'bread': (d['bread'] ?? 0) as int,
      };
    });
  }

  static Future<Map<String, int>> getStock() async {
    try {
      final snap = await _db.collection('inventory').doc('stock').get()
          .timeout(const Duration(seconds: 5));
      final d = snap.data() ?? {};
      return {'enjera': (d['enjera'] ?? 0) as int, 'bread': (d['bread'] ?? 0) as int};
    } catch (e) {
      return {'enjera': 0, 'bread': 0};
    }
  }

  static Future<void> setStock(int enjera, int bread) async {
    try {
      await _db.collection('inventory').doc('stock').set({
        'enjera': enjera, 'bread': bread,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5));
    } catch (e) {}
  }

  static Future<void> addStock(int enjera, int bread) async {
    try {
      final updates = <String, dynamic>{};
      if (enjera != 0) updates['enjera'] = FieldValue.increment(enjera);
      if (bread != 0) updates['bread'] = FieldValue.increment(bread);
      if (updates.isEmpty) return;
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('inventory').doc('stock')
          .set(updates, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (e) {}
  }

  static Future<void> deduct(int enjeraQty, int breadQty) async {
    try {
      final updates = <String, dynamic>{};
      if (enjeraQty > 0) updates['enjera'] = FieldValue.increment(-enjeraQty);
      if (breadQty > 0) updates['bread'] = FieldValue.increment(-breadQty);
      if (updates.isEmpty) return;
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('inventory').doc('stock')
          .set(updates, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (e) {}
  }

  static Future<void> restore(int enjeraQty, int breadQty) async {
    try {
      final updates = <String, dynamic>{};
      if (enjeraQty > 0) updates['enjera'] = FieldValue.increment(enjeraQty);
      if (breadQty > 0) updates['bread'] = FieldValue.increment(breadQty);
      if (updates.isEmpty) return;
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('inventory').doc('stock')
          .set(updates, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (e) {}
  }
}

// ==================== NOTIFICATIONS LOG ====================
class NotificationsLog {
  static final _controller =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  static final List<Map<String, dynamic>> _items = [];
  static bool _loadedFromPrefs = false;

  static Future<void> _loadFromPrefs() async {
    if (_loadedFromPrefs) return;
    _loadedFromPrefs = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('notif_log') ?? [];
      for (var s in raw) {
        try {
          final parts = s.split('|||');
          if (parts.length >= 4) {
            _items.add({
              'ts': parts[0],
              'waiter': parts[1],
              'total': double.tryParse(parts[2]) ?? 0,
              'method': parts[3],
            });
          }
        } catch (_) {}
      }
      if (_items.isNotEmpty) _controller.add(List.from(_items.reversed));
    } catch (_) {}
  }

  static Stream<List<Map<String, dynamic>>> stream() {
    _loadFromPrefs();
    return _controller.stream;
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = _items
          .take(100)
          .map((e) =>
              '${e['ts']}|||${e['waiter']}|||${e['total']}|||${e['method']}')
          .toList();
      await prefs.setStringList('notif_log', raw);
    } catch (_) {}
  }

  static Future<void> add(Map<String, dynamic> sale) async {
    _items.add({
      'ts': DateTime.now().toIso8601String(),
      'waiter': sale['waiter'] ?? '',
      'total': ((sale['total_price'] ?? 0) as num).toDouble(),
      'method': sale['payment_method'] ?? 'cash',
    });
    if (!_controller.isClosed) {
      _controller.add(List.from(_items.reversed));
    }
    await _persist();
  }

  static List<Map<String, dynamic>> get all => List.from(_items.reversed);
}

// ==================== CREDIT LEDGER ====================
Map<String, Map<String, dynamic>> computeCreditLedger(
    List<Map<String, dynamic>> rows) {
  final map = <String, Map<String, dynamic>>{};

  for (var s in rows) {
    if ((s['voided'] ?? 0) == 1) continue;
    final c = ((s['customer'] ?? '') as String).trim();
    if (c.isEmpty) continue;

    final cat = (s['category'] ?? '') as String;
    final isPayment = cat == 'payment';
    final amt = ((s['total_price'] ?? 0) as num).toDouble();

    if (!isPayment && (s['is_credit'] ?? 0) != 1) continue;

    map.putIfAbsent(c, () => {
          'customer': c,
          'credit': 0.0,
          'paid': 0.0,
          'balance': 0.0,
          'order_count': 0,
          'qty': 0,
          'last_time': '',
        });

    if (isPayment) {
      map[c]!['paid'] = (map[c]!['paid'] as double) + amt.abs();
    } else {
      map[c]!['credit'] = (map[c]!['credit'] as double) + amt;
      map[c]!['order_count'] = (map[c]!['order_count'] as int) + 1;
      map[c]!['qty'] =
          (map[c]!['qty'] as int) + ((s['quantity'] ?? 0) as int);
    }

    final ts = (s['timestamp'] ?? '') as String;
    if (ts.compareTo(map[c]!['last_time'] as String) > 0) {
      map[c]!['last_time'] = ts;
    }
  }

  for (var c in map.keys) {
    map[c]!['balance'] =
        (map[c]!['credit'] as double) - (map[c]!['paid'] as double);
  }

  return map;
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
  bool _saving = false;

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
  int get enjeraCount =>
      cart.where((c) => c.servedWith == 'እንጀራ').fold(0, (s, c) => s + c.qty);
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
    if (_saving) return;
    final cartRows = cart.where((c) => c.qty > 0).toList();
    if (cartRows.isEmpty) return;

    final customer = customerCtrl.text.trim();

    if (isCredit && customer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ዱቤ ለመመዝገብ የደንበኛ ስም ያስፈልጋል'),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _saving = true);

    final wasCredit = isCredit;
    final wasPayment = paymentMethod;
    final enjDeduct = enjeraCount;
    final brdDeduct = breadCount;
    final timestamp = DateTime.now().toIso8601String();

    final localIds = <int, Map<String, dynamic>>{};
    for (var c in cartRows) {
      final row = {
        'item_id': c.id,
        'item_name': c.name,
        'category': c.category,
        'quantity': c.qty,
        'unit_price': c.price,
        'total_price': c.price * c.qty,
        'waiter': waiterName,
        'customer': customer,
        'served_with': c.servedWith,
        'is_credit': wasCredit ? 1 : 0,
        'is_paid': wasCredit ? 0 : 1,
        'payment_method': wasCredit ? 'credit' : wasPayment,
        'voided': 0,
        'timestamp': timestamp,
      };
      try {
        final localId = await DB.saveSaleRow({...row, 'firestore_id': ''});
        localIds[localId] = row;
      } catch (_) {}
    }

    setState(() {
      for (var c in cart) c.qty = 0;
      customerCtrl.clear();
      isCredit = false;
      paymentMethod = 'cash';
      _saving = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'ሽያጭ ተመዝግቧል ✅ ($waiterName)${customer.isNotEmpty ? " — $customer" : ""}'),
      backgroundColor: wasCredit ? Colors.orange : Colors.green,
      duration: const Duration(seconds: 2),
    ));

    Future.microtask(() async {
      for (var entry in localIds.entries) {
        try {
          final fsId = await Cloud.pushSale(entry.value);
          if (fsId != null) {
            await DB.updateSaleFirestoreId(entry.key, fsId);
          }
        } catch (_) {}
      }
      try {
        await Inventory.deduct(enjDeduct, brdDeduct);
      } catch (_) {}
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const SetupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: Text('ሜሪ ሽሮ — $waiterName'),
        actions: [
          IconButton(
              icon: const Icon(Icons.cloud_done),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WaiterHistoryScreen()))),
          IconButton(
              icon: const Icon(Icons.receipt_long),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OrdersScreen()))),
          IconButton(
              icon: const Icon(Icons.credit_card),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreditScreen()))),
          IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()))),
          IconButton(
              icon: const Icon(Icons.restaurant_menu),
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MenuScreen()));
                _load();
              }),
          IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()))),
          IconButton(icon: const Icon(Icons.settings), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<Map<String, int>>(
            stream: Inventory.stockStream(),
            builder: (ctx, snap) {
              final stock = snap.data ?? {'enjera': 0, 'bread': 0};
              final enjeraLeft = (stock['enjera'] ?? 0) - enjeraCount;
              final breadLeft = (stock['bread'] ?? 0) - breadCount;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: const Color(0xFF0A0A0A),
                child: Row(
                  children: [
                    _stockChip('🍽️ እንጀራ', enjeraLeft, Colors.amber),
                    const SizedBox(width: 8),
                    _stockChip('🍞 ዳቦ', breadLeft, Colors.brown),
                  ],
                ),
              );
            },
          ),
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
                _chip(Icons.local_drink, '2L', water2L, Colors.lightBlueAccent),
                _chip(Icons.local_drink, '1L', water1L, Colors.lightBlueAccent),
                _chip(Icons.local_drink, '0.5L', water05L, Colors.lightBlueAccent),
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
                        border: Border.all(color: Colors.amber, width: 1)),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.amber, size: 16),
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
                          border: Border.all(color: Colors.teal, width: 1)),
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
                              : (v) => setState(() => paymentMethod = v!),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => setState(() => isCredit = !isCredit),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCredit
                          ? Colors.orange.withOpacity(0.3)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: isCredit ? Colors.orange : Colors.white24,
                          width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.credit_card,
                            color: isCredit ? Colors.orange : Colors.white60,
                            size: 16),
                        const SizedBox(width: 4),
                        Text('ዱቤ',
                            style: TextStyle(
                                color: isCredit ? Colors.orange : Colors.white60,
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
                      style: const TextStyle(color: Colors.white, fontSize: 13),
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
                                color: Colors.lightBlueAccent)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                                color: Colors.lightBlueAccent, width: 1)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                        ? Colors.amber.shade900.withOpacity(0.4)
                                        : Colors.brown.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(3),
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
                                onPressed: () => setState(() => item.qty++),
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
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Icon(isCredit ? Icons.credit_card : Icons.check, size: 20),
              label: Text(_saving ? '...' : (isCredit ? 'በዱቤ' : 'አረጋግጥ')),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: isCredit ? Colors.orange : Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: (totalItems == 0 || _saving) ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockChip(String label, int count, Color color) {
    final isZero = count <= 0;
    final isLow = count > 0 && count <= 5;
    final displayColor =
        isZero ? Colors.red : (isLow ? Colors.orange : color);
    final icon = isZero ? '❌' : (isLow ? '⚠️' : '✅');
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: displayColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: displayColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: displayColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Text('$count',
                style: TextStyle(
                    color: displayColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
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
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

// ==================== PAYMENT BADGE WIDGET ====================
Widget paymentBadge(String method) {
  final color = payColor(method);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(payIcon(method), color: color, size: 12),
        const SizedBox(width: 4),
        Text(payLabel(method),
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

// ==================== OWNER SCREEN ====================
class OwnerScreen extends StatefulWidget {
  const OwnerScreen({super.key});
  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> {
  int _lastCount = -1;
  int _lastNotifCount = 0;
  bool _initialized = false;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const SetupScreen()));
  }

  void _playAlert() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
  }

  Future<void> _exportCsv() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('sales')
          .orderBy('timestamp', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));
      if (snap.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('ምንም ሽያጭ የለም'),
            backgroundColor: Colors.orange));
        return;
      }
      final rows = <List<dynamic>>[
        ['Date', 'Time', 'Waiter', 'Customer', 'Category', 'Item', 'Served With', 'Qty', 'Unit Price', 'Total', 'Credit', 'Paid', 'Payment', 'Voided']
      ];
      for (var d in snap.docs) {
        final s = d.data();
        final ts = DateTime.tryParse((s['timestamp'] ?? '') as String);
        rows.add([
          ts != null ? DateFormat('yyyy-MM-dd').format(ts) : '',
          ts != null ? DateFormat('HH:mm:ss').format(ts) : '',
          s['waiter'] ?? '',
          s['customer'] ?? '',
          s['category'] ?? '',
          s['item_name'] ?? '',
          s['served_with'] ?? '',
          s['quantity'] ?? 0,
          s['unit_price'] ?? 0,
          s['total_price'] ?? 0,
          (s['is_credit'] ?? 0) == 1 ? 'YES' : 'NO',
          (s['is_paid'] ?? 1) == 1 ? 'YES' : 'NO',
          s['payment_method'] ?? 'cash',
          (s['voided'] ?? 0) == 1 ? 'YES' : 'NO',
        ]);
      }
      final csv = const ListToCsvConverter().convert(rows);
      final name =
          'all_sales_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      File file;
      final dl = Directory('/storage/emulated/0/Download');
      if (await dl.exists()) {
        file = File('${dl.path}/$name');
      } else {
        final appDir = await getDatabasesPath();
        file = File('$appDir/$name');
      }
      await file.writeAsString(csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('CSV: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ስህተት: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('ሜሪ ሽሮ — ባለቤት'),
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: NotificationsLog.stream(),
            builder: (ctx, snap) {
              final count = snap.data?.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    tooltip: 'ማሳወቂያዎች',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 16, minHeight: 16),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'CSV አውጣ',
              onPressed: _exportCsv),
          IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: '7 ቀን ሪፖርት',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WeeklyReportScreen()))),
          IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'አስተናጋጆች',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WaitersScreen()))),
          IconButton(
              icon: const Icon(Icons.inventory),
              tooltip: 'Stock አስተካክል',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StockManageScreen()))),
          IconButton(icon: const Icon(Icons.settings), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          StreamBuilder<Map<String, int>>(
            stream: Inventory.stockStream(),
            builder: (ctx, snap) {
              final stock = snap.data ?? {'enjera': 0, 'bread': 0};
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: const Color(0xFF0A0A0A),
                child: Row(
                  children: [
                    _stockChip('🍽️ እንጀራ', stock['enjera'] ?? 0, Colors.amber),
                    const SizedBox(width: 8),
                    _stockChip('🍞 ዳቦ', stock['bread'] ?? 0, Colors.brown),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Cloud.allSalesStream(),
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('ስህተት: ${snap.error}',
                          style: const TextStyle(color: Colors.red)),
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
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                final all = snap.data!;
                final sales = all.where((s) {
                  if ((s['category'] ?? '') == 'payment') return false;
                  final ts = DateTime.tryParse((s['timestamp'] ?? '') as String);
                  return ts != null && ts.isAfter(todayStart);
                }).toList();

                // Sort newest first
                sales.sort((a, b) =>
                    ((b['timestamp'] ?? '') as String)
                        .compareTo((a['timestamp'] ?? '') as String));

                // Detect new sale → notify
                if (_initialized && sales.length > _lastCount) {
                  final diff = sales.length - _lastCount;
                  for (var i = 0; i < diff && i < sales.length; i++) {
                    NotificationsLog.add(sales[i]);
                  }
                  final newest = sales.first;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _playAlert();
                    final amt =
                        ((newest['total_price'] ?? 0) as num).toDouble();
                    final w = newest['waiter'] ?? '';
                    final pm = newest['payment_method'] ?? 'cash';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          '🔔 አዲስ ሽያጭ: $w • ${amt.toStringAsFixed(0)} ብር • ${payLabel(pm)}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ));
                  });
                }
                _initialized = true;
                _lastCount = sales.length;

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
                  byWaiter[w]!['total'] = (byWaiter[w]!['total'] as double) +
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
                              Icon(Icons.circle, color: Colors.green, size: 10),
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
                          _payRow(Icons.payments, 'ጥሬ ገንዘብ', cashT, Colors.green),
                          _payRow(Icons.account_balance, 'CBE', cbeT, Colors.purple),
                          _payRow(Icons.phone_android, 'ቴሌብር', teleT, Colors.lightBlue),
                          _payRow(Icons.credit_card, 'ዱቤ', creditT, Colors.orange),
                        ],
                      ),
                    ),
                    // Per-waiter cards
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
                                  const TextStyle(color: Colors.white60)),
                          trailing: Text(
                              '${(e.value['total'] as double).toStringAsFixed(0)} ብር',
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                        ),
                      );
                    }),
                    // Live feed of latest 20 sales
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('የቅርብ ሽያጮች:',
                          style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                    ...sales.take(20).map((s) {
                      final ts =
                          DateTime.tryParse((s['timestamp'] ?? '') as String);
                      final pm = (s['payment_method'] ?? 'cash') as String;
                      return Card(
                        color: const Color(0xFF2A2A2A),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade900,
                            radius: 18,
                            child: Text(
                              ((s['waiter'] ?? '?') as String)
                                  .substring(0, 1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                              '${s['item_name']} × ${s['quantity']}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${s['waiter']}${ts != null ? " • ${DateFormat('HH:mm').format(ts)}" : ""}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 11),
                                ),
                                const SizedBox(width: 8),
                                if ((s['is_credit'] ?? 0) == 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.orange.withOpacity(0.2),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      border: Border.all(
                                          color: Colors.orange, width: 1),
                                    ),
                                    child: const Text('ዱቤ',
                                        style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  )
                                else
                                  paymentBadge(pm),
                              ],
                            ),
                          ),
                          trailing: Text(
                              '${((s['total_price'] ?? 0) as num).toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockChip(String label, int count, Color color) {
    final isZero = count <= 0;
    final isLow = count > 0 && count <= 5;
    final displayColor = isZero ? Colors.red : (isLow ? Colors.orange : color);
    final icon = isZero ? '❌' : (isLow ? '⚠️' : '✅');
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: displayColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: displayColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: displayColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Text('$count',
                style: TextStyle(
                    color: displayColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
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
              child:
                  Text(label, style: const TextStyle(color: Colors.white))),
          Text('${amount.toStringAsFixed(0)} ብር',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}

// ==================== NOTIFICATIONS SCREEN ====================
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('ማሳወቂያዎች'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationsLog.stream(),
        builder: (ctx, snap) {
          final items = snap.data ?? NotificationsLog.all;
          if (items.isEmpty) {
            return const Center(
              child: Text('ምንም ማሳወቂያ የለም',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final n = items[i];
              final ts = DateTime.tryParse((n['ts'] ?? '') as String);
              final method = (n['method'] ?? 'cash') as String;
              final color = payColor(method);
              return Card(
                color: const Color(0xFF2A2A2A),
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(payIcon(method),
                        color: Colors.white, size: 20),
                  ),
                  title: Text(
                    '${n['waiter']} — ${(n['total'] as double).toStringAsFixed(0)} ብር',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${payLabel(method)}${ts != null ? " • ${DateFormat('MMM d, HH:mm').format(ts)}" : ""}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
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

// ==================== CREDIT SCREEN ====================
class CreditScreen extends StatelessWidget {
  const CreditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('ዱቤ ዝርዝር'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Cloud.allSalesStream(),
        builder: (ctxS, snapS) {
          if (snapS.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('ስህተት: ${snapS.error}',
                    style: const TextStyle(color: Colors.red)),
              ),
            );
          }
          if (!snapS.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }
          final rows = snapS.data!;
          final ledger = computeCreditLedger(rows);
          final list = ledger.values
              .where((c) => (c['balance'] as double) > 0.01)
              .toList();
          list.sort((a, b) => (b['last_time'] as String)
              .compareTo(a['last_time'] as String));

          double grandCredit = 0, grandPaid = 0, grandBalance = 0;
          for (var c in ledger.values) {
            grandCredit += (c['credit'] as double);
            grandPaid += (c['paid'] as double);
            grandBalance += (c['balance'] as double);
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: Colors.orange.shade900.withOpacity(0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCol('ጠቅላላ ዱቤ', grandCredit, Colors.orangeAccent),
                    _statCol('የተከፈለ', grandPaid, Colors.green),
                    _statCol('ቀሪ', grandBalance, Colors.amber, big: true),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Text('ምንም ዱቤ የለም ✅',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 18)))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final c = list[i];
                          final balance = c['balance'] as double;
                          final credit = c['credit'] as double;
                          final paid = c['paid'] as double;
                          return Card(
                            color: const Color(0xFF2A2A2A),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerLedgerScreen(
                                      customer: c['customer'] as String),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
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
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(c['customer'] as String,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          const SizedBox(height: 6),
                                          Text(
                                            'ዱቤ: ${credit.toStringAsFixed(0)} ብር',
                                            style: const TextStyle(
                                                color: Colors.orangeAccent,
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'ተከፈለ: ${paid.toStringAsFixed(0)} ብር',
                                            style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Text('ቀሪ',
                                            style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10)),
                                        Text(
                                            '${balance.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                color: Colors.amber,
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 22)),
                                        const Text('ብር',
                                            style: TextStyle(
                                                color: Colors.white38,
                                                fontSize: 10)),
                                      ],
                                    ),
                                  ],
                                ),
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

  Widget _statCol(String label, double amount, Color color,
      {bool big = false}) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
        const SizedBox(height: 4),
        Text('${amount.toStringAsFixed(0)}',
            style: TextStyle(
                color: color,
                fontSize: big ? 26 : 20,
                fontWeight: FontWeight.bold)),
        const Text('ብር',
            style: TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

// ==================== CUSTOMER LEDGER ====================
class CustomerLedgerScreen extends StatefulWidget {
  final String customer;
  const CustomerLedgerScreen({super.key, required this.customer});
  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  String get customer => widget.customer;

  Future<void> _showPaymentDialog(double balance) async {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String payMethod = 'cash';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('💰 ክፍያ መዝግብ',
              style: TextStyle(color: Colors.amber)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('ለ $customer\nቀሪ: ${balance.toStringAsFixed(0)} ብር',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.green)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () =>
                          amtCtrl.text = balance.toStringAsFixed(0),
                      child: Text('ሙሉ ${balance.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('የተቀበለው:',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: paymentMethods.map((pm) {
                    final sel = payMethod == pm['key'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: () => setStateDialog(
                              () => payMethod = pm['key'] as String),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? (pm['color'] as Color).withOpacity(0.25)
                                  : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: sel
                                      ? pm['color'] as Color
                                      : Colors.white24,
                                  width: sel ? 2 : 1),
                            ),
                            child: Column(
                              children: [
                                Icon(pm['icon'] as IconData,
                                    color: sel
                                        ? pm['color'] as Color
                                        : Colors.white60,
                                    size: 18),
                                const SizedBox(height: 2),
                                Text(pm['label'] as String,
                                    style: TextStyle(
                                        color: sel
                                            ? Colors.white
                                            : Colors.white60,
                                        fontSize: 10,
                                        fontWeight: sel
                                            ? FontWeight.bold
                                            : FontWeight.normal)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'ማስታወሻ (አማራጭ)',
                    labelStyle:
                        TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ሰርዝ'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final amount = double.tryParse(amtCtrl.text.trim()) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('ትክክለኛ ቁጥር ያስገቡ'),
                      backgroundColor: Colors.orange));
                  return;
                }
                final prefs = await SharedPreferences.getInstance();
                final waiter =
                    prefs.getString('waiterName') ?? ownerInfo['name']!;
                final timestamp = DateTime.now().toIso8601String();
                final note = noteCtrl.text.trim();
                final row = {
                  'item_id': -1,
                  'item_name': note.isNotEmpty
                      ? '💰 ክፍያ — $note'
                      : '💰 ክፍያ ተቀበለ',
                  'category': 'payment',
                  'quantity': 1,
                  'unit_price': -amount,
                  'total_price': -amount,
                  'waiter': waiter,
                  'customer': customer.trim(),
                  'served_with': '',
                  'is_credit': 0,
                  'is_paid': 1,
                  'payment_method': payMethod,
                  'voided': 0,
                  'timestamp': timestamp,
                };
                try {
                  final localId =
                      await DB.saveSaleRow({...row, 'firestore_id': ''});
                  if (ctx.mounted) Navigator.pop(ctx, true);
                  Future.microtask(() async {
                    try {
                      final fsId = await Cloud.pushSale(row);
                      if (fsId != null) {
                        await DB.updateSaleFirestoreId(localId, fsId);
                      }
                    } catch (_) {}
                  });
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx, false);
                }
              },
              child: const Text('አስቀምጥ',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ ክፍያ ተመዝግቧል'),
          backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: Text(customer),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Cloud.allSalesStream(),
        builder: (ctxS, snapS) {
          if (snapS.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('ስህተት: ${snapS.error}',
                    style: const TextStyle(color: Colors.red)),
              ),
            );
          }
          if (!snapS.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapS.data!
              .where((s) =>
                  ((s['customer'] ?? '') as String).trim() ==
                  customer.trim())
              .toList();

          double credit = 0, paid = 0;
          for (var s in all) {
            final cat = (s['category'] ?? '') as String;
            final amt = ((s['total_price'] ?? 0) as num).toDouble();
            if (cat == 'payment') {
              paid += amt.abs();
            } else if ((s['is_credit'] ?? 0) == 1) {
              credit += amt;
            }
          }
          final balance = credit - paid;

          final history = <Map<String, dynamic>>[];
          for (var s in all) {
            final cat = (s['category'] ?? '') as String;
            final isPayment = cat == 'payment';
            if (!isPayment && (s['is_credit'] ?? 0) != 1) continue;
            history.add({
              'kind': isPayment ? 'payment' : 'sale',
              'timestamp': s['timestamp'] ?? '',
              'amount': ((s['total_price'] ?? 0) as num).toDouble().abs(),
              'label': isPayment
                  ? (s['item_name'] ?? '💰 ክፍያ')
                  : '${s['item_name']} × ${s['quantity']}',
              'by': s['waiter'] ?? '',
              'payment_method': s['payment_method'] ?? 'cash',
            });
          }
          history.sort((a, b) => (b['timestamp'] as String)
              .compareTo(a['timestamp'] as String));

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1F1F1F),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCol('ጠቅላላ ዱቤ', credit, Colors.orangeAccent),
                    _statCol('የተከፈለ', paid, Colors.green),
                    _statCol('ቀሪ', balance, Colors.amber, big: true),
                  ],
                ),
              ),
              if (balance > 0.01)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payments, color: Colors.white),
                    label: const Text('💰 ክፍያ መዝግብ',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () => _showPaymentDialog(balance),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ታሪክ:',
                      style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: history.isEmpty
                    ? const Center(
                        child: Text('ምንም ታሪክ የለም',
                            style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (ctx, i) {
                          final h = history[i];
                          final isPayment = h['kind'] == 'payment';
                          final ts = DateTime.tryParse(
                              h['timestamp'] as String);
                          final pm =
                              h['payment_method'] as String? ?? 'cash';
                          return Card(
                            color: const Color(0xFF2A2A2A),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 3),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPayment
                                    ? Colors.green.shade900
                                    : Colors.orange.shade900,
                                child: Icon(
                                    isPayment
                                        ? Icons.payments
                                        : Icons.shopping_bag,
                                    color: Colors.white,
                                    size: 20),
                              ),
                              title: Text(h['label'] as String,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      '${h['by']}${ts != null ? " • ${DateFormat('MMM d, HH:mm').format(ts)}" : ""}',
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11),
                                    ),
                                    const SizedBox(width: 8),
                                    paymentBadge(pm),
                                  ],
                                ),
                              ),
                              trailing: Text(
                                '${isPayment ? "-" : "+"}${(h['amount'] as double).toStringAsFixed(0)}',
                                style: TextStyle(
                                    color: isPayment
                                        ? Colors.green
                                        : Colors.orangeAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17),
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

  Widget _statCol(String label, double amount, Color color,
      {bool big = false}) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
        const SizedBox(height: 4),
        Text('${amount.toStringAsFixed(0)}',
            style: TextStyle(
                color: color,
                fontSize: big ? 26 : 20,
                fontWeight: FontWeight.bold)),
        const Text('ብር',
            style: TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

// ==================== STOCK MANAGE ====================
class StockManageScreen extends StatefulWidget {
  const StockManageScreen({super.key});
  @override
  State<StockManageScreen> createState() => _StockManageScreenState();
}

class _StockManageScreenState extends State<StockManageScreen> {
  final enjeraCtrl = TextEditingController();
  final breadCtrl = TextEditingController();
  int currentEnjera = 0;
  int currentBread = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    enjeraCtrl.dispose();
    breadCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final stock = await Inventory.getStock();
    if (!mounted) return;
    setState(() {
      currentEnjera = stock['enjera'] ?? 0;
      currentBread = stock['bread'] ?? 0;
      enjeraCtrl.text = '$currentEnjera';
      breadCtrl.text = '$currentBread';
      loading = false;
    });
  }

  Future<void> _save() async {
    final e = int.tryParse(enjeraCtrl.text.trim()) ?? 0;
    final b = int.tryParse(breadCtrl.text.trim()) ?? 0;
    await Inventory.setStock(e, b);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Stock ተቀይሯል: እንጀራ $e • ዳቦ $b'),
        backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  Future<void> _addTo() async {
    final e = int.tryParse(enjeraCtrl.text.trim()) ?? 0;
    final b = int.tryParse(breadCtrl.text.trim()) ?? 0;
    await Inventory.addStock(e, b);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ ተጨምሯል: +$e እንጀራ • +$b ዳቦ'),
        backgroundColor: Colors.green));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.amber.shade900,
          title: const Text('Stock አስተካክል')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('🍽️ እንጀራ: $currentEnjera',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text('🍞 ዳቦ: $currentBread',
                      style: const TextStyle(
                          color: Colors.brown,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('🍽️ ጠቅላላ እንጀራ:',
                style: TextStyle(color: Colors.amber, fontSize: 15)),
            const SizedBox(height: 6),
            TextField(
              controller: enjeraCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0',
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.amber)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('🍞 ጠቅላላ ዳቦ:',
                style: TextStyle(color: Colors.brown, fontSize: 15)),
            const SizedBox(height: 6),
            TextField(
              controller: breadCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0',
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.brown)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.black),
              label: const Text('ጠቅላላውን ቀይር (Reset)',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _save,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('ተጨማሪ ጨምር (Add)',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _addTo,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== WAITERS MANAGEMENT ====================
class WaitersScreen extends StatefulWidget {
  const WaitersScreen({super.key});
  @override
  State<WaitersScreen> createState() => _WaitersScreenState();
}

class _WaitersScreenState extends State<WaitersScreen> {
  void _showForm({String? existingName, String? existingPhone}) {
    final nameCtrl = TextEditingController(text: existingName ?? '');
    final phoneCtrl = TextEditingController(text: existingPhone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(existingName == null ? 'አዲስ አስተናጋጅ' : 'አርትዕ',
            style: const TextStyle(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'ስም',
                    labelStyle: TextStyle(color: Colors.amber))),
            TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'ስልክ ቁጥር',
                    labelStyle: TextStyle(color: Colors.amber))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ሰርዝ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                await FirebaseFirestore.instance
                    .collection('waiters')
                    .doc(name)
                    .set({'name': name, 'phone': phone})
                    .timeout(const Duration(seconds: 5));
                if (existingName != null && existingName != name) {
                  await FirebaseFirestore.instance
                      .collection('waiters')
                      .doc(existingName)
                      .delete()
                      .timeout(const Duration(seconds: 5));
                }
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('አስቀምጥ'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title:
            const Text('ማረጋገጫ', style: TextStyle(color: Colors.amber)),
        content: Text('$name ይሰረዝ?',
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('አይ')),
          ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('አዎ')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await FirebaseFirestore.instance
            .collection('waiters')
            .doc(name)
            .delete()
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.amber.shade900,
          title: const Text('አስተናጋጆች')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.add, color: Colors.black),
        label:
            const Text('አዲስ ጨምር', style: TextStyle(color: Colors.black)),
        onPressed: () => _showForm(),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Cloud.waitersStream(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('ስህተት: ${snap.error}',
                    style: const TextStyle(color: Colors.red)),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(
                child: Text('ምንም አስተናጋጅ የለም',
                    style: TextStyle(color: Colors.white70)));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final w = list[i];
              return Card(
                color: const Color(0xFF2A2A2A),
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber.shade900,
                    child: Text(
                        ((w['name'] ?? '?') as String).substring(0, 1),
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text((w['name'] ?? '') as String,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text((w['phone'] ?? '') as String,
                      style: const TextStyle(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.amber),
                          onPressed: () => _showForm(
                              existingName: w['name'] as String,
                              existingPhone:
                                  (w['phone'] ?? '') as String)),
                      IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.redAccent),
                          onPressed: () => _delete(w['name'] as String)),
                    ],
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

// ==================== 7-DAY REPORT ====================
class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.amber.shade900,
          title: const Text('7 ቀን ሪፖርት')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Cloud.allSalesStream(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 6));
          final sales = snap.data!.where((s) {
            if ((s['category'] ?? '') == 'payment') return false;
            final ts = DateTime.tryParse((s['timestamp'] ?? '') as String);
            return ts != null && ts.isAfter(start);
          }).toList();

          final byDay = <String, Map<String, dynamic>>{};
          for (var i = 0; i < 7; i++) {
            final d = DateTime(start.year, start.month, start.day)
                .add(Duration(days: i));
            byDay[DateFormat('yyyy-MM-dd').format(d)] = {
              'date': d,
              'total': 0.0,
              'qty': 0,
              'count': 0,
              'cash': 0.0,
              'cbe': 0.0,
              'tele': 0.0,
              'credit': 0.0,
            };
          }
          for (var s in sales) {
            final ts = DateTime.tryParse((s['timestamp'] ?? '') as String);
            if (ts == null) continue;
            final key = DateFormat('yyyy-MM-dd').format(ts);
            if (byDay.containsKey(key)) {
              final amt = ((s['total_price'] ?? 0) as num).toDouble();
              final pm = (s['payment_method'] ?? 'cash') as String;
              byDay[key]!['total'] = (byDay[key]!['total'] as double) + amt;
              byDay[key]!['qty'] =
                  (byDay[key]!['qty'] as int) + ((s['quantity'] ?? 0) as int);
              byDay[key]!['count'] = (byDay[key]!['count'] as int) + 1;
              if (pm == 'cbe') {
                byDay[key]!['cbe'] = (byDay[key]!['cbe'] as double) + amt;
              } else if (pm == 'telebirr') {
                byDay[key]!['tele'] = (byDay[key]!['tele'] as double) + amt;
              } else if (pm == 'credit') {
                byDay[key]!['credit'] =
                    (byDay[key]!['credit'] as double) + amt;
              } else {
                byDay[key]!['cash'] = (byDay[key]!['cash'] as double) + amt;
              }
            }
          }

          double grandTotal = 0;
          for (var d in byDay.values) {
            grandTotal += (d['total'] as double);
          }
          final sortedKeys = byDay.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.amber.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    const Text('የ 7 ቀን ጠቅላላ',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    Text('${grandTotal.toStringAsFixed(0)} ብር',
                        style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 30,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...sortedKeys.map((k) {
                final d = byDay[k]!;
                final date = d['date'] as DateTime;
                final dayLabel = DateFormat('EEE, MMM d').format(date);
                final isToday = DateTime(now.year, now.month, now.day) ==
                    DateTime(date.year, date.month, date.day);
                return Card(
                  color: isToday
                      ? Colors.amber.shade900.withOpacity(0.3)
                      : const Color(0xFF2A2A2A),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(dayLabel,
                                style: TextStyle(
                                    color: isToday
                                        ? Colors.amber
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            const Spacer(),
                            Text(
                                '${(d['total'] as double).toStringAsFixed(0)} ብር',
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${d['count']} ሽያጭ • ${d['qty']} ዕቃ',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if ((d['cash'] as double) > 0)
                              _miniBadge('ጥሬ',
                                  d['cash'] as double, Colors.green),
                            if ((d['cbe'] as double) > 0)
                              _miniBadge('CBE', d['cbe'] as double,
                                  Colors.purple),
                            if ((d['tele'] as double) > 0)
                              _miniBadge('ቴሌ', d['tele'] as double,
                                  Colors.lightBlue),
                            if ((d['credit'] as double) > 0)
                              _miniBadge('ዱቤ', d['credit'] as double,
                                  Colors.orange),
                          ],
                        ),
                      ],
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

  Widget _miniBadge(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text('$label ${amount.toStringAsFixed(0)}',
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ==================== ORDERS ====================
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
      builder: (ctx) =>
          _CustomerEditorSheet(customer: customer, onChanged: _load),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load)
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
                    final isCredit = (o['is_credit'] ?? 0) == 1 &&
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
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(o['customer'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${o['total_qty']} ዕቃ${isCredit ? " • ዱቤ" : ""}',
                            style: TextStyle(
                                color: isCredit
                                    ? Colors.orange
                                    : Colors.white60)),
                        trailing: Text(
                            '${(o['total_revenue'] as num).toStringAsFixed(0)} ብር',
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    );
                  },
                ),
    );
  }
}

class _CustomerEditorSheet extends StatefulWidget {
  final String customer;
  final VoidCallback onChanged;
  const _CustomerEditorSheet(
      {required this.customer, required this.onChanged});
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
    if (newQty <= 0) {
      await _deleteItem(saleId);
      return;
    }
    final row =
        items.firstWhere((it) => it['id'] == saleId, orElse: () => {});
    if (row.isEmpty) return;
    final sw = row['served_with'] as String? ?? '';
    final oldQty = row['quantity'] as int? ?? 0;
    final diff = newQty - oldQty;

    await DB.updateSaleQty(saleId, newQty);
    await _load();
    widget.onChanged();

    try {
      if (sw == 'እንጀራ' && diff != 0) {
        await Inventory.deduct(diff, 0);
      } else if (sw == 'ዳቦ' && diff != 0) {
        await Inventory.deduct(0, diff);
      }
    } catch (_) {}
  }

  Future<void> _deleteItem(int saleId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title:
            const Text('ማረጋገጫ', style: TextStyle(color: Colors.amber)),
        content:
            const Text('ይሰረዝ?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('አይ')),
          ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('አዎ')),
        ],
      ),
    );
    if (ok == true) {
      final row = await (await DB.database)
          .query('sales', where: 'id = ?', whereArgs: [saleId]);
      if (row.isNotEmpty) {
        final fsId = row.first['firestore_id'] as String?;
        if (fsId != null && fsId.isNotEmpty) {
          try {
            await Cloud.voidSale(fsId);
          } catch (_) {}
        }
        final sw = row.first['served_with'] as String? ?? '';
        final qty = row.first['quantity'] as int? ?? 0;
        try {
          if (sw == 'እንጀራ') {
            await Inventory.restore(qty, 0);
          } else if (sw == 'ዳቦ') {
            await Inventory.restore(0, qty);
          }
        } catch (_) {}
      }
      await DB.deleteSale(saleId);
      await _load();
      widget.onChanged();
    }
  }

  Future<void> _addNewItem() async {
    final menu = await DB.getMenu();
    if (!mounted) return;

    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
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
                  const Icon(Icons.add_circle, color: Colors.black),
                  const SizedBox(width: 8),
                  const Text('ምግብ ጨምር',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: menu.length,
                itemBuilder: (ctx3, i) {
                  final m = menu[i];
                  final sw = (m['served_with'] ?? '') as String;
                  return ListTile(
                    title: Text(m['name'] as String,
                        style:
                            const TextStyle(color: Colors.white)),
                    subtitle: Row(
                      children: [
                        Text(
                            '${m['category']} • ${(m['price'] as num).toStringAsFixed(0)} ብር',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        if (sw.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sw == 'እንጀራ'
                                  ? Colors.amber.shade900.withOpacity(0.4)
                                  : Colors.brown.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text('በ$sw',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10)),
                          ),
                        ],
                      ],
                    ),
                    trailing: const Icon(Icons.add_circle,
                        color: Colors.greenAccent),
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
      final waiter = items.isNotEmpty
          ? (items.first['waiter'] as String? ?? 'OWNER')
          : 'OWNER';
      final isCredit = items.isNotEmpty
          ? (items.first['is_credit'] as int? ?? 0)
          : 0;
      final isPaid =
          items.isNotEmpty ? (items.first['is_paid'] as int? ?? 1) : 1;
      final paymentMethod = items.isNotEmpty
          ? (items.first['payment_method'] as String? ?? 'cash')
          : 'cash';

      final row = {
        'item_id': picked['id'],
        'item_name': picked['name'],
        'category': picked['category'],
        'quantity': 1,
        'unit_price': picked['price'],
        'total_price': picked['price'],
        'waiter': waiter,
        'customer': widget.customer,
        'served_with': picked['served_with'] ?? '',
        'is_credit': isCredit,
        'is_paid': isPaid,
        'payment_method': paymentMethod,
        'voided': 0,
        'timestamp': now,
      };

      try {
        final localId = await DB.saveSaleRow({...row, 'firestore_id': ''});
        final fsId = await Cloud.pushSale(row);
        if (fsId != null) await DB.updateSaleFirestoreId(localId, fsId);
        final sw = (picked['served_with'] ?? '') as String;
        if (sw == 'እንጀራ') {
          await Inventory.deduct(1, 0);
        } else if (sw == 'ዳቦ') {
          await Inventory.deduct(0, 1);
        }
      } catch (_) {}

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
      initialChildSize: 0.75,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$qty ዕቃ',
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 11)),
                    Text('${total.toStringAsFixed(0)} ብር',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
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
                child: Text('ምንም ዕቃ የለም\nምግብ ለመጨመር ከታች ይጫኑ',
                    textAlign: TextAlign.center,
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
                  final sw = (it['served_with'] ?? '') as String;
                  final pm =
                      (it['payment_method'] ?? 'cash') as String;
                  return Card(
                    color: const Color(0xFF2A2A2A),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: ListTile(
                      title: Text('${it['item_name']}',
                          style:
                              const TextStyle(color: Colors.white)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text(
                                '${it['waiter']} • ${(it['unit_price'] as num).toStringAsFixed(0)} ብር/ዕቃ',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            const SizedBox(width: 6),
                            paymentBadge(pm),
                            if (sw.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: sw == 'እንጀራ'
                                      ? Colors.amber.shade900
                                          .withOpacity(0.4)
                                      : Colors.brown.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text('በ$sw',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.redAccent, size: 26),
                              onPressed: () => _changeQty(
                                  it['id'] as int,
                                  (it['quantity'] as int) - 1)),
                          SizedBox(
                            width: 32,
                            child: Text('${it['quantity']}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                          IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: Colors.greenAccent, size: 26),
                              onPressed: () => _changeQty(
                                  it['id'] as int,
                                  (it['quantity'] as int) + 1)),
                          IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent, size: 22),
                              onPressed: () =>
                                  _deleteItem(it['id'] as int)),
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
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle, color: Colors.white),
              label: const Text('ምግብ ጨምር (Add Food)',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _addNewItem,
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
                        labelStyle: TextStyle(color: Colors.amber))),
                TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'ዋጋ (ብር)',
                        labelStyle: TextStyle(color: Colors.amber))),
                TextField(
                    controller: catCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'ምድብ',
                        labelStyle: TextStyle(color: Colors.amber))),
                const SizedBox(height: 12),
                const Text('በምን ይቀርባል?',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                        label: const Text('እንጀራ'),
                        selected: servedWith == 'እንጀራ',
                        selectedColor: Colors.amber,
                        onSelected: (v) => setStateDialog(
                            () => servedWith = v ? 'እንጀራ' : '')),
                    ChoiceChip(
                        label: const Text('ዳቦ'),
                        selected: servedWith == 'ዳቦ',
                        selectedColor: Colors.brown,
                        onSelected: (v) => setStateDialog(
                            () => servedWith = v ? 'ዳቦ' : '')),
                    ChoiceChip(
                        label: const Text('ሌላ'),
                        selected: servedWith == '',
                        selectedColor: Colors.grey,
                        onSelected: (v) =>
                            setStateDialog(() => servedWith = '')),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ሰርዝ')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price =
                    double.tryParse(priceCtrl.text.trim()) ?? 0;
                final cat = catCtrl.text.trim().isEmpty
                    ? 'ሌላ'
                    : catCtrl.text.trim();
                if (name.isEmpty || price <= 0) return;
                if (existing == null) {
                  await DB.addItem({
                    'name': name,
                    'price': price,
                    'category': cat,
                    'served_with': servedWith
                  });
                } else {
                  await DB.updateItem(existing['id'], {
                    'name': name,
                    'price': price,
                    'category': cat,
                    'served_with': servedWith
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
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('አዎ')),
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
          title: const Text('ምናሌ አስተዳደር')),
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
                    subtitle: Text(
                        '${item['category']} • ${(item['price'] as num).toStringAsFixed(0)} ብር${sw.isNotEmpty ? " • በ$sw" : ""}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.amber),
                            onPressed: () => _showForm(existing: item)),
                        IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () => _delete(item)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==================== WAITER LOCAL HISTORY ====================
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
    sales =
        all.where((s) => (s['waiter'] ?? '') == waiterName).toList();
    setState(() => loading = false);
  }

  Future<void> _exportCsv() async {
    try {
      final allSales = await DB.getAllSales();
      final mine =
          allSales.where((s) => s['waiter'] == waiterName).toList();
      if (mine.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('ምንም ሽያጭ የለም'),
            backgroundColor: Colors.orange));
        return;
      }
      final rows = <List<dynamic>>[
        ['ID', 'Date', 'Time', 'Waiter', 'Customer', 'Category', 'Item', 'Qty', 'Unit Price', 'Total', 'Payment']
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
          s['quantity'],
          s['unit_price'],
          s['total_price'],
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('CSV: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ስህተት: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteSale(Map<String, dynamic> s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('ሽያጭ ይሰረዝ?',
            style: TextStyle(color: Colors.amber)),
        content: Text('${s['item_name']} × ${s['quantity']}',
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('አይ')),
          ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('አዎ')),
        ],
      ),
    );
    if (ok == true) {
      final fsId = s['firestore_id'] as String?;
      if (fsId != null && fsId.isNotEmpty) {
        await Cloud.voidSale(fsId);
      }
      final sw = s['served_with'] as String? ?? '';
      final qty = s['quantity'] as int? ?? 0;
      if (sw == 'እንጀራ') {
        await Inventory.restore(qty, 0);
      } else if (sw == 'ዳቦ') {
        await Inventory.restore(0, qty);
      }
      await DB.deleteSale(s['id'] as int);
      _load();
    }
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
              icon: const Icon(Icons.download), onPressed: _exportCsv)
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
                    final pm =
                        (s['payment_method'] ?? 'cash') as String;
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        onLongPress: () => _deleteSale(s),
                        title: Text(
                            '${s['item_name']} × ${s['quantity']}',
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(
                                  '${s['customer'] ?? ""} • ${DateFormat('MMM d, HH:mm').format(ts)}',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11)),
                              const SizedBox(width: 8),
                              if ((s['is_credit'] ?? 0) == 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: Colors.orange, width: 1),
                                  ),
                                  child: const Text('ዱቤ',
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                )
                              else
                                paymentBadge(pm),
                            ],
                          ),
                        ),
                        trailing: Text(
                            '${(s['total_price'] as num).toStringAsFixed(0)} ብር',
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold)),
                      ),
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
          title: Text('$waiter — ሽያጮቼ')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Cloud.waiterSalesStream(waiter),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(
                child: Text('ስህተት: ${snap.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final sales = snap.data!.where((s) {
            final ts = DateTime.tryParse((s['timestamp'] ?? '') as String);
            return ts != null && ts.isAfter(todayStart);
          }).toList();
          if (sales.isEmpty) {
            return const Center(
                child: Text('ምንም ሽያጭ የለም',
                    style: TextStyle(color: Colors.white70)));
          }
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    Text('${sales.length} ሽያጭ',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (ctx, i) {
                    final s = sales[i];
                    final ts = DateTime.tryParse(
                        (s['timestamp'] ?? '') as String);
                    final pm =
                        (s['payment_method'] ?? 'cash') as String;
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(
                            '${s['item_name']} × ${s['quantity']}',
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(
                                  '${s['customer'] ?? ""} • ${ts != null ? DateFormat('HH:mm').format(ts) : ""}',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11)),
                              const SizedBox(width: 8),
                              if ((s['is_credit'] ?? 0) == 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: Colors.orange, width: 1),
                                  ),
                                  child: const Text('ዱቤ',
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                )
                              else
                                paymentBadge(pm),
                            ],
                          ),
                        ),
                        trailing: Text(
                            '${((s['total_price'] ?? 0) as num).toStringAsFixed(0)} ብር',
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold)),
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

// ==================== REPORTS ====================
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
    if (!mounted) return;
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load)
        ],
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade900.withOpacity(0.3),
            child: Column(
              children: [
                const Text('የኔ ጠቅላላ ሽያጭ',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 14)),
                Text('${grandTotal.toStringAsFixed(0)} ብር',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                    '🍽️ እንጀራ: $grandEnjera  |  🍞 ዳቦ: $grandBread  |  ዕቃ: $grandQty',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1F1F1F),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('በክፍያ ዘዴ:',
                    style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _payRow(Icons.payments, 'ጥሬ', cashTotal, Colors.green),
                _payRow(Icons.account_balance, 'CBE', cbeTotal,
                    Colors.purple),
                _payRow(Icons.phone_android, 'ቴሌብር', telebirrTotal,
                    Colors.lightBlue),
                _payRow(Icons.credit_card, 'ዱቤ', creditTotal,
                    Colors.orange),
              ],
            ),
          ),
          ...summary.map((s) {
            final ts = DateTime.tryParse((s['timestamp'] ?? '') as String);
            final pm = (s['payment_method'] ?? 'cash') as String;
            return ListTile(
              title: Text('${s['item_name']} × ${s['quantity']}',
                  style: const TextStyle(color: Colors.white)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Text(
                        ts != null
                            ? DateFormat('MMM d, HH:mm').format(ts)
                            : '',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                    const SizedBox(width: 8),
                    if ((s['is_credit'] ?? 0) == 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.orange, width: 1),
                        ),
                        child: const Text('ዱቤ',
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      )
                    else
                      paymentBadge(pm),
                  ],
                ),
              ),
              trailing: Text(
                  '${((s['total_price'] ?? 0) as num).toStringAsFixed(0)} ብር',
                  style: const TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
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
              child:
                  Text(label, style: const TextStyle(color: Colors.white))),
          Text('${amount.toStringAsFixed(0)} ብር',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
