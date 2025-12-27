# Developer Handbook - Money Tracker App

This document serves as a comprehensive guide to understanding the structure, logic, and architecture of the "Money Tracker" Flutter application. It is designed to help you handle UI/UX tasks and understand the underlying systems.

## 1. Project Overview
*   **Framework**: Flutter (Dart)
*   **State Management**: `flutter_riverpod` (Providers used for dependency injection and state)
*   **Database**: `isar` (NoSQL, local database for optimal performance)
*   **Navigation**: `go_router` (Routing logic and deep linking support)
*   **Graphs**: `fl_chart`

## 2. Directory Structure (`lib/`)
The project follows a **Feature-First Architecture**.

*   `core/`: Shared utilities, widgets, and router. (e.g., `IsarService`, `ScaffoldWithNavbar`).
*   `features/`: Contains the main business logic and UI, split by domain.
    *   `accounts/`: Account management, bucket logic, account details page.
    *   `transactions/`: Transaction CRUD, Add Transaction logic, History.
    *   `categories/`: Category management, default seeding.
    *   `dashboard/`: The main Home screen logic.
    *   `analytics/`: Charts, Graphs, and breakdown views.
    *   `subscriptions/`: Subscription management, recurrence logic.
    *   `settings/`: App preferences, backup/restore.

Each feature folder typically contains:
*   `data/`: Repositories (Database access).
*   `domain/`: Models (`.dart` and `.g.dart` generated files).
*   `presentation/`: UI Pages and Widgets.
*   `application/`: Providers (Logic glue between UI and Data).

## 3. Data Schema (Isar Models)

### Account (`features/accounts/domain/account.dart`)
Represents a financial account (Wallet, Bank, etc.).
*   `buckets`: A list of `AccountBucket` (Custom funds like "Car Fund", "Travel").
*   `reservedBalance`: A specific "locked" amount that shouldn't be spent freely.
*   `reservedLimit`: The target limit for the reserved balance.
*   `openingBalance`: Initial balance. *Current Balance is calculated dynamically (Opening + Income - Expense).*

### Transaction (`features/transactions/domain/transaction.dart`)
The core record of money movement.
*   `type`: `income`, `expense`, or `transfer`.
*   `categoryId`: Links to a Category.
*   `subscriptionId`: Links to a Subscription (if auto-generated).
*   `subTransactions`: List of splits (if a single purchase includes multiple categories).
*   `relatedTransactionId`: Used for refunds or transfers (linking the two sides).

### Subscription (`features/subscriptions/domain/subscription.dart`)
Recurring payments.
*   `repeat`: Enum (`daily`, `weekly`, `monthly`, `yearly`).
*   `accountId`: Default account to charge.

## 4. Navigation & Pages
We use `GoRouter` with a "Shell Route" for the bottom navigation bar.

**Routes (`lib/core/router/app_router.dart`):**
*   `/` (Home): `DashboardPage`
*   `/transactions`: `TransactionsPage` (History)
*   `/analytics`: `AnalyticsPage`
*   `/settings`: `SettingsPage`
*   **Sub-pages** (pushed on top):
    *   `/add-transaction`: `AddTransactionPage` (The complex form)
    *   `/account-details`: `AccountDetailsPage`
    *   `/subscriptions`: `SubscriptionsPage`

**Visual Navigation (`lib/core/widgets/scaffold_with_navbar.dart`):**
The Bottom Bar has **5 items**, but only **4 real tabs**.
1.  **Dashboard** (Route `/`)
2.  **History** (Route `/transactions`)
3.  **Add (+)**: This is **NOT** a tab. It acts as a button that pushes `/add-transaction` immediately.
4.  **Analysis** (Route `/analytics`)
5.  **Settings** (Route `/settings`)

## 5. Core Business Logic

### The Bucketing System (Unique Feature)
Money isn't just one big pile; it's segregated into tiers for smarter spending.

1.  **Spendable**: Free cash you can use.
2.  **Custom Buckets**: Specific funds (e.g., "Holiday").
3.  **Reserved**: Emergency/Locked funds.

**Logic in `AddTransactionPage`:**
*   **Income**:
    1.  **Fills Reserved First** (up to `reservedLimit`).
    2.  **Fills Custom Bucket** (if user selects one).
    3.  **Rest goes to Spendable**.
*   **Expense**:
    1.  **Deducts from Spendable First**.
    2.  **Deducts from Custom Buckets** (user warning if Spendable empty).
    3.  **Deducts from Reserved** (critical warning if everything else empty).

### Analytics Logic
*   **Accounting View**: Calculation = `Income - Expense`. (Ignores Transfers). Shows if you are earning more than spending.
*   **Cash Flow View**: Calculation = `Total In - Total Out`. (Includes Transfers). Shows actual movement of money.

### Subscriptions
*   **Virtual Projection**: The app doesn't create future transactions in the database database until they happen (or you click "Pay Now").
*   **Status**: The app checks the *history* of transactions to see if a transaction exists near the `due date` to mark it as `Paid` or `Missed`.

## 6. How to Work on This App
*   **UI Changes**: Most UI is in `presentation/` folders. Edit `_page.dart` files for screens and `widgets/` for components.
*   **Logic Changes**: If editing how data is saved, check `add_transaction_page.dart` (for immediate logic) or `..._repository.dart` files (for database logic).
*   **Schema Changes**: If you add fields to `Account` or `Transaction`, you **MUST** run:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
    This regenerates the `.g.dart` files required by Isar.

Good luck! The codebase is structured to be modular, so you can focus on one feature at a time.
