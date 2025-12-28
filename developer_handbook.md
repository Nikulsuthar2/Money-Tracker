# Developer Handbook - Money Tracker App

This document serves as a comprehensive guide to understanding the structure, logic, and architecture of the **Money Tracker** Flutter application. It is designed to help contributors understand the codebase and maintain the high standards of the project.

## 1. Project Overview
*   **Framework**: Flutter (Dart) (Min SDK: 3.0.0)
*   **State Management**: `flutter_riverpod` (Providers for dependency injection and reactive state)
*   **Database**: `isar` (NoSQL, highly performant local storage)
*   **Navigation**: `go_router` (Deep linking and declarative routing)
*   **Charts**: `fl_chart` (Interactive financial graphs)
*   **Security**: `local_auth` (Biometric protection)

## 2. Directory Structure (`lib/`)
The project utilizes a scalable **Feature-First Architecture**, ensuring code isolation and maintainability.

*   `core/`: Shared utilities, global widgets, themes, and router configuration.
    *   `database/`: Isar service initialization.
    *   `providers/`: Global state (Currency, Theme, Security).
    *   `widgets/`: Reusable UI components (`ScaffoldWithNavbar`, `AppCard`).
*   `features/`: Contains domain-specific logic, split by feature:
    *   `accounts/`: Wallet/Bank management, fund allocation logic.
    *   `transactions/`: CRUD operations, Add/Edit logic, History views.
    *   `categories/`: Category management, icon/color pickers.
    *   `dashboard/`: Home screen aggregation and summary cards.
    *   `analytics/`: Trends, Spending breakdown, Calendar view.
    *   `subscriptions/`: Recurring payment logic and virtual history generation.
    *   `settings/`: App configuration, Backup/Restore (JSON), Security settings.

**Feature Internal Structure:**
Each feature typically follows this pattern:
*   `data/`: Repositories (`_repository.dart`) handling direct database interactions.
*   `domain/`: Data Models (`model.dart` and auto-generated `.g.dart`).
*   `presentation/`: UI Pages (`_page.dart`) and feature-specific Widgets.
*   `application/`: Providers (`_providers.dart`) bridging UI and Data layers.

## 3. Data Schema (Isar Models)

### Account (`features/accounts/domain/account.dart`)
Represents a financial container (e.g., Wallet, Bank Account).
*   `buckets`: List of `AccountBucket` (Custom allocation funds like "Travel", "Car").
*   `reservedBalance`: Restricted funds within the account.
*   `openingBalance`: Initial amount. *Current Balance = Opening + Income - Expense.*

### Transaction (`features/transactions/domain/transaction.dart`)
The central record of financial movement.
*   `type`: `income`, `expense`, or `transfer`.
*   `subTransactions`: Support for **Split Transactions** (multiple categories in one entry).
*   `relatedTransactionId`: Links transactions (e.g., Original Expense <-> Refund).
*   `subscriptionId`: Links to source Subscription.

### Category (`features/categories/domain/category.dart`)
*   `type`: `income`, `expense`, or `common` (available for both).
*   `icon` & `color`: stored as integers (CodePoint/ARGB).

## 4. Navigation & Routing
We use **GoRouter** with a ShellRoute pattern for persistent bottom navigation.

**Key Routes (`lib/core/router/app_router.dart`):**
*   `/` (Home): Dashboard
*   `/transactions`: History Table/List
*   `/analytics`: Reports & Charts
*   `/settings`: Configuration
*   **Modals/Sub-pages**: `/add-transaction`, `/account-details`, `/categories`, `/subscriptions`.

## 5. Core Business Logic

### The Bucketing System
A unique feature that segments account balances into "Tiers" of availability:
1.  **Spendable**: Free-to-use cash.
2.  **Custom Buckets**: User-defined funds (e.g., "Holiday Fund").
3.  **Reserved**: Emergency/Locked funds.

**Logic Flow (`AddTransactionPage`):**
*   **Income**: Fills **Reserved** (to limit) -> Fills **Custom Bucket** (optional) -> Rest to **Spendable**.
*   **Expense**: Deducts **Spendable** -> Deducts **Custom Buckets** -> Deducts **Reserved** (with warnings).

### Refund System
Handles the complex logic of reverting payments or splitting shared costs.
*   **Refund Mode**: A dedicated UI state in `AddTransactionPage` that locks the type to Income and fields to Read-Only.
*   **Logic**:
    *   **Full Refund**: Reverses the entire transaction.
    *   **Split Repayment**: For split expenses, allows repaying specific items (e.g., "friend paid me back").
    *   **Smart Labels**: "Got Back" vs "Repay" vs "Reverse" based on context.

### Virtual Subscriptions
To keep the database clean, future subscription payments are **not** pre-generated.
*   **History**: Calculated on-the-fly by projecting the `startDate` forward based on the `repeat` interval.
*   **Status**: The app checks the *actual* transaction history against these projected dates to determine if a period is "Paid" or "Due".

## 6. Development Workflow
1.  **Modify Models**: If you edit any class annotated with `@collection` or `@embedded`, run:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
2.  **State Updates**: Use `ref.read/watch` for state. Avoid large `setState` calls in complex widgets.
3.  **UI Components**: Use the defined `Theme.of(context)` to maintain Material 3 consistency.

## 7. Release Process
To prepare a release for GitHub:
1.  **Update Version**: Bump version in `pubspec.yaml` (e.g., `5.0.0+1`).
2.  **Build Android**:
    ```bash
    flutter build apk --release
    ```
3.  **Build Windows**:
    ```bash
    flutter build windows --release
    ```
4.  **Upload**: Create a new Release tag on GitHub and upload the artifacts.

Happy Coding! 🚀
