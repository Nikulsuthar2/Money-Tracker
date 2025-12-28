# 🐛 Issues & Enhancements

## 📱 UI & Responsive Design
- [ ] **Desktop Responsiveness**: Improve layout adaptability for larger screens (Windows/Web).
- [ ] **Navigation Cleanup**: The "+ FAB" appears redundantly in both the Sidebar and Bottom Navigation. It should only appear where contextually appropriate.
- [ ] **Analytics UI**: Fix alignment issues within the "Net Result Card" on the Analytics Page.

## 📊 Charts & Data Visualization
- [ ] **Graph Variety (Analytics)**: Implement different chart types (Bar, Line, Pie) across the main Analytics section.
- [ ] **Graph Variety (Account Details)**: Add Bar, Line, and Pie charts to the Account Details analysis section.
- [ ] **Dynamic Graph Filtering**: In Account Details, graphs should update dynamically based on the History segmented button (All vs Income vs Expense).

## 💸 Transactions & Logic
- [ ] **Sorting Order**: Transactions are not sorting strictly by date. Newest transactions must stack on top (Date Descending), ignoring time differences if they cause disorder.
- [ ] **Split Transaction UI**: Group split transaction items into a distinct "Card" section in the Transaction Details page for better isolation.
- [ ] **Fund Allocation UI**: Improve the visual design of the Fund Allocation section in the "Add Account" page.
- [ ] **Budget Logic Bug**: Users receive a "Funds Exceeded" warning even when sufficient Spendable balance is available for normal expenses.

## 🔄 Refunds & Recouping
- [ ] **Partial Refund Logic**: The "Get Back" feature is broken; it offers a full refund even after a partial refund has already been recorded.
- [ ] **Refund Mode Context**: The "Refund Mode" banner/state only triggers via the main "Get Back" button, not when initiating a refund from an individual split item.
- [ ] **UI Bug**: "Refunded" and "Undo" buttons are incorrectly visible on all expense transactions.

## 📅 Subscriptions
- [ ] **Subscription Logic**: 
    - Fix duplicate payout prompts (asking for same payment multiple times).
    - Implement auto-creation for past-due start dates: The app should automatically generate past transactions up to the current date without requiring user confirmation for each one.
- [ ] **Subscription Details**: Remove "Refunded" and "Undo" buttons from Subscription-generated transaction details.