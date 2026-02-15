import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/user.dart';
import '../models/butcher_shop.dart';
import '../models/stock_session.dart';
import '../models/stock_movement.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cheku_left_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Butcher shops table (tenants)
    await db.execute('''
      CREATE TABLE butcher_shops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        license_number TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Users table with butcher_id for multi-tenant
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        butcher_id INTEGER NOT NULL,
        username TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT DEFAULT 'cashier',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (butcher_id) REFERENCES butcher_shops (id),
        UNIQUE(butcher_id, username)
      )
    ''');

    // Products table with butcher_id
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        butcher_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price_per_kg REAL NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (butcher_id) REFERENCES butcher_shops (id)
      )
    ''');

    // Sales table with butcher_id and user_id for tracking
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        butcher_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        sale_number TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY (butcher_id) REFERENCES butcher_shops (id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(butcher_id, sale_number)
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        weight_grams INTEGER NOT NULL,
        price_per_kg REAL NOT NULL,
        total_price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    // Stock sessions table for daily open/close
    await _createStockTables(db);

    await _insertDefaultData(db);
  }

  Future<void> _createStockTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        butcher_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        open_time TEXT NOT NULL,
        close_time TEXT,
        status TEXT DEFAULT 'open',
        created_at TEXT NOT NULL,
        FOREIGN KEY (butcher_id) REFERENCES butcher_shops (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        opening_grams INTEGER NOT NULL,
        sold_grams INTEGER DEFAULT 0,
        closing_grams INTEGER,
        expected_closing_grams INTEGER NOT NULL,
        variance_grams INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES stock_sessions (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createStockTables(db);
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Create default butcher shop
    final butcherId = await db.insert('butcher_shops', {
      'name': 'Demo Butcher Shop',
      'address': '123 Main Street',
      'phone': '+263 77 123 4567',
      'license_number': 'BL-001',
      'is_active': 1,
      'created_at': now,
    });

    // Create admin user for the butcher shop
    await db.insert('users', {
      'butcher_id': butcherId,
      'username': 'admin',
      'password_hash': 'admin123',
      'full_name': 'Shop Admin',
      'role': 'admin',
      'is_active': 1,
      'created_at': now,
    });

    // Create cashier user for the butcher shop
    await db.insert('users', {
      'butcher_id': butcherId,
      'username': 'cashier',
      'password_hash': 'cashier123',
      'full_name': 'John Cashier',
      'role': 'cashier',
      'is_active': 1,
      'created_at': now,
    });

    // Create sample products for the butcher shop
    final products = [
      {'name': 'Beef', 'price_per_kg': 8.00},
      {'name': 'Pork', 'price_per_kg': 6.50},
      {'name': 'Chicken', 'price_per_kg': 5.00},
      {'name': 'Goat', 'price_per_kg': 9.00},
      {'name': 'Sausage', 'price_per_kg': 7.00},
    ];

    for (var product in products) {
      await db.insert('products', {
        'butcher_id': butcherId,
        'name': product['name'],
        'price_per_kg': product['price_per_kg'],
        'is_active': 1,
        'created_at': now,
      });
    }
  }

  // BUTCHER SHOP OPERATIONS
  Future<ButcherShop?> getButcherShop(int id) async {
    final db = await database;
    final result = await db.query(
      'butcher_shops',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return ButcherShop.fromMap(result.first);
    }
    return null;
  }

  // USER OPERATIONS
  Future<User?> getUserById(int id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<void> saveUserFromApi({
    required int id,
    required int butcherId,
    required String email,
    required String passwordHash,
    required String fullName,
    required String role,
    String? butcherName,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    // Upsert butcher shop
    final existingShop = await db.query(
      'butcher_shops',
      where: 'id = ?',
      whereArgs: [butcherId],
    );

    if (existingShop.isEmpty) {
      await db.insert('butcher_shops', {
        'id': butcherId,
        'name': butcherName ?? 'Shop $butcherId',
        'is_active': 1,
        'created_at': now,
      });
    } else if (butcherName != null) {
      await db.update(
        'butcher_shops',
        {'name': butcherName},
        where: 'id = ?',
        whereArgs: [butcherId],
      );
    }

    // Upsert user
    final existingUser = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existingUser.isEmpty) {
      await db.insert('users', {
        'id': id,
        'butcher_id': butcherId,
        'username': email,
        'password_hash': passwordHash,
        'full_name': fullName,
        'role': role,
        'is_active': 1,
        'created_at': now,
      });
    } else {
      await db.update(
        'users',
        {
          'butcher_id': butcherId,
          'username': email,
          'password_hash': passwordHash,
          'full_name': fullName,
          'role': role,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<Map<String, dynamic>?> authenticateUserByEmail(
    String email,
    String password,
  ) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      final user = result.first;
      final butcherId = user['butcher_id'] as int;
      final shop = await getButcherShop(butcherId);

      return {...user, 'butcher_shop': shop?.toMap()};
    }
    return null;
  }

  Future<List<User>> getUsersByButcher(int butcherId) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'butcher_id = ?',
      whereArgs: [butcherId],
      orderBy: 'full_name ASC',
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  // PRODUCT OPERATIONS
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts({int? butcherId}) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: butcherId != null ? 'butcher_id = ?' : null,
      whereArgs: butcherId != null ? [butcherId] : null,
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getActiveProducts({int? butcherId}) async {
    final db = await database;
    String where = 'is_active = ?';
    List<dynamic> whereArgs = [1];

    if (butcherId != null) {
      where += ' AND butcher_id = ?';
      whereArgs.add(butcherId);
    }

    final result = await db.query(
      'products',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // SALE OPERATIONS
  Future<int> insertSale(Sale sale, List<SaleItem> items) async {
    final db = await database;

    return await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap());

      for (var item in items) {
        final itemMap = item.copyWith(saleId: saleId).toMap();
        itemMap.remove('id');
        await txn.insert('sale_items', itemMap);
      }

      return saleId;
    });
  }

  Future<List<Sale>> getAllSales({int? butcherId, int? userId}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (butcherId != null && userId != null) {
      where = 'butcher_id = ? AND user_id = ?';
      whereArgs = [butcherId, userId];
    } else if (butcherId != null) {
      where = 'butcher_id = ?';
      whereArgs = [butcherId];
    }

    final salesResult = await db.query(
      'sales',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    List<Sale> sales = [];
    for (var saleMap in salesResult) {
      final itemsResult = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      final items = itemsResult.map((map) => SaleItem.fromMap(map)).toList();
      sales.add(Sale.fromMap(saleMap, items: items));
    }

    return sales;
  }

  Future<List<Sale>> getUnsyncedSales({int? butcherId}) async {
    final db = await database;
    String where = 'is_synced = ?';
    List<dynamic> whereArgs = [0];

    if (butcherId != null) {
      where += ' AND butcher_id = ?';
      whereArgs.add(butcherId);
    }

    final salesResult = await db.query(
      'sales',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at ASC',
    );

    List<Sale> sales = [];
    for (var saleMap in salesResult) {
      final itemsResult = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      final items = itemsResult.map((map) => SaleItem.fromMap(map)).toList();
      sales.add(Sale.fromMap(saleMap, items: items));
    }

    return sales;
  }

  Future<int> markSaleAsSynced(int saleId) async {
    final db = await database;
    return await db.update(
      'sales',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  Future<List<Sale>> getTodaySales({int? butcherId, int? userId}) async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final endOfDay = DateTime(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
    ).toIso8601String();

    String where = 'created_at BETWEEN ? AND ?';
    List<dynamic> whereArgs = [startOfDay, endOfDay];

    if (butcherId != null) {
      where += ' AND butcher_id = ?';
      whereArgs.add(butcherId);
    }
    if (userId != null) {
      where += ' AND user_id = ?';
      whereArgs.add(userId);
    }

    final salesResult = await db.query(
      'sales',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    List<Sale> sales = [];
    for (var saleMap in salesResult) {
      final itemsResult = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleMap['id']],
      );
      final items = itemsResult.map((map) => SaleItem.fromMap(map)).toList();
      sales.add(Sale.fromMap(saleMap, items: items));
    }

    return sales;
  }

  Future<int> getNextSaleNumber({required int butcherId}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) + 1 as next FROM sales WHERE butcher_id = ?',
      [butcherId],
    );
    return result.first['next'] as int;
  }

  // USER AUTHENTICATION
  Future<Map<String, dynamic>?> authenticateUser(
    String username,
    String password,
  ) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password_hash = ? AND is_active = ?',
      whereArgs: [username, password, 1],
    );

    if (result.isNotEmpty) {
      final userData = Map<String, dynamic>.from(result.first);

      // Get butcher shop info
      final butcherResult = await db.query(
        'butcher_shops',
        where: 'id = ?',
        whereArgs: [userData['butcher_id']],
      );

      if (butcherResult.isNotEmpty) {
        userData['butcher_shop'] = butcherResult.first;
      }

      return userData;
    }
    return null;
  }

  // SUMMARY OPERATIONS
  Future<Map<String, dynamic>> getDailySummary({
    int? butcherId,
    int? userId,
  }) async {
    final sales = await getTodaySales(butcherId: butcherId, userId: userId);

    double totalAmount = 0;
    int totalTransactions = sales.length;
    int totalGrams = 0;
    double cashTotal = 0;
    double ecocashTotal = 0;
    double cardTotal = 0;
    int syncedCount = 0;
    int unsyncedCount = 0;

    for (var sale in sales) {
      totalAmount += sale.totalAmount;

      for (var item in sale.items) {
        totalGrams += item.weightGrams;
      }

      switch (sale.paymentMethod.toLowerCase()) {
        case 'cash':
          cashTotal += sale.totalAmount;
          break;
        case 'ecocash':
          ecocashTotal += sale.totalAmount;
          break;
        case 'card':
          cardTotal += sale.totalAmount;
          break;
      }

      if (sale.isSynced) {
        syncedCount++;
      } else {
        unsyncedCount++;
      }
    }

    return {
      'totalAmount': totalAmount,
      'totalTransactions': totalTransactions,
      'totalGrams': totalGrams,
      'cashTotal': cashTotal,
      'ecocashTotal': ecocashTotal,
      'cardTotal': cardTotal,
      'syncedCount': syncedCount,
      'unsyncedCount': unsyncedCount,
    };
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // STOCK SESSION OPERATIONS
  Future<int> insertStockSession(StockSession session) async {
    final db = await database;
    final map = session.toMap();
    map.remove('id');
    return await db.insert('stock_sessions', map);
  }

  Future<StockSession?> getOpenSession({required int butcherId}) async {
    final db = await database;
    final result = await db.query(
      'stock_sessions',
      where: 'butcher_id = ? AND status = ?',
      whereArgs: [butcherId, 'open'],
      orderBy: 'open_time DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return StockSession.fromMap(result.first);
    }
    return null;
  }

  Future<StockSession?> getSessionById(int id) async {
    final db = await database;
    final result = await db.query(
      'stock_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return StockSession.fromMap(result.first);
    }
    return null;
  }

  Future<StockSession?> getTodaySession({required int butcherId}) async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final endOfDay = DateTime(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
    ).toIso8601String();

    final result = await db.query(
      'stock_sessions',
      where: 'butcher_id = ? AND open_time BETWEEN ? AND ?',
      whereArgs: [butcherId, startOfDay, endOfDay],
      orderBy: 'open_time DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return StockSession.fromMap(result.first);
    }
    return null;
  }

  Future<List<StockSession>> getAllSessions({int? butcherId}) async {
    final db = await database;
    final result = await db.query(
      'stock_sessions',
      where: butcherId != null ? 'butcher_id = ?' : null,
      whereArgs: butcherId != null ? [butcherId] : null,
      orderBy: 'open_time DESC',
    );
    return result.map((map) => StockSession.fromMap(map)).toList();
  }

  Future<int> closeStockSession(int sessionId, String closeTime) async {
    final db = await database;
    return await db.update(
      'stock_sessions',
      {'status': 'closed', 'close_time': closeTime},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // STOCK MOVEMENT OPERATIONS
  Future<int> insertStockMovement(StockMovement movement) async {
    final db = await database;
    final map = movement.toMap();
    map.remove('id');
    return await db.insert('stock_movements', map);
  }

  Future<List<StockMovement>> getSessionMovements(int sessionId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT sm.*, p.name as product_name, p.price_per_kg
      FROM stock_movements sm
      LEFT JOIN products p ON sm.product_id = p.id
      WHERE sm.session_id = ?
      ORDER BY p.name ASC
    ''',
      [sessionId],
    );
    return result.map((map) => StockMovement.fromMap(map)).toList();
  }

  Future<StockMovement?> getMovementByProduct(
    int sessionId,
    int productId,
  ) async {
    final db = await database;
    final result = await db.query(
      'stock_movements',
      where: 'session_id = ? AND product_id = ?',
      whereArgs: [sessionId, productId],
    );
    if (result.isNotEmpty) {
      return StockMovement.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateStockMovementSoldGrams(
    int sessionId,
    int productId,
    int additionalGrams,
  ) async {
    final db = await database;
    return await db.rawUpdate(
      '''
      UPDATE stock_movements
      SET sold_grams = sold_grams + ?,
          expected_closing_grams = opening_grams - (sold_grams + ?)
      WHERE session_id = ? AND product_id = ?
    ''',
      [additionalGrams, additionalGrams, sessionId, productId],
    );
  }

  Future<int> updateStockMovementClosing(
    int movementId,
    int closingGrams,
  ) async {
    final db = await database;

    // First get the movement to calculate variance
    final movement = await db.query(
      'stock_movements',
      where: 'id = ?',
      whereArgs: [movementId],
    );

    if (movement.isEmpty) return 0;

    final expectedClosing = movement.first['expected_closing_grams'] as int;
    final variance = closingGrams - expectedClosing;

    return await db.update(
      'stock_movements',
      {'closing_grams': closingGrams, 'variance_grams': variance},
      where: 'id = ?',
      whereArgs: [movementId],
    );
  }

  Future<Map<String, dynamic>> getStockReport(int sessionId) async {
    final movements = await getSessionMovements(sessionId);

    int totalOpeningGrams = 0;
    int totalSoldGrams = 0;
    int totalExpectedClosingGrams = 0;
    int totalClosingGrams = 0;
    int totalVarianceGrams = 0;
    double totalVarianceValue = 0;

    for (var m in movements) {
      totalOpeningGrams += m.openingGrams;
      totalSoldGrams += m.soldGrams;
      totalExpectedClosingGrams += m.expectedClosingGrams;
      totalClosingGrams += m.closingGrams ?? 0;
      totalVarianceGrams += m.varianceGrams ?? 0;
      if (m.pricePerKg != null && m.varianceGrams != null) {
        totalVarianceValue += m.calculateVarianceValue(m.pricePerKg!);
      }
    }

    return {
      'movements': movements,
      'totalOpeningGrams': totalOpeningGrams,
      'totalSoldGrams': totalSoldGrams,
      'totalExpectedClosingGrams': totalExpectedClosingGrams,
      'totalClosingGrams': totalClosingGrams,
      'totalVarianceGrams': totalVarianceGrams,
      'totalVarianceValue': totalVarianceValue,
    };
  }

  Future<bool> hasUnclosedSession({required int butcherId}) async {
    final session = await getOpenSession(butcherId: butcherId);
    return session != null;
  }

  Future<bool> allMovementsHaveClosingStock(int sessionId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM stock_movements
      WHERE session_id = ? AND closing_grams IS NULL
    ''',
      [sessionId],
    );
    return (result.first['count'] as int) == 0;
  }
}
