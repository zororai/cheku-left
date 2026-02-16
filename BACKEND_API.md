# Cheku Left POS - Backend API Specification

**Version:** 1.0.0  
**Base URL:** `https://chekuleftpos.co.zw`  
**Authentication:** Bearer Token (JWT)

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [Products](#2-products)
3. [Sales](#3-sales)
4. [Stock Sessions](#4-stock-sessions)
5. [Device Registration](#5-device-registration)
6. [License & Subscription](#6-license--subscription)
7. [Super Admin Panel](#7-super-admin-panel)
8. [Error Handling](#8-error-handling)
9. [Database Schema](#9-database-schema)

---

## 1. Authentication

### 1.1 Login

**Endpoint:** `POST /api/login`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com",
    "role": "cashier",
    "butcher_id": 1,
    "butcher": {
      "id": 1,
      "name": "Main Street Butchery",
      "address": "123 Main Street",
      "phone": "+263 77 123 4567"
    }
  }
}
```

**Error Responses:**

| Status | Response |
|--------|----------|
| 401 | `{"success": false, "message": "Invalid credentials"}` |
| 403 | `{"success": false, "message": "Subscription expired"}` |
| 403 | `{"success": false, "message": "Account suspended"}` |
| 422 | `{"success": false, "message": "Validation error", "errors": {...}}` |

### 1.2 Logout

**Endpoint:** `POST /api/logout`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## 2. Products

### 2.1 Get Products

**Endpoint:** `GET /api/products`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| butcher_id | int | Filter by butcher shop |
| active_only | bool | Only return active products |

**Response (200):**
```json
{
  "success": true,
  "products": [
    {
      "id": 1,
      "butcher_id": 1,
      "name": "Beef",
      "price_per_kg": 8.00,
      "is_active": true,
      "created_at": "2026-01-01T00:00:00Z",
      "updated_at": "2026-01-15T10:30:00Z"
    },
    {
      "id": 2,
      "butcher_id": 1,
      "name": "Pork",
      "price_per_kg": 6.50,
      "is_active": true,
      "created_at": "2026-01-01T00:00:00Z",
      "updated_at": "2026-01-15T10:30:00Z"
    }
  ]
}
```

### 2.2 Sync Products (From App to Server)

**Endpoint:** `POST /api/products/sync`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
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
    },
    {
      "id": 3,
      "name": "Chicken",
      "price_per_kg": 5.00,
      "is_active": 1
    },
    {
      "id": null,
      "name": "Goat",
      "price_per_kg": 9.00,
      "is_active": 1
    }
  ]
}
```

**Notes:**
- Products with `id: null` are new products to be created
- Products with existing `id` should be updated (upsert)

**Response (200):**
```json
{
  "success": true,
  "message": "Products synced successfully",
  "synced_count": 4,
  "created_count": 1,
  "updated_count": 3
}
```

---

## 3. Sales

### 3.1 Sync Sales (From App to Server)

**Endpoint:** `POST /api/sales/sync`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
{
  "sales": [
    {
      "butcher_id": 1,
      "user_id": 1,
      "sale_number": "CL-0001",
      "total_amount": 25.50,
      "payment_method": "cash",
      "created_at": "2026-02-15T10:30:00Z",
      "items": [
        {
          "product_id": 1,
          "product_name": "Beef",
          "weight_grams": 500,
          "price_per_kg": 8.00,
          "total_price": 4.00
        },
        {
          "product_id": 2,
          "product_name": "Pork",
          "weight_grams": 1000,
          "price_per_kg": 6.50,
          "total_price": 6.50
        }
      ]
    },
    {
      "butcher_id": 1,
      "user_id": 1,
      "sale_number": "CL-0002",
      "total_amount": 15.00,
      "payment_method": "ecocash",
      "created_at": "2026-02-15T11:00:00Z",
      "items": [
        {
          "product_id": 3,
          "product_name": "Chicken",
          "weight_grams": 3000,
          "price_per_kg": 5.00,
          "total_price": 15.00
        }
      ]
    }
  ]
}
```

**Payment Methods:**
- `cash`
- `ecocash`
- `innbucks`
- `swipe`

**Response (200):**
```json
{
  "success": true,
  "message": "Sales synced successfully",
  "synced_count": 2,
  "synced_sale_numbers": ["CL-0001", "CL-0002"]
}
```

**Duplicate Handling:**
- If `sale_number` already exists for the `butcher_id`, skip or update
- Return list of already synced sale numbers

### 3.2 Get Sales

**Endpoint:** `GET /api/sales`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| butcher_id | int | Required - Filter by butcher shop |
| date | string | Filter by date (YYYY-MM-DD) |
| from_date | string | Filter from date |
| to_date | string | Filter to date |
| user_id | int | Filter by user |
| payment_method | string | Filter by payment method |

**Response (200):**
```json
{
  "success": true,
  "sales": [
    {
      "id": 1,
      "butcher_id": 1,
      "user_id": 1,
      "user_name": "John Cashier",
      "sale_number": "CL-0001",
      "total_amount": 25.50,
      "payment_method": "cash",
      "created_at": "2026-02-15T10:30:00Z",
      "items": [...]
    }
  ],
  "summary": {
    "total_amount": 1250.00,
    "total_transactions": 45,
    "by_payment_method": {
      "cash": 800.00,
      "ecocash": 350.00,
      "innbucks": 100.00
    }
  }
}
```

---

## 4. Stock Sessions

### 4.1 Open Day (Start Stock Session)

**Endpoint:** `POST /api/stock-sessions/open`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
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
```

**Response (200):**
```json
{
  "success": true,
  "message": "Stock session opened",
  "session_id": 123,
  "local_session_id": 1
}
```

### 4.2 Close Day (End Stock Session)

**Endpoint:** `POST /api/stock-sessions/close`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
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
```

**Variance Calculation:**
```
variance_grams = closing_grams - expected_closing_grams
expected_closing_grams = opening_grams - sold_grams

Positive variance: More stock than expected
Negative variance: Less stock than expected (loss/theft)
```

**Response (200):**
```json
{
  "success": true,
  "message": "Stock session closed",
  "session_id": 123,
  "total_variance_grams": -500,
  "variance_by_product": [
    {"product_id": 1, "product_name": "Beef", "variance_grams": -500},
    {"product_id": 2, "product_name": "Pork", "variance_grams": 0},
    {"product_id": 3, "product_name": "Chicken", "variance_grams": 0}
  ]
}
```

### 4.3 Get Stock Sessions (History)

**Endpoint:** `GET /api/stock-sessions`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| butcher_id | int | Required - Filter by butcher shop |
| from_date | string | Filter from date |
| to_date | string | Filter to date |
| status | string | `open` or `closed` |

**Response (200):**
```json
{
  "success": true,
  "sessions": [
    {
      "id": 123,
      "butcher_id": 1,
      "user_id": 1,
      "user_name": "John Doe",
      "status": "closed",
      "opened_at": "2026-02-15T08:00:00Z",
      "closed_at": "2026-02-15T18:00:00Z",
      "notes": "Normal day",
      "total_opening_grams": 45000,
      "total_sold_grams": 16000,
      "total_closing_grams": 28500,
      "total_variance_grams": -500,
      "stock_movements": [...]
    }
  ]
}
```

---

## 5. Device Registration

### 5.1 Register Device

**Endpoint:** `POST /api/devices/register`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
{
  "butcher_id": 1,
  "user_id": 1,
  "device_id": "abc123-unique-device-id",
  "device_name": "Samsung Galaxy S21",
  "device_model": "SM-G991B",
  "os_version": "Android 13",
  "app_version": "1.0.0"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Device registered",
  "device_id": "abc123-unique-device-id",
  "registered_at": "2026-02-15T10:00:00Z"
}
```

---

## 6. License & Subscription

### 6.1 Check License Status

**Endpoint:** `GET /api/license/status`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| butcher_id | int | Required |

**Response (200):**
```json
{
  "success": true,
  "license": {
    "butcher_id": 1,
    "plan": "premium",
    "status": "active",
    "is_locked": false,
    "payment_count": 45,
    "payment_limit": 100,
    "remaining_payments": 55,
    "expires_at": "2026-12-31T23:59:59Z"
  }
}
```

### 6.2 Unlock License

**Endpoint:** `POST /api/license/unlock`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
{
  "butcher_id": 1,
  "unlock_code": "ABC123XYZ"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "License unlocked",
  "new_payment_limit": 200,
  "remaining_payments": 155
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "Invalid unlock code"
}
```

---

## 7. Super Admin Panel

This section covers endpoints for managing butcher shops, licenses, and payment limits as a **Super Admin**.

### 7.1 Admin Authentication

Super admins use a separate login or have `role: 'super_admin'` in the users table.

**Endpoint:** `POST /api/admin/login`

**Request:**
```json
{
  "email": "admin@chekuleft.co.zw",
  "password": "admin_password"
}
```

**Response (200):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "Super Admin",
    "email": "admin@chekuleft.co.zw",
    "role": "super_admin"
  }
}
```

### 7.2 List All Butcher Shops

**Endpoint:** `GET /api/admin/butcher-shops`

**Headers:**
```
Authorization: Bearer {admin_token}
```

**Response (200):**
```json
{
  "success": true,
  "butcher_shops": [
    {
      "id": 1,
      "name": "Main Street Butchery",
      "phone": "+263 77 123 4567",
      "is_active": true,
      "license": {
        "plan": "premium",
        "status": "active",
        "payment_count": 45,
        "payment_limit": 100,
        "remaining_payments": 55,
        "expires_at": "2026-12-31T23:59:59Z"
      },
      "created_at": "2026-01-01T00:00:00Z"
    }
  ]
}
```

### 7.3 Get Butcher Shop Details

**Endpoint:** `GET /api/admin/butcher-shops/{id}`

**Response (200):**
```json
{
  "success": true,
  "butcher_shop": {
    "id": 1,
    "name": "Main Street Butchery",
    "address": "123 Main Street",
    "phone": "+263 77 123 4567",
    "is_active": true,
    "users": [...],
    "devices": [...],
    "license": {...},
    "stats": {
      "total_sales": 1250.00,
      "total_transactions": 450,
      "this_month_sales": 320.00
    }
  }
}
```

### 7.4 Update Payment Limit (Reset/Extend)

**Endpoint:** `PUT /api/admin/licenses/{butcher_id}`

**Headers:**
```
Authorization: Bearer {admin_token}
Content-Type: application/json
```

**Request:**
```json
{
  "payment_limit": 100,
  "reset_count": true,
  "expires_at": "2027-12-31T23:59:59Z",
  "status": "active"
}
```

| Field | Type | Description |
|-------|------|-------------|
| payment_limit | int | New payment limit (e.g., 20, 50, 100, unlimited=999999) |
| reset_count | bool | Reset `payment_count` to 0 |
| expires_at | string | New expiry date |
| status | string | `active`, `locked`, `expired` |

**Response (200):**
```json
{
  "success": true,
  "message": "License updated",
  "license": {
    "butcher_id": 1,
    "payment_count": 0,
    "payment_limit": 100,
    "remaining_payments": 100,
    "status": "active",
    "expires_at": "2027-12-31T23:59:59Z"
  }
}
```

### 7.5 Generate Unlock Code

**Endpoint:** `POST /api/admin/unlock-codes`

**Headers:**
```
Authorization: Bearer {admin_token}
Content-Type: application/json
```

**Request:**
```json
{
  "butcher_id": 1,
  "additional_payments": 50,
  "expires_at": "2026-03-31T23:59:59Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| butcher_id | int | Optional - Lock code to specific shop |
| additional_payments | int | Payments to add when code is used |
| expires_at | string | Optional - Code expiry date |

**Response (200):**
```json
{
  "success": true,
  "unlock_code": {
    "code": "CL-UNLOCK-ABC123",
    "butcher_id": 1,
    "additional_payments": 50,
    "is_used": false,
    "expires_at": "2026-03-31T23:59:59Z",
    "created_at": "2026-02-15T10:00:00Z"
  }
}
```

### 7.6 List Unlock Codes

**Endpoint:** `GET /api/admin/unlock-codes`

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| butcher_id | int | Filter by shop |
| is_used | bool | Filter used/unused codes |

**Response (200):**
```json
{
  "success": true,
  "unlock_codes": [
    {
      "id": 1,
      "code": "CL-UNLOCK-ABC123",
      "butcher_id": 1,
      "butcher_name": "Main Street Butchery",
      "additional_payments": 50,
      "is_used": false,
      "used_at": null,
      "expires_at": "2026-03-31T23:59:59Z"
    },
    {
      "id": 2,
      "code": "CL-UNLOCK-XYZ789",
      "butcher_id": null,
      "butcher_name": null,
      "additional_payments": 100,
      "is_used": true,
      "used_at": "2026-02-10T14:30:00Z",
      "expires_at": null
    }
  ]
}
```

### 7.7 Lock/Unlock Butcher Shop

**Endpoint:** `POST /api/admin/butcher-shops/{id}/lock`

**Request:**
```json
{
  "action": "lock",
  "reason": "Payment overdue"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Butcher shop locked",
  "butcher_id": 1,
  "status": "locked"
}
```

**Unlock:**
```json
{
  "action": "unlock"
}
```

### 7.8 View Payment History

**Endpoint:** `GET /api/admin/butcher-shops/{id}/payments`

**Response (200):**
```json
{
  "success": true,
  "payments": [
    {
      "date": "2026-02-15",
      "payment_count": 15,
      "sales_total": 250.00,
      "transactions": 15
    },
    {
      "date": "2026-02-14",
      "payment_count": 12,
      "sales_total": 180.00,
      "transactions": 12
    }
  ],
  "summary": {
    "total_payments": 45,
    "payment_limit": 100,
    "remaining": 55,
    "status": "active"
  }
}
```

### 7.9 Dashboard Stats

**Endpoint:** `GET /api/admin/dashboard`

**Response (200):**
```json
{
  "success": true,
  "stats": {
    "total_butcher_shops": 25,
    "active_shops": 22,
    "locked_shops": 3,
    "total_sales_today": 5400.00,
    "total_transactions_today": 180,
    "shops_near_limit": [
      {
        "id": 5,
        "name": "Corner Butchery",
        "remaining_payments": 3
      }
    ]
  }
}
```

---

### How the 20 Payment Limit Works

```
┌─────────────────────────────────────────────────────────────┐
│                    PAYMENT LIMIT FLOW                        │
└─────────────────────────────────────────────────────────────┘

1. New shop starts with:
   - payment_count = 0
   - payment_limit = 20 (free tier)

2. Each sale increments payment_count:
   - Sale made → payment_count++
   - If payment_count >= payment_limit → LOCK

3. When locked:
   - App shows "License Locked" screen
   - User must enter unlock code OR
   - Admin increases payment_limit

4. To unlock:
   Option A: User enters unlock code
   Option B: Admin updates license directly

5. After unlock:
   - payment_limit increased (e.g., +50)
   - OR reset payment_count to 0
```

### Database Logic

```sql
-- Check if shop should be locked
SELECT 
  butcher_id,
  payment_count,
  payment_limit,
  (payment_count >= payment_limit) AS should_lock
FROM licenses
WHERE butcher_id = ?;

-- Increment payment count after sale
UPDATE licenses 
SET payment_count = payment_count + 1,
    status = CASE 
      WHEN payment_count + 1 >= payment_limit THEN 'locked'
      ELSE status
    END
WHERE butcher_id = ?;

-- Admin: Reset and extend
UPDATE licenses 
SET payment_count = 0,
    payment_limit = 100,
    status = 'active',
    expires_at = '2027-12-31'
WHERE butcher_id = ?;

-- Use unlock code
UPDATE licenses l
JOIN unlock_codes uc ON uc.code = ?
SET l.payment_limit = l.payment_limit + uc.additional_payments,
    l.status = 'active',
    uc.is_used = TRUE,
    uc.used_at = NOW()
WHERE (uc.butcher_id IS NULL OR uc.butcher_id = l.butcher_id)
  AND uc.is_used = FALSE;
```

---

## 8. Error Handling

### Standard Error Response

```json
{
  "success": false,
  "message": "Error description",
  "errors": {
    "field_name": ["Validation error message"]
  }
}
```

### HTTP Status Codes

| Status | Meaning |
|--------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized (invalid/expired token) |
| 403 | Forbidden (subscription expired, suspended) |
| 404 | Not Found |
| 422 | Validation Error |
| 500 | Server Error |

### Special 403 Cases

The app handles these specific 403 messages:

| Message | App Behavior |
|---------|--------------|
| `Subscription expired` | Redirect to Subscription Expired screen |
| `Account suspended` | Redirect to Suspended screen |

---

## 8. Database Schema

### butcher_shops
```sql
CREATE TABLE butcher_shops (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  address TEXT,
  phone VARCHAR(50),
  license_number VARCHAR(100),
  subscription_plan VARCHAR(50) DEFAULT 'free',
  subscription_status VARCHAR(50) DEFAULT 'active',
  subscription_expires_at DATETIME,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### users
```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  butcher_id BIGINT NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role ENUM('owner', 'manager', 'cashier') DEFAULT 'cashier',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (butcher_id) REFERENCES butcher_shops(id)
);
```

### products
```sql
CREATE TABLE products (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  butcher_id BIGINT NOT NULL,
  name VARCHAR(255) NOT NULL,
  price_per_kg DECIMAL(10,2) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (butcher_id) REFERENCES butcher_shops(id)
);
```

### sales
```sql
CREATE TABLE sales (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  butcher_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  sale_number VARCHAR(50) NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  payment_method VARCHAR(50) NOT NULL,
  created_at TIMESTAMP,
  FOREIGN KEY (butcher_id) REFERENCES butcher_shops(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  UNIQUE KEY unique_sale (butcher_id, sale_number)
);
```

### sale_items
```sql
CREATE TABLE sale_items (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  sale_id BIGINT NOT NULL,
  product_id BIGINT NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  weight_grams INT NOT NULL,
  price_per_kg DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id)
);
```

### stock_sessions
```sql
CREATE TABLE stock_sessions (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  butcher_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  local_session_id INT,
  status ENUM('open', 'closed') DEFAULT 'open',
  notes TEXT,
  opened_at DATETIME NOT NULL,
  closed_at DATETIME,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (butcher_id) REFERENCES butcher_shops(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### stock_movements
```sql
CREATE TABLE stock_movements (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  session_id BIGINT NOT NULL,
  product_id BIGINT NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  opening_grams INT NOT NULL,
  sold_grams INT DEFAULT 0,
  closing_grams INT,
  expected_closing_grams INT,
  variance_grams INT,
  created_at TIMESTAMP,
  FOREIGN KEY (session_id) REFERENCES stock_sessions(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id)
);
```

### devices
```sql
CREATE TABLE devices (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  butcher_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  device_id VARCHAR(255) UNIQUE NOT NULL,
  device_name VARCHAR(255),
  device_model VARCHAR(255),
  os_version VARCHAR(100),
  app_version VARCHAR(50),
  last_active_at DATETIME,
  registered_at TIMESTAMP,
  FOREIGN KEY (butcher_id) REFERENCES butcher_shops(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### licenses
```sql
CREATE TABLE licenses (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  butcher_id BIGINT UNIQUE NOT NULL,
  plan VARCHAR(50) DEFAULT 'free',
  status ENUM('active', 'locked', 'expired') DEFAULT 'active',
  payment_count INT DEFAULT 0,
  payment_limit INT DEFAULT 100,
  expires_at DATETIME,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (butcher_id) REFERENCES butcher_shops(id)
);
```

### unlock_codes
```sql
CREATE TABLE unlock_codes (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(50) UNIQUE NOT NULL,
  butcher_id BIGINT,
  additional_payments INT NOT NULL,
  is_used BOOLEAN DEFAULT FALSE,
  used_at DATETIME,
  created_at TIMESTAMP,
  FOREIGN KEY (butcher_id) REFERENCES butcher_shops(id)
);
```

---

## Notes for Backend Developer

1. **Multi-tenancy:** All data is scoped by `butcher_id`
2. **Offline-first:** App works offline, syncs when online - handle duplicates gracefully
3. **Idempotency:** Sync endpoints should handle re-submission of same data
4. **Timestamps:** All timestamps in ISO 8601 format (UTC)
5. **Token expiry:** Implement JWT with reasonable expiry (e.g., 30 days)
6. **Rate limiting:** Consider rate limiting sync endpoints

---

**Contact:** +263 77 521 9766  
**Support:** support@chekuleft.co.zw
