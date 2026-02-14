# Butcher Admin Dashboard - Viewing Salesman Sales

This document explains how a butcher shop admin can view sales data from their salesmen using the Laravel backend.

---

## Data Flow Overview

```
┌─────────────────┐      Sync       ┌─────────────────┐
│  Flutter App    │ ──────────────► │  Laravel API    │
│  (Offline POS)  │                 │  (Backend)      │
└─────────────────┘                 └─────────────────┘
        │                                   │
        │ Records sales with:               │ Stores in database:
        │ - butcher_id                      │ - butcher_shops
        │ - user_id                         │ - users
        │ - sale_number                     │ - sales
        │ - items                           │ - sale_items
        │                                   │
        ▼                                   ▼
   Local SQLite                      MySQL/PostgreSQL
```

---

## Database Structure (Laravel)

### Migration: Butcher Shops Table

```php
Schema::create('butcher_shops', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('address')->nullable();
    $table->string('phone')->nullable();
    $table->string('license_number')->nullable();
    $table->boolean('is_active')->default(true);
    $table->timestamps();
});
```

### Migration: Users Table

```php
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->foreignId('butcher_id')->constrained('butcher_shops');
    $table->string('username')->unique();
    $table->string('password');
    $table->string('full_name');
    $table->enum('role', ['admin', 'manager', 'cashier'])->default('cashier');
    $table->boolean('is_active')->default(true);
    $table->timestamps();
    
    $table->unique(['butcher_id', 'username']);
});
```

### Migration: Sales Table

```php
Schema::create('sales', function (Blueprint $table) {
    $table->id();
    $table->foreignId('butcher_id')->constrained('butcher_shops');
    $table->foreignId('user_id')->constrained('users');
    $table->string('sale_number');
    $table->decimal('total_amount', 10, 2);
    $table->enum('payment_method', ['Cash', 'EcoCash', 'Card']);
    $table->timestamp('sale_date');
    $table->timestamps();
    
    $table->unique(['butcher_id', 'sale_number']);
});
```

### Migration: Sale Items Table

```php
Schema::create('sale_items', function (Blueprint $table) {
    $table->id();
    $table->foreignId('sale_id')->constrained()->onDelete('cascade');
    $table->string('product_name');
    $table->integer('weight_grams');
    $table->decimal('price_per_kg', 10, 2);
    $table->decimal('total_price', 10, 2);
    $table->timestamps();
});
```

---

## API Endpoint: Receive Synced Sales

### Route

```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/sales/sync', [SalesSyncController::class, 'sync']);
});
```

### Controller

```php
// app/Http/Controllers/SalesSyncController.php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Models\SaleItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SalesSyncController extends Controller
{
    public function sync(Request $request)
    {
        $request->validate([
            'sales' => 'required|array',
            'sales.*.butcher_id' => 'required|integer|exists:butcher_shops,id',
            'sales.*.user_id' => 'required|integer|exists:users,id',
            'sales.*.sale_number' => 'required|string',
            'sales.*.total_amount' => 'required|numeric',
            'sales.*.payment_method' => 'required|in:Cash,EcoCash,Card',
            'sales.*.created_at' => 'required|date',
            'sales.*.items' => 'required|array',
        ]);

        $synced = [];
        $errors = [];

        DB::beginTransaction();
        
        try {
            foreach ($request->sales as $saleData) {
                // Check for duplicate sale_number within the same butcher shop
                $exists = Sale::where('butcher_id', $saleData['butcher_id'])
                    ->where('sale_number', $saleData['sale_number'])
                    ->exists();

                if ($exists) {
                    $errors[] = "Sale {$saleData['sale_number']} already exists";
                    continue;
                }

                // Create sale
                $sale = Sale::create([
                    'butcher_id' => $saleData['butcher_id'],
                    'user_id' => $saleData['user_id'],
                    'sale_number' => $saleData['sale_number'],
                    'total_amount' => $saleData['total_amount'],
                    'payment_method' => $saleData['payment_method'],
                    'sale_date' => $saleData['created_at'],
                ]);

                // Create sale items
                foreach ($saleData['items'] as $item) {
                    SaleItem::create([
                        'sale_id' => $sale->id,
                        'product_name' => $item['product_name'],
                        'weight_grams' => $item['weight_grams'],
                        'price_per_kg' => $item['price_per_kg'],
                        'total_price' => $item['total_price'],
                    ]);
                }

                $synced[] = $saleData['sale_number'];
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'synced' => $synced,
                'errors' => $errors,
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Sync failed: ' . $e->getMessage(),
            ], 500);
        }
    }
}
```

---

## Admin Dashboard: Viewing Salesman Sales

### Route (Web)

```php
// routes/web.php
Route::middleware(['auth', 'admin'])->prefix('admin')->group(function () {
    Route::get('/dashboard', [AdminDashboardController::class, 'index']);
    Route::get('/sales', [AdminDashboardController::class, 'sales']);
    Route::get('/sales/by-user/{userId}', [AdminDashboardController::class, 'salesByUser']);
    Route::get('/salesmen', [AdminDashboardController::class, 'salesmen']);
    Route::get('/daily-summary', [AdminDashboardController::class, 'dailySummary']);
});
```

### Controller

```php
// app/Http/Controllers/AdminDashboardController.php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminDashboardController extends Controller
{
    /**
     * Get the admin's butcher shop ID
     */
    private function getButcherId()
    {
        return Auth::user()->butcher_id;
    }

    /**
     * Dashboard Overview
     */
    public function index()
    {
        $butcherId = $this->getButcherId();
        $today = now()->toDateString();

        $data = [
            'today_sales' => Sale::where('butcher_id', $butcherId)
                ->whereDate('sale_date', $today)
                ->sum('total_amount'),
                
            'today_transactions' => Sale::where('butcher_id', $butcherId)
                ->whereDate('sale_date', $today)
                ->count(),
                
            'active_salesmen' => User::where('butcher_id', $butcherId)
                ->where('role', 'cashier')
                ->where('is_active', true)
                ->count(),
                
            'recent_sales' => Sale::where('butcher_id', $butcherId)
                ->with('user:id,full_name')
                ->orderBy('sale_date', 'desc')
                ->limit(10)
                ->get(),
        ];

        return view('admin.dashboard', $data);
    }

    /**
     * All Sales for this Butcher Shop
     */
    public function sales(Request $request)
    {
        $butcherId = $this->getButcherId();
        
        $query = Sale::where('butcher_id', $butcherId)
            ->with(['user:id,full_name', 'items']);

        // Filter by date range
        if ($request->has('from') && $request->has('to')) {
            $query->whereBetween('sale_date', [$request->from, $request->to]);
        }

        // Filter by payment method
        if ($request->has('payment_method')) {
            $query->where('payment_method', $request->payment_method);
        }

        // Filter by salesman
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        $sales = $query->orderBy('sale_date', 'desc')->paginate(20);

        return view('admin.sales', compact('sales'));
    }

    /**
     * Sales by Specific Salesman
     */
    public function salesByUser($userId)
    {
        $butcherId = $this->getButcherId();

        // Verify the user belongs to this butcher shop
        $salesman = User::where('id', $userId)
            ->where('butcher_id', $butcherId)
            ->firstOrFail();

        $sales = Sale::where('butcher_id', $butcherId)
            ->where('user_id', $userId)
            ->with('items')
            ->orderBy('sale_date', 'desc')
            ->paginate(20);

        $summary = [
            'total_sales' => Sale::where('user_id', $userId)->sum('total_amount'),
            'total_transactions' => Sale::where('user_id', $userId)->count(),
            'today_sales' => Sale::where('user_id', $userId)
                ->whereDate('sale_date', now())
                ->sum('total_amount'),
        ];

        return view('admin.sales-by-user', compact('salesman', 'sales', 'summary'));
    }

    /**
     * List All Salesmen with Performance
     */
    public function salesmen()
    {
        $butcherId = $this->getButcherId();

        $salesmen = User::where('butcher_id', $butcherId)
            ->where('role', '!=', 'admin')
            ->withCount('sales')
            ->withSum('sales', 'total_amount')
            ->get()
            ->map(function ($user) {
                $user->today_sales = Sale::where('user_id', $user->id)
                    ->whereDate('sale_date', now())
                    ->sum('total_amount');
                return $user;
            });

        return view('admin.salesmen', compact('salesmen'));
    }

    /**
     * Daily Summary with Breakdown by Salesman
     */
    public function dailySummary(Request $request)
    {
        $butcherId = $this->getButcherId();
        $date = $request->get('date', now()->toDateString());

        // Overall summary
        $overall = [
            'total_amount' => Sale::where('butcher_id', $butcherId)
                ->whereDate('sale_date', $date)
                ->sum('total_amount'),
            'transaction_count' => Sale::where('butcher_id', $butcherId)
                ->whereDate('sale_date', $date)
                ->count(),
            'cash_total' => Sale::where('butcher_id', $butcherId)
                ->whereDate('sale_date', $date)
                ->where('payment_method', 'Cash')
                ->sum('total_amount'),
            'ecocash_total' => Sale::where('butcher_id', $butcherId)
                ->whereDate('sale_date', $date)
                ->where('payment_method', 'EcoCash')
                ->sum('total_amount'),
            'card_total' => Sale::where('butcher_id', $butcherId)
                ->whereDate('sale_date', $date)
                ->where('payment_method', 'Card')
                ->sum('total_amount'),
        ];

        // Breakdown by salesman
        $byUser = Sale::where('butcher_id', $butcherId)
            ->whereDate('sale_date', $date)
            ->selectRaw('user_id, SUM(total_amount) as total, COUNT(*) as count')
            ->groupBy('user_id')
            ->with('user:id,full_name')
            ->get();

        return view('admin.daily-summary', compact('overall', 'byUser', 'date'));
    }
}
```

---

## Sample Blade Views

### Salesmen List View

```blade
{{-- resources/views/admin/salesmen.blade.php --}}
@extends('layouts.admin')

@section('content')
<div class="container">
    <h1>My Salesmen</h1>
    
    <table class="table">
        <thead>
            <tr>
                <th>Name</th>
                <th>Role</th>
                <th>Today's Sales</th>
                <th>Total Sales</th>
                <th>Transactions</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            @foreach($salesmen as $salesman)
            <tr>
                <td>{{ $salesman->full_name }}</td>
                <td>{{ ucfirst($salesman->role) }}</td>
                <td>${{ number_format($salesman->today_sales, 2) }}</td>
                <td>${{ number_format($salesman->sales_sum_total_amount ?? 0, 2) }}</td>
                <td>{{ $salesman->sales_count }}</td>
                <td>
                    <a href="/admin/sales/by-user/{{ $salesman->id }}" class="btn btn-primary btn-sm">
                        View Sales
                    </a>
                </td>
            </tr>
            @endforeach
        </tbody>
    </table>
</div>
@endsection
```

### Daily Summary View

```blade
{{-- resources/views/admin/daily-summary.blade.php --}}
@extends('layouts.admin')

@section('content')
<div class="container">
    <h1>Daily Summary - {{ $date }}</h1>
    
    <div class="row mb-4">
        <div class="col-md-3">
            <div class="card">
                <div class="card-body">
                    <h5>Total Sales</h5>
                    <h2>${{ number_format($overall['total_amount'], 2) }}</h2>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card">
                <div class="card-body">
                    <h5>Transactions</h5>
                    <h2>{{ $overall['transaction_count'] }}</h2>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card">
                <div class="card-body">
                    <h5>Cash</h5>
                    <h2>${{ number_format($overall['cash_total'], 2) }}</h2>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card">
                <div class="card-body">
                    <h5>EcoCash</h5>
                    <h2>${{ number_format($overall['ecocash_total'], 2) }}</h2>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="card">
                <div class="card-body">
                    <h5>Card</h5>
                    <h2>${{ number_format($overall['card_total'], 2) }}</h2>
                </div>
            </div>
        </div>
    </div>

    <h3>Sales by Salesman</h3>
    <table class="table">
        <thead>
            <tr>
                <th>Salesman</th>
                <th>Transactions</th>
                <th>Total Amount</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            @foreach($byUser as $row)
            <tr>
                <td>{{ $row->user->full_name }}</td>
                <td>{{ $row->count }}</td>
                <td>${{ number_format($row->total, 2) }}</td>
                <td>
                    <a href="/admin/sales/by-user/{{ $row->user_id }}?date={{ $date }}">
                        View Details
                    </a>
                </td>
            </tr>
            @endforeach
        </tbody>
    </table>
</div>
@endsection
```

---

## Security: Data Isolation

**Important:** Each admin can ONLY see data from their own butcher shop.

```php
// Middleware to ensure data isolation
// app/Http/Middleware/EnsureButcherAccess.php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureButcherAccess
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        
        // If accessing a specific butcher's data, verify ownership
        if ($request->route('butcherId')) {
            if ($user->butcher_id != $request->route('butcherId')) {
                abort(403, 'Access denied to this butcher shop data');
            }
        }
        
        return $next($request);
    }
}
```

---

## Summary

| Feature | How Admin Sees It |
|---------|-------------------|
| **All Shop Sales** | `/admin/sales` - All sales from their butcher shop |
| **Salesman List** | `/admin/salesmen` - All cashiers with performance metrics |
| **Specific Salesman** | `/admin/sales/by-user/{id}` - All sales by one salesman |
| **Daily Summary** | `/admin/daily-summary` - Breakdown by payment method & salesman |
| **Filter Options** | Date range, payment method, specific salesman |

The admin **cannot** see sales from other butcher shops - data is isolated by `butcher_id`.
