# Cheku Left POS - User Guide

## Table of Contents
1. [User Login](#user-login)
2. [Sync & Closing Details](#sync--closing-details)

---

## User Login

### Overview
The Cheku Left POS app uses a hybrid authentication system that supports both online and offline login.

### Login Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    USER LOGIN FLOW                          │
└─────────────────────────────────────────────────────────────┘

User enters Email + Password
              │
              ▼
    ┌─────────────────────┐
    │  Try API Login      │──────────────────┐
    │  POST /api/login    │                  │
    └─────────────────────┘                  │
              │                              │
              ▼                              ▼
    ┌─────────────────────┐        ┌─────────────────────┐
    │   API SUCCESS       │        │   NETWORK ERROR     │
    │                     │        │                     │
    │ • Save user to      │        │ • Try SQLite        │
    │   SQLite for        │        │   offline login     │
    │   offline use       │        │                     │
    │ • Store token       │        └─────────────────────┘
    │ • Go to Dashboard   │                  │
    └─────────────────────┘                  ▼
                                   ┌─────────────────────┐
                                   │  SQLITE LOGIN       │
                                   │                     │
                                   │ • Check cached      │
                                   │   credentials       │
                                   │ • If found, login   │
                                   │ • If not, show      │
                                   │   error message     │
                                   └─────────────────────┘
```

### First Time Login (Online Required)

1. Open the app
2. Enter your **email** and **password** (provided by your shop owner/admin)
3. The app connects to `https://api.chekuleft.co.zw/api/login`
4. On success:
   - Your credentials are saved locally for offline use
   - You are taken to the Dashboard

### Subsequent Logins (Offline Supported)

1. If you have logged in before on this device
2. Enter the same **email** and **password**
3. Even without internet, the app will authenticate using cached credentials
4. You can work fully offline

### Login Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Invalid credentials" | Wrong email or password | Check your credentials |
| "Subscription expired" | Shop subscription ended | Contact admin: +263 77 521 9766 |
| "Account suspended" | Account disabled | Contact admin |
| "Network error..." | No internet + no cached credentials | Connect to internet and try again |

### API Endpoint

```
POST https://api.chekuleft.co.zw/api/login

Request Body:
{
  "email": "user@example.com",
  "password": "your_password"
}

Success Response:
{
  "success": true,
  "token": "Bearer xyz...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com",
    "role": "cashier",
    "butcher_id": 1,
    "butcher": {
      "id": 1,
      "name": "My Butcher Shop"
    }
  }
}
```

---

## Sync & Closing Details

### Overview
The app works offline-first. All sales and stock data are saved locally and synced to the server when internet is available.

### Daily Stock Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    DAILY STOCK FLOW                         │
└─────────────────────────────────────────────────────────────┘

        ┌─────────────────────┐
        │     OPEN DAY        │
        │                     │
        │ • Enter opening     │
        │   stock (kg)        │
        │ • Creates new       │
        │   stock session     │
        └─────────────────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │   RECORD SALES      │
        │                     │
        │ • Each sale         │
        │   deducts from      │
        │   stock             │
        │ • Sales saved       │
        │   locally           │
        └─────────────────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │    CLOSE DAY        │
        │                     │
        │ • Enter closing     │
        │   stock (kg)        │
        │ • Calculate         │
        │   variance          │
        │ • Add notes         │
        └─────────────────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │   SYNC TO SERVER    │
        │                     │
        │ • Upload sales      │
        │ • Upload stock      │
        │   session           │
        │ • Mark as synced    │
        └─────────────────────┘
```

### Sync Process

#### Automatic Sync
- The app checks for internet connectivity
- When online, unsynced data is automatically queued for sync

#### Manual Sync
1. Go to **Dashboard** → **Sync Sales**
2. View pending (unsynced) sales count
3. Tap **Sync Now** to push data to server

### Data Synced to Server

#### 1. Products Sync
```
POST https://api.chekuleft.co.zw/api/products/sync

Request:
{
  "butcher_id": 1,
  "products": [
    {
      "id": 1,
      "name": "Beef",
      "price_per_kg": 8.00,
      "is_active": 1
    },
    {
      "id": 2,
      "name": "Pork",
      "price_per_kg": 6.50,
      "is_active": 1
    }
  ]
}

Response (200):
{
  "success": true,
  "message": "Products synced successfully"
}
```

#### 2. Sales Data
```
POST https://api.chekuleft.co.zw/api/sales/sync

Request:
{
  "sales": [
    {
      "sale_number": "CL-0001",
      "total_amount": 25.50,
      "payment_method": "cash",
      "items": [
        {
          "product_id": 1,
          "product_name": "Beef",
          "weight_grams": 500,
          "price_per_kg": 8.00,
          "total_price": 4.00
        }
      ],
      "created_at": "2026-02-15T10:30:00Z"
    }
  ]
}

Response (200):
{
  "success": true,
  "synced_count": 1
}
```

#### 3. Open Day (Stock Session Start) - Per Product
```
POST https://api.chekuleft.co.zw/api/stock-sessions/open

Request:
{
  "butcher_id": 1,
  "user_id": 1,
  "local_session_id": 1,
  "opened_at": "2026-02-15T08:00:00Z",
  "stock_movements": [
    {
      "product_id": 1,
      "product_name": "Beef",
      "opening_grams": 20000
    },
    {
      "product_id": 2,
      "product_name": "Pork",
      "opening_grams": 15000
    },
    {
      "product_id": 3,
      "product_name": "Chicken",
      "opening_grams": 10000
    }
  ]
}

Response (200):
{
  "success": true,
  "message": "Stock session opened"
}
```

#### 4. Close Day (Stock Session End) - Per Product
```
POST https://api.chekuleft.co.zw/api/stock-sessions/close

Request:
{
  "butcher_id": 1,
  "user_id": 1,
  "local_session_id": 1,
  "notes": "Normal day, no issues",
  "opened_at": "2026-02-15T08:00:00Z",
  "closed_at": "2026-02-15T18:00:00Z",
  "stock_movements": [
    {
      "product_id": 1,
      "product_name": "Beef",
      "opening_grams": 20000,
      "sold_grams": 8000,
      "closing_grams": 11500,
      "expected_closing_grams": 12000,
      "variance_grams": -500
    },
    {
      "product_id": 2,
      "product_name": "Pork",
      "opening_grams": 15000,
      "sold_grams": 5000,
      "closing_grams": 10000,
      "expected_closing_grams": 10000,
      "variance_grams": 0
    },
    {
      "product_id": 3,
      "product_name": "Chicken",
      "opening_grams": 10000,
      "sold_grams": 3000,
      "closing_grams": 7000,
      "expected_closing_grams": 7000,
      "variance_grams": 0
    }
  ]
}

Response (200):
{
  "success": true,
  "message": "Stock session closed"
}
```

### Sync Status Indicators

| Indicator | Meaning |
|-----------|---------|
| 🟢 **Online** | Connected to internet, sync available |
| 🔴 **Offline** | No internet, data saved locally |
| **X pending** | Number of unsynced sales |

### Closing Day Summary

When you close the day, the app calculates:

| Field | Description |
|-------|-------------|
| **Opening Stock** | Stock entered when day opened |
| **Total Sold** | Sum of all sales (grams) |
| **Closing Stock** | Actual stock counted at end of day |
| **Expected Stock** | Opening - Sold |
| **Variance** | Closing - Expected (difference) |

### Variance Explanation

```
Variance = Closing Stock - (Opening Stock - Total Sold)

Positive variance (+): More stock than expected (possible over-count)
Negative variance (-): Less stock than expected (possible loss/theft)
Zero variance (0): Perfect match
```

### Sync Troubleshooting

| Issue | Solution |
|-------|----------|
| Sync stuck | Check internet connection |
| "Sync failed" | Retry, check server status |
| Data not appearing on server | Ensure you're online, tap Sync |

---

## Contact Support

For technical issues:
- **Phone:** +263 77 521 9766
- **Email:** support@chekuleft.co.zw

---

*Cheku Left POS v1.0.0*
