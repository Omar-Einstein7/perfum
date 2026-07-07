/// Centralized route path constants for GoRouter.
/// All paths are UI routes (browser URL). API paths are NOT stored here.
/// API base URL (including /api/v1) comes from .env -> AppConfig.
abstract final class AppRoutes {
  AppRoutes._();

  // --- Public (no auth required) ---
  static const String login          = '/login';
  static const String signUp         = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding     = '/onboarding';

  // --- Core (any authenticated user) ---
  static const String dashboard      = '/';

  // --- Lookups (canEditMasters = 32) ---
  static const String units          = '/units';
  static const String unitNew        = '/units/new';
  static const String unitDetail     = '/units/:id';
  static const String unitEdit       = '/units/:id/edit';
  static const String categories     = '/categories';

  // --- Inventory (canEditMasters = 32) ---
  static const String materials      = '/materials';
  static const String materialDetail = '/materials/:id';

  // --- Parties (canEditMasters = 32) ---
  static const String suppliers      = '/suppliers';
  static const String supplierDetail = '/suppliers/:id';
  static const String customers      = '/customers';
  static const String customerDetail = '/customers/:id';

  // --- Branches (canEditMasters = 32) ---
  static const String branches       = '/branches';

  // --- Purchases (canViewPurchases=4, canEditPurchases=8) ---
  static const String purchases      = '/purchases';
  static const String purchaseNew    = '/purchases/new';
  static const String purchaseDetail = '/purchases/:id';

  // --- Sales (canViewSales=1, canEditSales=2) ---
  static const String sales          = '/sales';
  static const String saleNew        = '/sales/new';
  static const String saleDetail     = '/sales/:id';

  // --- Vouchers ---
  static const String paymentVouchers    = '/payment-vouchers';
  static const String paymentVoucherNew  = '/payment-vouchers/new';
  static const String receiptVouchers    = '/receipt-vouchers';
  static const String receiptVoucherNew  = '/receipt-vouchers/new';

  // --- Transfers (canEditPurchases = 8) ---
  static const String transfers      = '/transfers';
  static const String transferNew    = '/transfers/new';

  // --- Reports (canViewStock = 16) ---
  static const String stock          = '/stock';
  static const String ledger         = '/ledger';
  static const String reports        = '/reports';

  // --- Helpers for parametric routes ---
  static String materialDetailPath(String id)  => '/materials/$id';
  static String supplierDetailPath(String id)  => '/suppliers/$id';
  static String customerDetailPath(String id)  => '/customers/$id';
  static String purchaseDetailPath(String id)  => '/purchases/$id';
  static String saleDetailPath(String id)      => '/sales/$id';
}
