import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const SalesApp());
}

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
      home: const SplashScreen(),
    );
  }
}

// ==================== SPLASH SCREEN ====================
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
    await DB.database;
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'ETHIOPIAN FOOD',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            const Text('የሽያጭ መቆጣጠሪያ',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.amber),
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
    final dbPath = p.join(await getDatabasesPath(), 'ethiopian_sales.db');
    _db = await openDatabase(dbPath, version: 1, onCreate: _create);
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

  static Future<List<Map<String, dynamic>>> getAllSales(
      DateTime from, DateTime to) async {
    final db = await database;
    return db.query('sales',
        where: 'timestamp BETWEEN ? AND ?',
        whereArgs: [from.toIso8601String(), to.toIso8601String()],
        orderBy: 'timestamp DESC');
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
    final sold = cart.where((c) => c.qty > 0).toList();
    if (sold.isEmpty) return;

    final rows = sold
        .map((c) => {
              'item_id': c.id,
              'item_name': c.name,
              'category': c.category,
              'quantity': c.qty,
              'unit_price': c.price,
              'total_price': c.price * c.qty,
            })
        .toList();

    await DB.saveSales(rows);
    final totalAmount = sold.fold<double>(0, (s, c) => s + c.price * c.qty);

    setState(() {
      for (var c in cart) c.qty = 0;
    });

    if (!mounted) return;

    // Show options: Print Receipt or Skip
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('ሽያጭ ተመዝግቧል ✅',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...sold.map((c) => Text(
                  '${c.name}  ×  ${c.qty}  =  ${(c.price * c.qty).toStringAsFixed(0)} ብር',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                )),
            const Divider(color: Colors.white24),
            Text(
              'ጠቅላላ: ${totalAmount.toStringAsFixed(0)} ብር',
              style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ዝጋ'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print, size: 18),
            label: const Text('ደረሰኝ'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              Navigator.pop(ctx);
              _printReceipt(sold, totalAmount);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(List<CartItem> sold, double totalAmount) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(now);

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(height: 10),
          pw.Text('ETHIOPIAN FOOD',
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('የኢትዮጵያ ምግብ ቤት',
              style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 4),
          pw.Text(dateStr,
              style: const pw.TextStyle(fontSize: 10)),
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Qty x Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Divider(),
          ...sold.map((c) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text(c.name, style: const pw.TextStyle(fontSize: 10))),
                    pw.Text('${c.qty} x ${c.price.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('${(c.price * c.qty).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              )),
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('${totalAmount.toStringAsFixed(0)} ብር',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('እናመሰግናለን!',
              style: const pw.TextStyle(fontSize: 12)),
          pw.Text('Thank you!',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 20),
        ],
      ),
    ));

    await Printing.layoutPdf(
      onLayout: (format) => doc.save(),
      name: 'receipt_${now.millisecondsSinceEpoch}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber.shade900,
        title: const Text('የሽያጭ መቆጣጠሪያ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MenuScreen()));
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
        ],
      ),
      body: ListView(
        children: grouped.entries.expand((entry) {
          return [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.amber.shade900.withOpacity(0.3),
              child: Text(
                entry.key,
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            ...entry.value.map((item) => Card(
                  color: const Color(0xFF2A2A2A),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(item.name,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.white)),
                    subtitle: Text('${item.price.toStringAsFixed(0)} ብር',
                        style: const TextStyle(color: Colors.amber)),
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
                          onPressed: () => setState(() => item.qty++),
                        ),
                      ],
                    ),
                  ),
                )),
          ];
        }).toList(),
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
                      style: const TextStyle(color: Colors.white70)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
    final catCtrl = TextEditingController(text: existing?['category'] ?? '');

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
              onPressed: () => Navigator.pop(ctx), child: const Text('ሰርዝ')),
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
        label: const Text('አዲስ ጨምር', style: TextStyle(color: Colors.black)),
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          icon: const Icon(Icons.edit, color: Colors.amber),
                          onPressed: () => _showForm(existing: item),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
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
  DateTime from = DateTime.now();
  DateTime to = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DB.getSummary(from, to);
    double t = 0;
    int q = 0;
    for (var r in rows) {
      t += (r['total_revenue'] as num).toDouble();
      q += (r['total_qty'] as num).toInt();
    }
    setState(() {
      summary = rows;
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

  Future<void> _exportCSV() async {
    final rows = await DB.getAllSales(from, to);
    if (rows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ምንም ሽያጭ የለም'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final csvData = <List<dynamic>>[
      ['Date', 'Time', 'Item', 'Category', 'Qty', 'Unit Price', 'Total'],
    ];
    for (var r in rows) {
      final ts = DateTime.parse(r['timestamp'] as String);
      csvData.add([
        DateFormat('yyyy-MM-dd').format(ts),
        DateFormat('HH:mm').format(ts),
        r['item_name'],
        r['category'],
        r['quantity'],
        r['unit_price'],
        r['total_price'],
      ]);
    }
    csvData.add([]);
    csvData.add(['', '', '', 'GRAND TOTAL', grandQty, '', grandTotal]);

    final csvString = const ListToCsvConverter().convert(csvData);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/sales_$timestamp.csv');
    await file.writeAsString(csvString);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Sales Export $timestamp',
    );
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
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'CSV አውጣ',
            onPressed: _exportCSV,
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
                    style:
                        const TextStyle(fontSize: 18, color: Colors.white)),
                Text('ጠቅላላ ገቢ: ${grandTotal.toStringAsFixed(0)} ብር',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('CSV አውጣ (Excel)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _exportCSV,
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
                        title: Text(r['item_name'] as String,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(r['category'] as String? ?? '',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${r['total_qty']} ዕቃ',
                                style: const TextStyle(
                                    color: Colors.white70)),
                            Text(
                              '${(r['total_revenue'] as num).toStringAsFixed(0)} ብር',
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
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
