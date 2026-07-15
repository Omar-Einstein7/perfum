# Data Model: Perfume Shop POS & Management System

> Entity definitions derived from the spec + execution-plan API contracts.

## Core Entities

### Employee
- `id` (int, PK)
- `fullName` (varchar)
- `username` (varchar, unique)
- `passwordHash` (varchar, bcrypt)
- `branchId` (int, FK → Branch)
- `permissions` (jsonb: `{ canSell, canManageSuppliers, canManageVouchers, canManageUsers, canViewReports, canViewReports2, canViewInfo }`)
- `isActive` (boolean)
- `createdAt`, `updatedAt`

### Branch
- `id` (int, PK)
- `name` (varchar)
- `address` (text, nullable)
- `isActive` (boolean)

### Category
- `id` (int, PK)
- `name` (varchar)
- `isActive` (boolean)

### Unit
- `id` (int, PK)
- `name` (varchar)
- `symbol` (varchar)

### Material
- `id` (int, PK)
- `materialName` (varchar)
- `categoryId` (int, FK → Category)
- `unitId` (int, FK → Unit)
- `purchasePrice` (numeric(12,2))
- `retailPrice` (numeric(12,2))
- `wholesalePrice` (numeric(12,2))
- `isBottle` (boolean, default false)
- `emptyBottlePrice` (numeric(12,2), nullable)
- `lowStockThreshold` (numeric(12,3), default 5)
- `isActive` (boolean)

### MaterialBranchStock
- `id` (int, PK)
- `materialId` (int, FK → Material)
- `branchId` (int, FK → Branch)
- `currentQuantity` (numeric(12,3))
- `updatedAt` (timestamp)
- **Unique constraint**: (materialId, branchId)

### Customer
- `id` (int, PK)
- `fullName` (varchar)
- `phone` (varchar, nullable)
- `address` (text, nullable)
- `type` (enum: retail / wholesale)
- `openingBalance` (numeric(12,2), default 0)
- `isActive` (boolean)

### Supplier
- `id` (int, PK)
- `fullName` / `companyName` (varchar)
- `phone` (varchar, nullable)
- `address` (text, nullable)
- `openingBalance` (numeric(12,2), default 0)
- `isActive` (boolean)

## Transaction Entities

### Shift
- `id` (int, PK)
- `branchId` (int, FK → Branch)
- `employeeId` (int, FK → Employee)
- `openedAt` (timestamp)
- `closedAt` (timestamp, nullable)
- `openingBalance` (numeric(12,2), default 0)
- `closingBalance` (numeric(12,2), nullable)
- `status` (enum: open / closed)

### SalesInvoice (Retail)
- `id` (int, PK)
- `clientGeneratedUuid` (uuid, unique)
- `invNumber` (int, auto-sequence per branch)
- `branchId` (int, FK → Branch)
- `employeeId` (int, FK → Employee)
- `shiftId` (int, FK → Shift)
- `customerPersonName` (varchar)
- `customerPhone` (varchar, nullable)
- `paymentMethod` (enum: cash / credit)
- `giftDiscount` (numeric(12,2), default 0)
- `specialDiscount` (numeric(12,2), default 0)
- `beforeDiscount` (numeric(12,2)) — computed server-side
- `afterGiftDiscount` (numeric(12,2)) — computed server-side
- `finalTotal` (numeric(12,2)) — computed server-side
- `createdAt` (timestamp)
- `syncedAt` (timestamp, nullable)
- `syncStatus` (enum: pending / synced / failed)

### SalesInvoiceLineItem
- `id` (int, PK)
- `invoiceId` (int, FK → SalesInvoice)
- `materialId` (int, FK → Material)
- `quantity` (numeric(12,3))
- `unitPrice` (numeric(12,2))
- `cardDiscount` (numeric(12,2), default 0)
- `giftDiscount` (numeric(12,2), default 0)
- `sellDiscountPct` (numeric(5,2), default 0)
- `isEmptyBottleLine` (boolean, default false)
- `notes` (text, nullable)

### WholesaleInvoice
- Same structure as SalesInvoice but:
  - No shiftId (wholesale does not require shift)
  - No isEmptyBottleLine logic
  - unitPrice defaults from wholesalePrice

### PurchaseInvoice
- `id` (int, PK)
- `clientGeneratedUuid` (uuid, unique)
- `branchId` (int, FK → Branch)
- `employeeId` (int, FK → Employee)
- `supplierId` (int, FK → Supplier)
- `total` (numeric(12,2)) — computed server-side
- `createdAt` (timestamp)
- `syncStatus` (enum: pending / synced / failed)

### PurchaseInvoiceLineItem
- `id` (int, PK)
- `purchaseInvoiceId` (int, FK → PurchaseInvoice)
- `materialId` (int, FK → Material)
- `quantity` (numeric(12,3))
- `unitPrice` (numeric(12,2))

### PurchaseReturn
- `id` (int, PK)
- `originalInvoiceId` (int, FK → PurchaseInvoice)
- `branchId` (int, FK → Branch)
- `employeeId` (int, FK → Employee)
- `reason` (text, nullable)
- `createdAt` (timestamp)

### PurchaseReturnLineItem
- `id` (int, PK)
- `returnId` (int, FK → PurchaseReturn)
- `materialId` (int, FK → Material)
- `quantity` (numeric(12,3))
- `unitPrice` (numeric(12,2))

### PaymentVoucher
- `id` (int, PK)
- `clientGeneratedUuid` (uuid, unique)
- `branchId` (int, FK → Branch)
- `employeeId` (int, FK → Employee)
- `supplierId` (int, FK → Supplier)
- `amount` (numeric(12,2))
- `reference` (varchar, nullable)
- `notes` (text, nullable)
- `createdAt` (timestamp)
- `syncStatus` (enum: pending / synced / failed)

### ReceiptVoucher
- `id` (int, PK)
- `clientGeneratedUuid` (uuid, unique)
- `branchId` (int, FK → Branch)
- `employeeId` (int, FK → Employee)
- `customerId` (int, FK → Customer)
- `amount` (numeric(12,2))
- `reference` (varchar, nullable)
- `notes` (text, nullable)
- `createdAt` (timestamp)
- `syncStatus` (enum: pending / synced / failed)

### CreditLedger
- `id` (int, PK)
- `branchId` (int, FK → Branch)
- `partyType` (enum: customer / supplier)
- `partyId` (int — FK to Customer or Supplier)
- `transactionType` (enum: invoice / receipt / payment / return)
- `transactionId` (int — FK to the source document)
- `debit` (numeric(12,2), default 0)
- `credit` (numeric(12,2), default 0)
- `balanceAfter` (numeric(12,2))
- `notes` (text, nullable)
- `createdAt` (timestamp)

### SyncQueue
- `id` (int, PK)
- `clientGeneratedUuid` (uuid, unique)
- `operationType` (varchar: e.g. "sales_invoice", "purchase_invoice", "payment_voucher")
- `payload` (jsonb — full request body)
- `status` (enum: pending / synced / failed)
- `retryCount` (int, default 0)
- `lastError` (text, nullable)
- `createdAt` (timestamp)
- `syncedAt` (timestamp, nullable)

## Entity Relationships (simplified)

```
Branch 1──N Employee
Branch 1──N MaterialBranchStock
Branch 1──N Shift
Branch 1──N SalesInvoice
Branch 1──N WholesaleInvoice
Branch 1──N PurchaseInvoice
Branch 1──N PaymentVoucher
Branch 1──N ReceiptVoucher
Branch 1──N CreditLedger

Material 1──N MaterialBranchStock
Material 1──N SalesInvoiceLineItem
Material 1──N PurchaseInvoiceLineItem

Employee 1──N Shift
Employee 1──N SalesInvoice
Employee 1──N PurchaseInvoice
Employee 1──N PaymentVoucher
Employee 1──N ReceiptVoucher

Shift 1──N SalesInvoice

Customer 1──N ReceiptVoucher
Customer 1──N CreditLedger (as customer party)

Supplier 1──N PurchaseInvoice
Supplier 1──N PaymentVoucher
Supplier 1──N CreditLedger (as supplier party)
```
