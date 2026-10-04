import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';

void main() {
  runApp(const SalesApp());
}

const List<String> waiters = ['የሮሳ', 'ከድር', 'አህመድ', 'ይቻላል'];

// ==================== APP ====================
class SalesApp extends StatelessWidget {
  const SalesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'የኢትዮጵያ ምግብ ሽያጭ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ==================== DATABASE ====================
class DB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = p.join(await getDatabasesPath(), 'ethiopian_sales.db');
    _db = await openDatabase(dbPath,
        version: 2, onCreate: _create, onUpgrade: _upgrade);
    return _db!;
  }

  static Future _create(Database db, int v) async {
    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL
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
        timestamp TEXT NOT NULL
      )
    ''');

    final menu = [
      {'name': 'የርማል ፉል', 'price': 110.0, 'category': 'ቁርስ'},
      {'name': 'ስፔሻል ፉል', 'price': 140.0, 'category': 'ቁርስ'},
      {'name': 'አንጀራ ፍርፍር', 'price': 110.0, 'category': 'ቁርስ'},
      {'name': 'ስፔሻል ፍርፍር', 'price': 170.0, 'category': 'ቁርስ'},
      {'name': 'አንቁላል ፍርፍር', 'price': 170.0, 'category': 'ቁርስ'},
      {'name': 'አንቁላል ስልስ', 'price': 170.0, 'category': 'ቁርስ'},
      {'name': 'አንቁላል በስጋ', 'price': 250.0, 'category': 'ቁርስ'},
      {'name': 'በያይነት', 'price': 130.0, 'category': 'ምሳ'},
      {'name': 'ፓስታ በስጋ', 'price': 110.0, 'category': 'ምሳ'},
      {'name': 'ፓስታ ባትካልት', 'price': 130.0, 'category': 'ምሳ'},
      {'name': 'የርማል ድንች', 'price': 110.0, 'category': 'ምሳ'},
      {'name': 'ጎመን', 'price': 130.0, 'category': 'ምሳ'},
      {'name': 'ሽሮ ፋስክ', 'price': 110.0, 'category': 'ምሳ'},
      {'name': 'ቲማቲም ለብለብ', 'price': 130.0, 'category': 'ምሳ'},
      {'name': 'ተጋቢኖ', 'price': 150.0, 'category': 'ምሳ'},
      {'name': 'ስፔሻል', 'price': 230.0, 'category': 'የፍስክ ምግብ'},
      {'name': 'ጥብስ', 'price': 350.0, 'category': 'የፍስክ ምግብ'},
      {'name': 'ዱለት', 'price': 300.0, 'category': 'የፍስክ ምግብ'},
      {'name': 'ድንች በስጋ', 'price': 180.0, 'category': 'የፍስክ ምግብ'},
      {'name': 'ሽሮ ባይባይ', 'price': 170.0, 'category': 'የፍስክ ምግብ'},
      {'name': 'ሽሮ በቅቤ', 'price': 150.0, 'category': 'የፍስክ ምግብ'},
      {'name': 'ቅቅል', 'price': 300.0, 'category': 'የፍስክ ምግብ'},
      {'name': 'ጎመን አንጀራ', 'price': 20.0, 'category': 'ተጨማሪ'},
      {'name': 'ዳቦ', 'price': 15.0, 'category': 'ተጨማሪ'},
      {'name': '2 ሊትር ውሃ', 'price': 60.0, 'category': 'መጠጦች'},
      {'name': '1 ሊትር ውሃ', 'price': 40.0, 'category': 'መጠጦች'},
      {'name': 'ለስላሳ መጠጦች', 'price': 50.0, 'category': 'መጠጦች'},
    ];
    for (var item in menu) {
      await db.insert('menu_items', item);
    }
  }

  static Future _upgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute(
          'ALTER TABLE sales ADD COLUMN waiter TEXT NOT NULL DEFAULT ""');
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
    final now = DateTime.now().toIso8601String();
    for (var r in rows) {
      batch.insert('sales', {...r, 'timestamp': now});
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getAllSales() async {
    final db = await database;
    return db.query('sales', orderBy: 'timestamp DESC');
  }

  static Future<List<Map<String, dynamic>>> getSummary(
      DateTime from, DateTime to) async {
    final db = await database;
    return db.rawQuery('''
      SELECT item_name, category,
             SUM(quantity) as total_qty,
             SUM(total_price) as total_revenue
      FROM sales
      WHERE timestamp BETWEEN ? AND ?
      GROUP BY item_name
      ORDER BY category, item_name
    ''', [from.toIso8601String(), to.toIso8601String()]);
  }

  static Future<List<Map<String, dynamic>>> getWaiterSummary(
      DateTime from, DateTime to) async {
    final db = await database;
    return db.rawQuery('''
      SELECT waiter,
             SUM(quantity) as total_qty,
             SUM(total_price) as total_revenue
      FROM sales
      WHERE timestamp BETWEEN ? AND ?
      GROUP BY waiter
      ORDER BY total_revenue DESC
    ''', [from.toIso8601String(), to.toIso8601String()]);
  }
}

// ==================== CART MODEL ====================
class CartItem {
  final int id;
  final String name;
  final String category;
  final double price;
  int qty;
  CartItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.qty = 0,
  });
}

// ==================== HOME SCREEN ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CartItem> cart = [];
  bool loading = true;
  String selectedWaiter = waiters.first;

  @override
  void initState() {
    super.initState();
    _load();
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
            ))
        .toList();
    setState(() => loading = false);
  }

  double get total => cart.fold(0.0, (s, c) => s + c.price * c.qty);
  int get totalItems => cart.fold(0, (s, c) => s + c.qty);

  Map<String, List<CartItem>> get grouped {
    final map = <String, List<CartItem>>{};
    for (var c in cart) {
      map.putIfAbsent(c.category, () => []).add(c);
    }
    return map;
  }

  Future<void> _confirm() async {
    final cartRows = cart.where((c) => c.qty > 0).toList();
    final rows = cartRows
        .map((c) => {
              'item_id': c.id,
              'item_name': c.name,
              'category': c.category,
              'quantity': c.qty,
              'unit_price': c.price,
              'total_price': c.price * c.qty,
              'waiter': selectedWaiter,
            })
        .toList();
    if (rows.isEmpty) return;

    await DB.saveSales(rows);
    setState(() {
      for (var c in cart) c.qty = 0;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ሽያጭ ተመዝግቧል ✅ (${selectedWaiter})'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('የሽያጭ መቆጣጠሪያ'),
        actions: [
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
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF1F1F1F),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text('አስተናጋጅ:',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: DropdownButton<String>(
                      value: selectedWaiter,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2A2A2A),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.amber),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16),
                      items: waiters
                          .map((w) => DropdownMenuItem(
                                value: w,
                                child: Text(w),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedWaiter = v!),
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
                        horizontal: 16, vertical: 10),
                    color: Colors.amber.shade900.withOpacity(0.3),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...entry.value.map((item) => Card(
                        color: const Color(0xFF2A2A2A),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(item.name,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white)),
                          subtitle: Text(
                              '${item.price.toStringAsFixed(0)} ብር',
                              style:
                                  const TextStyle(color: Colors.amber)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.redAccent, size: 32),
                                onPressed: () => setState(() {
                                  if (item.qty > 0) item.qty--;
                                }),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text('${item.qty}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.greenAccent, size: 32),
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
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF1F1F1F),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ዕቃዎች: $totalItems',
                      style:
                          const TextStyle(color: Colors.white70)),
                  Text('ጠቅላላ: ${total.toStringAsFixed(0)} ብር',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber)),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('አረጋግጥ'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: totalItems == 0 ? null : _confirm,
            ),
          ],
        ),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ሰርዝ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
              final cat =
                  catCtrl.text.trim().isEmpty ? 'ሌላ' : catCtrl.text.trim();
              if (name.isEmpty || price <= 0) return;

              if (existing == null) {
                await DB.addItem(
                    {'name': name, 'price': price, 'category': cat});
              } else {
                await DB.updateItem(existing['id'],
                    {'name': name, 'price': price, 'category': cat});
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: const Text('አስቀምጥ'),
          ),
        ],
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
                return Card(
                  color: const Color(0xFF2A2A2A),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(item['name'] as String,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${item['category']}  •  ${(item['price'] as num).toStringAsFixed(0)} ብር',
                      style: const TextStyle(color: Colors.white54),
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

// ==================== HISTORY SCREEN ====================
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> sales = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    sales = await DB.getAllSales();
    setState(() => loading = false);
  }

  Future<void> _exportCsv() async {
    try {
      final allSales = await DB.getAllSales();
      if (allSales.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ምንም ሽያጭ የለም'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final rows = <List<dynamic>>[
        [
          'ID',
          'Date',
          'Time',
          'Waiter',
          'Category',
          'Item',
          'Qty',
          'Unit Price',
          'Total',
        ]
      ];
      for (var s in allSales) {
        final ts = DateTime.parse(s['timestamp'] as String);
        rows.add([
          s['id'],
          DateFormat('yyyy-MM-dd').format(ts),
          DateFormat('HH:mm:ss').format(ts),
          s['waiter'],
          s['category'],
          s['item_name'],
          s['quantity'],
          s['unit_price'],
          s['total_price'],
        ]);
      }

      final csvData = const ListToCsvConverter().convert(rows);
      final fileName =
          'sales_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      // Try Downloads folder first; fallback to app files
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
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ስህተት: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('የትራንዛክሽን ታሪክ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'CSV አውጣ',
            onPressed: _exportCsv,
          ),
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
                    final waiterStr = (s['waiter'] as String?) ?? '';
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.shade900,
                          child: Text(
                            waiterStr.isEmpty
                                ? '?'
                                : waiterStr.substring(0, 1),
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
                          '${s['waiter']} • ${DateFormat('MMM d, HH:mm').format(ts)}\n${s['category']}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
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
  List<Map<String, dynamic>> waiterSummary = [];
  double grandTotal = 0;
  int grandQty = 0;
  DateTime from = DateTime.now();
  DateTime to = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DB.getSummary(from, to);
    final waitersData = await DB.getWaiterSummary(from, to);
    double t = 0;
    int q = 0;
    for (var r in rows) {
      t += (r['total_revenue'] as num).toDouble();
      q += (r['total_qty'] as num).toInt();
    }
    setState(() {
      summary = rows;
      waiterSummary = waitersData;
      grandTotal = t;
      grandQty = q;
    });
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (range != null) {
      setState(() {
        from = range.start;
        to = range.end.add(const Duration(days: 1));
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('ሪፖርት'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickRange,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade900.withOpacity(0.3),
            child: Column(
              children: [
                Text(
                  '${DateFormat('MMM d').format(from)} — ${DateFormat('MMM d').format(to.subtract(const Duration(days: 1)))}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text('የተሸጡ ዕቃዎች: $grandQty',
                    style: const TextStyle(
                        fontSize: 18, color: Colors.white)),
                Text('ጠቅላላ ገቢ: ${grandTotal.toStringAsFixed(0)} ብር',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber)),
              ],
            ),
          ),
          if (waiterSummary.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1F1F1F),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('በአስተናጋጅ:',
                      style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...waiterSummary.map((w) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('👤 ${w['waiter']}',
                                style: const TextStyle(
                                    color: Colors.white)),
                            Text(
                              '${w['total_qty']} ዕቃ — ${(w['total_revenue'] as num).toStringAsFixed(0)} ብር',
                              style: const TextStyle(
                                  color: Colors.white70),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          Expanded(
            child: summary.isEmpty
                ? const Center(
                    child: Text('ምንም ሽያጭ የለም',
                        style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    itemCount: summary.length,
                    itemBuilder: (ctx, i) {
                      final r = summary[i];
                      return ListTile(
                        title: Text(r['item_name']
