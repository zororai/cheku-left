# Cheku Left POS - Functions Reference

## Table of Contents
- [License Lock System](#license-lock-system)
- [Stock Module Features](#stock-module-features)
- [Models](#models)
- [Providers](#providers)
- [Services](#services)
- [Database](#database)

---

## License Lock System

The License Lock & SMS Unlock system enforces payment control and prevents unauthorized usage.

| Feature | Description |
|---------|-------------|
| **Payment limit tracking** | App usage limited to 20 successful payments |
| **Automatic lock** | App locks automatically after reaching payment limit |
| **SMS notification** | Lock event triggers SMS to admin via backend |
| **Unlock code** | Admin sends 6-digit unlock code to client |
| **Backend validation** | Unlock code validated server-side only |
| **Device binding** | Device ID tracked for each license |
| **Startup verification** | License checked on every app launch |

### Lock Flow
1. **Sale completed** → Payment count incremented on backend
2. **Limit reached** → App locks, SMS sent to admin
3. **Admin receives** → Unlock code in SMS
4. **Client enters code** → Backend validates, app unlocks
5. **Counter reset** → Payment count reset to 0

---

## Stock Module Features

The Opening & Closing Stock Module provides daily stock control for butcher operations.

| Feature | Description |
|---------|-------------|
| **Open Day with opening stock entry** | Start a new day by recording opening stock (grams) for each product |
| **Auto-deduct stock from sales** | When a sale is created, sold grams are automatically deducted from stock movements |
| **Block sales if day not open** | Sales cannot be created unless a stock session is open for the day |
| **Record closing stock per product** | At end of day, enter physical stock count for each product |
| **Calculate variance (gain/loss)** | System calculates: `variance = actualClosing - expectedClosing` |
| **Close day with validation** | Cannot close day until all products have closing stock recorded |
| **Daily stock report with variance analysis** | Comprehensive report showing opening, sold, expected, actual, and variance per product |
| **Session history** | View past stock sessions and their reports |
| **Database migration (v1 → v2)** | Automatic migration adds stock tables to existing databases |

### Daily Flow
1. **Open Day** → Enter opening stock for all products
2. **During Day** → Sales auto-deduct from stock
3. **Close Day** → Enter physical closing stock, review variance, close session

### Variance Formulas
```
expectedClosing = openingGrams - soldGrams
variance = closingGrams - expectedClosing
varianceValue = (varianceGrams / 1000) * pricePerKg
```

---

## Models

### ButcherShop
**File:** `lib/models/butcher_shop.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `toMap()` | `Map<String, dynamic>` | Converts the butcher shop to a database map |
| `ButcherShop.fromMap(map)` | `ButcherShop` | Factory constructor from database map |
| `toJson()` | `Map<String, dynamic>` | Converts to JSON for API |

---

### CartItem
**File:** `lib/models/cart_item.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `CartItem.create(product, weightGrams)` | `CartItem` | Factory constructor to create cart item with calculated price |
| `toSaleItem()` | `SaleItem` | Converts cart item to sale item for checkout |

---

### Product
**File:** `lib/models/product.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `toMap()` | `Map<String, dynamic>` | Converts the product to a database map |
| `Product.fromMap(map)` | `Product` | Factory constructor from database map |
| `copyWith(...)` | `Product` | Creates a copy with optional modified fields |

---

### Sale
**File:** `lib/models/sale.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `toMap()` | `Map<String, dynamic>` | Converts the sale to a database map |
| `Sale.fromMap(map, {items})` | `Sale` | Factory constructor from database map with items |
| `toJson()` | `Map<String, dynamic>` | Converts to JSON for API sync |
| `copyWith(...)` | `Sale` | Creates a copy with optional modified fields |

---

### SaleItem
**File:** `lib/models/sale_item.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `calculateTotalPrice(weightGrams, pricePerKg)` | `double` | Static method to calculate total price |
| `toMap()` | `Map<String, dynamic>` | Converts to database map |
| `SaleItem.fromMap(map)` | `SaleItem` | Factory constructor from database map |
| `toJson()` | `Map<String, dynamic>` | Converts to JSON for API |
| `copyWith(...)` | `SaleItem` | Creates a copy with optional modified fields |

---

### User
**File:** `lib/models/user.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `toMap()` | `Map<String, dynamic>` | Converts to database map |
| `User.fromMap(map)` | `User` | Factory constructor from database map |
| `toJson()` | `Map<String, dynamic>` | Converts to JSON |

**Getters:**
- `isAdmin` → `bool` - Returns true if user role is admin
- `isManager` → `bool` - Returns true if user role is manager
- `isCashier` → `bool` - Returns true if user role is cashier

---

### StockSession
**File:** `lib/models/stock_session.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `toMap()` | `Map<String, dynamic>` | Converts to database map |
| `StockSession.fromMap(map)` | `StockSession` | Factory constructor from database map |
| `toJson()` | `Map<String, dynamic>` | Converts to JSON for API |
| `copyWith(...)` | `StockSession` | Creates a copy with optional modified fields |

**Getters:**
- `isOpen` → `bool` - Returns true if session status is 'open'
- `isClosed` → `bool` - Returns true if session status is 'closed'

---

### StockMovement
**File:** `lib/models/stock_movement.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `calculateExpectedClosing(openingGrams, soldGrams)` | `int` | Static: Calculates expected closing stock |
| `calculateVariance(closingGrams, expectedClosingGrams)` | `int` | Static: Calculates variance (gain/loss) |
| `calculateVarianceValue(pricePerKg)` | `double` | Calculates monetary value of variance |
| `toMap()` | `Map<String, dynamic>` | Converts to database map |
| `StockMovement.fromMap(map)` | `StockMovement` | Factory constructor from database map |
| `toJson()` | `Map<String, dynamic>` | Converts to JSON for API |
| `copyWith(...)` | `StockMovement` | Creates a copy with optional modified fields |

**Getters:**
- `isFinalized` → `bool` - Returns true if closing stock has been recorded
- `varianceDisplay` → `String` - Formatted variance string (e.g., "+50g" or "-30g")

---

## Providers

### AuthProvider
**File:** `lib/providers/auth_provider.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `checkAuthStatus()` | `Future<void>` | Checks and restores authentication status from SharedPreferences |
| `login(username, password)` | `Future<bool>` | Authenticates user and stores session |
| `logout()` | `Future<void>` | Clears authentication and session data |

**Getters:**
- `isAuthenticated` → `bool`
- `userId` → `int?`
- `butcherId` → `int?`
- `username` → `String?`
- `fullName` → `String?`
- `role` → `String?`
- `butcherName` → `String?`
- `isLoading` → `bool`
- `isAdmin` → `bool`
- `isManager` → `bool`
- `isCashier` → `bool`

---

### CartProvider
**File:** `lib/providers/cart_provider.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `addItem(product, weightGrams)` | `void` | Adds a product to the cart |
| `removeItem(index)` | `void` | Removes item at specified index |
| `updateItem(index, newWeightGrams)` | `void` | Updates weight of item at index |
| `setPaymentMethod(method)` | `void` | Sets the payment method |
| `toSaleItems()` | `List<SaleItem>` | Converts cart items to sale items |
| `clear()` | `void` | Clears all items and resets payment method |

**Getters:**
- `items` → `List<CartItem>` - Unmodifiable list of cart items
- `selectedPaymentMethod` → `String`
- `itemCount` → `int`
- `totalAmount` → `double`
- `totalGrams` → `int`
- `isEmpty` → `bool`
- `isNotEmpty` → `bool`

---

### ProductProvider
**File:** `lib/providers/product_provider.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `setCurrentButcher(butcherId)` | `void` | Sets the current butcher context |
| `loadProducts({butcherId})` | `Future<void>` | Loads all products for a butcher |
| `addProduct(product)` | `Future<bool>` | Adds a new product |
| `updateProduct(product)` | `Future<bool>` | Updates an existing product |
| `deleteProduct(id, {butcherId})` | `Future<bool>` | Deletes a product by ID |
| `toggleProductStatus(product)` | `Future<bool>` | Toggles product active/inactive status |

**Getters:**
- `products` → `List<Product>`
- `activeProducts` → `List<Product>`
- `isLoading` → `bool`

---

### SaleProvider
**File:** `lib/providers/sale_provider.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `setCurrentUser({butcherId, userId})` | `void` | Sets current user context |
| `loadSales({butcherId, userId})` | `Future<void>` | Loads sales data |
| `isDayOpen({butcherId})` | `Future<bool>` | Checks if stock session is open |
| `createSale({butcherId, userId, totalAmount, paymentMethod, items, checkStockSession})` | `Future<String>` | Creates a new sale, auto-deducts stock, returns sale number |
| `syncSales({apiToken, butcherId})` | `Future<SyncResult>` | Syncs unsynced sales to server |
| `hasInternetConnection()` | `Future<bool>` | Checks internet connectivity |

**Getters:**
- `sales` → `List<Sale>`
- `todaySales` → `List<Sale>`
- `unsyncedSales` → `List<Sale>`
- `dailySummary` → `Map<String, dynamic>`
- `isLoading` → `bool`
- `isSyncing` → `bool`
- `unsyncedCount` → `int`

---

### StockProvider
**File:** `lib/providers/stock_provider.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `setCurrentUser({butcherId, userId})` | `void` | Sets current user context |
| `loadCurrentSession({butcherId})` | `Future<void>` | Loads current open stock session |
| `openDay({butcherId, userId, products, openingStockGrams})` | `Future<bool>` | Opens a new day with opening stock |
| `closeDay(sessionId)` | `Future<bool>` | Closes the day after recording closing stock |
| `recordClosingStock(movementId, closingGrams)` | `Future<bool>` | Records physical closing stock for a product |
| `updateSoldGrams(productId, additionalGrams)` | `Future<bool>` | Updates sold grams (called by sales) |
| `loadSessionMovements(sessionId)` | `Future<void>` | Loads stock movements for a session |
| `calculateDailyStockReport(sessionId)` | `Future<Map<String, dynamic>>` | Generates daily stock report |
| `getSessionHistory({butcherId})` | `Future<List<StockSession>>` | Gets all past sessions |
| `getSessionById(id)` | `Future<StockSession?>` | Gets a specific session |
| `clearError()` | `void` | Clears error state |

**Getters:**
- `currentSession` → `StockSession?`
- `stockMovements` → `List<StockMovement>`
- `isLoading` → `bool`
- `error` → `String?`
- `isDayOpen` → `bool`
- `totalVarianceGrams` → `int`
- `totalVarianceValue` → `double`

---

## Services

### PrintService
**File:** `lib/services/print_service.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `getBondedDevices()` | `Future<List<PrinterDevice>>` | Gets list of paired Bluetooth printers |
| `connect(device)` | `Future<bool>` | Connects to a Bluetooth printer |
| `disconnect()` | `Future<void>` | Disconnects from current printer |
| `checkConnection()` | `Future<bool>` | Checks if printer is still connected |
| `printReceipt({sale, items, shopName, cashierName})` | `Future<bool>` | Prints a sale receipt |
| `printTestPage()` | `Future<bool>` | Prints a test page |
| `_formatDate(isoDate)` | `String` | Private helper to format date for receipt |

**Getters:**
- `isConnected` → `bool`
- `connectedDevice` → `PrinterDevice?`

---

### SyncService
**File:** `lib/services/sync_service.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `hasInternetConnection()` | `Future<bool>` | Checks internet connectivity |
| `syncSales({apiToken, butcherId})` | `Future<SyncResult>` | Syncs individual sales one by one |
| `syncAllSales({apiToken})` | `Future<SyncResult>` | Syncs all unsynced sales in batch |
| `_sendSaleToServer(sale, apiToken)` | `Future<bool>` | Private method to POST sale to API |

---

### SyncResult
**File:** `lib/services/sync_service.dart`

| Property | Type | Description |
|----------|------|-------------|
| `success` | `bool` | Whether sync was successful |
| `message` | `String` | Status message |
| `syncedCount` | `int` | Number of successfully synced sales |
| `failedCount` | `int` | Number of failed syncs |
| `errors` | `List<String>` | List of error messages |

---

### LicenseService
**File:** `lib/services/license_service.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `checkLicenseStatus({butcherId})` | `Future<LicenseStatus>` | Checks current license status with backend |
| `incrementPaymentCount({butcherId, butcherName})` | `Future<LicenseStatus>` | Increments payment count after sale |
| `submitUnlockCode({butcherId, code})` | `Future<UnlockResult>` | Submits unlock code for validation |
| `registerDevice({butcherId, butcherName})` | `Future<bool>` | Registers device with backend |

---

### LicenseStatus
**File:** `lib/services/license_service.dart`

| Property | Type | Description |
|----------|------|-------------|
| `isLocked` | `bool` | Whether app is locked |
| `remainingPayments` | `int` | Payments remaining before lock |
| `paymentCount` | `int` | Current payment count |
| `maxAllowedPayments` | `int` | Maximum allowed payments (default: 20) |

---

### LicenseProvider
**File:** `lib/providers/license_provider.dart`

| Function | Return Type | Description |
|----------|-------------|-------------|
| `setCurrentButcher({butcherId, butcherName})` | `void` | Sets current butcher context |
| `checkLicenseStatus({butcherId})` | `Future<void>` | Checks license status from backend |
| `incrementPaymentAndCheck({butcherId, butcherName})` | `Future<LicenseStatus>` | Increments payment and returns status |
| `submitUnlockCode({butcherId, code})` | `Future<bool>` | Submits unlock code, returns success |
| `registerDevice({butcherId, butcherName})` | `Future<void>` | Registers device with backend |
| `clearError()` | `void` | Clears error state |

**Getters:**
- `status` → `LicenseStatus?`
- `isLoading` → `bool`
- `error` → `String?`
- `isLocked` → `bool`
- `remainingPayments` → `int`
- `paymentCount` → `int`
- `maxPayments` → `int`

---

## Database

### DatabaseHelper
**File:** `lib/database/database_helper.dart`

#### Initialization
| Function | Return Type | Description |
|----------|-------------|-------------|
| `database` | `Future<Database>` | Gets or initializes the database |
| `_initDB(fileName)` | `Future<Database>` | Private: Initializes database file |
| `_createDB(db, version)` | `Future<void>` | Private: Creates all tables |
| `_insertDefaultData(db)` | `Future<void>` | Private: Inserts demo data |
| `close()` | `Future<void>` | Closes the database connection |

#### Butcher Shop Operations
| Function | Return Type | Description |
|----------|-------------|-------------|
| `getButcherShop(id)` | `Future<ButcherShop?>` | Gets butcher shop by ID |

#### User Operations
| Function | Return Type | Description |
|----------|-------------|-------------|
| `getUserById(id)` | `Future<User?>` | Gets user by ID |
| `getUsersByButcher(butcherId)` | `Future<List<User>>` | Gets all users for a butcher shop |
| `authenticateUser(username, password)` | `Future<Map<String, dynamic>?>` | Authenticates user credentials |

#### Product Operations
| Function | Return Type | Description |
|----------|-------------|-------------|
| `insertProduct(product)` | `Future<int>` | Inserts a new product |
| `getAllProducts({butcherId})` | `Future<List<Product>>` | Gets all products, optionally filtered |
| `getActiveProducts({butcherId})` | `Future<List<Product>>` | Gets active products only |
| `updateProduct(product)` | `Future<int>` | Updates an existing product |
| `deleteProduct(id)` | `Future<int>` | Deletes a product |

#### Sale Operations
| Function | Return Type | Description |
|----------|-------------|-------------|
| `insertSale(sale, items)` | `Future<int>` | Inserts sale with items in transaction |
| `getAllSales({butcherId, userId})` | `Future<List<Sale>>` | Gets all sales with filters |
| `getUnsyncedSales({butcherId})` | `Future<List<Sale>>` | Gets sales not yet synced |
| `markSaleAsSynced(saleId)` | `Future<int>` | Marks a sale as synced |
| `getTodaySales({butcherId, userId})` | `Future<List<Sale>>` | Gets today's sales |
| `getNextSaleNumber({butcherId})` | `Future<int>` | Gets next sale number for a butcher |

#### Summary Operations
| Function | Return Type | Description |
|----------|-------------|-------------|
| `getDailySummary({butcherId, userId})` | `Future<Map<String, dynamic>>` | Gets daily sales summary with totals by payment method |

#### Stock Session Operations
| Function | Return Type | Description |
|----------|-------------|-------------|
| `insertStockSession(session)` | `Future<int>` | Creates a new stock session |
| `getOpenSession({butcherId})` | `Future<StockSession?>` | Gets currently open session |
| `getSessionById(id)` | `Future<StockSession?>` | Gets session by ID |
| `getTodaySession({butcherId})` | `Future<StockSession?>` | Gets today's session |
| `getAllSessions({butcherId})` | `Future<List<StockSession>>` | Gets all sessions for a butcher |
| `closeStockSession(sessionId, closeTime)` | `Future<int>` | Closes a stock session |
| `hasUnclosedSession({butcherId})` | `Future<bool>` | Checks if there's an open session |

#### Stock Movement Operations
| Function | Return Type | Description |
|----------|-------------|-------------|
| `insertStockMovement(movement)` | `Future<int>` | Creates a stock movement record |
| `getSessionMovements(sessionId)` | `Future<List<StockMovement>>` | Gets all movements for a session |
| `getMovementByProduct(sessionId, productId)` | `Future<StockMovement?>` | Gets movement for a specific product |
| `updateStockMovementSoldGrams(sessionId, productId, additionalGrams)` | `Future<int>` | Adds sold grams to a movement |
| `updateStockMovementClosing(movementId, closingGrams)` | `Future<int>` | Records closing stock and calculates variance |
| `getStockReport(sessionId)` | `Future<Map<String, dynamic>>` | Gets full stock report with totals |
| `allMovementsHaveClosingStock(sessionId)` | `Future<bool>` | Checks if all products have closing stock |

---

## Summary Statistics

| Category | Count |
|----------|-------|
| **Models** | 10 classes |
| **Providers** | 6 classes |
| **Services** | 3 classes |
| **Database** | 1 helper class |
| **Screens** | 11 screens |
| **Total Functions** | ~100+ methods |
