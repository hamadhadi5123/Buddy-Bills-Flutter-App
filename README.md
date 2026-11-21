# 📱 Buddy Bills — Professional Expense Management & Bill Splitting App

> Inspired by Splitwise. Built with **Flutter & Dart**, featuring the **Midnight Emerald** theme, advanced debt simplification algorithms, dynamic equal/unequal bill splitting, complete Firebase Authentication system, and Cloud Firestore schemas.

---

## 🌟 Key Features

### 1. 🔐 Comprehensive Authentication System
- **Email & Password**: Registration, Login, and validation.
- **Google Sign-In**: One-click Google authentication flow.
- **Phone OTP**: 6-digit SMS OTP verification workflow with resend timers.
- **Password Reset**: Forgot password flow with email link dispatch.
- **Session & Profile Management**: Switch account, guest/demo login as Hamad, profile editing (name, phone).

### 2. 🗂️ 4 Main Navigation Tabs
- **Groups**: Create trips (e.g., *Murree Trip*, *Hostel Flat 4B*), manage roommates, track collective spending.
- **Friends**: Individual balances, tracking who owes you and who you owe across all groups.
- **Activity**: Audit trail of every expense, settlement, and group update.
- **Account**: Profile management, Midnight Emerald Dark Mode toggle, lifetime spending stats, and project details.

### 3. ⚡ Smart Split Calculation Engine
- **Equal Split**: Automatically distributes amounts equally ($Total \div N$) with remainder handling.
- **Unequal Split**: Custom share per member with real-time discrepancy validation.
- **`includePayerInSplit` Switch**: Critical business logic toggle allowing the payer to either share the expense or divide it entirely among other participants.
- **Debt Simplification**: Calculates minimum cash flows so friends can settle up with the fewest possible transactions.
- **Expense Deletion**: Direct deletion of expenses with confirmation and instant recalculation of balances.

### 4. 🎨 Design & Theme
- **Dark Mode**: Midnight Indigo Background (`#0B1A12`), Emerald Cards (`#113322`), Accent Green (`#27C46E`).
- **Light Mode**: Modern clean aesthetic with green branding (`#F4F7F5`).
- **Material 3**: Rounded cards, subtle borders, custom avatars with initials.

---

## 📁 Project Structure

```
F:\Projects\buddy_bills\
├── android\                               # Android platform project configuration
│   ├── app\
│   │   ├── src\main\AndroidManifest.xml   # App name, permissions, launcher config
│   │   └── build.gradle                   # Gradle app build config
│   ├── build.gradle                       # Top-level Gradle config
│   └── settings.gradle                    # Gradle plugins & SDK paths
├── firestore.rules                        # Cloud Firestore security rules
├── pubspec.yaml                           # Flutter configuration & dependencies
├── README.md                              # Complete technical documentation
├── test\
│   └── split_calculator_test.dart         # Unit tests verifying calculations
└── lib\
    ├── main.dart                          # App Entrypoint, MultiProvider & Auth Gating
    ├── core\
    │   ├── theme\
    │   │   ├── app_colors.dart            # Midnight Emerald palette
    │   │   └── app_theme.dart             # Material 3 Dark & Light themes
    │   └── utils\
    │       ├── currency_formatter.dart    # Format PKR / Rs.
    │       └── split_calculator.dart      # Core split & debt simplification math
    ├── models\
    │   ├── activity_model.dart            # Activity log item
    │   ├── balance_model.dart             # Individual balances & debt relations
    │   ├── expense_model.dart             # Expense entity with split rules
    │   ├── group_model.dart               # Group / Trip entity
    │   └── user_model.dart                # User entity
    ├── providers\
    │   ├── app_state_provider.dart        # Reactive state, seed data & operations
    │   ├── auth_provider.dart             # Email, Google, Phone OTP auth logic
    │   └── theme_provider.dart            # Theme mode toggle
    ├── screens\
    │   ├── auth\
    │   │   ├── forgot_password_screen.dart # Password reset flow
    │   │   ├── login_screen.dart           # Email, Google, Phone OTP, Demo login
    │   │   ├── phone_otp_screen.dart       # SMS OTP verification screen
    │   │   └── register_screen.dart        # User registration screen
    │   ├── main_nav_screen.dart           # Bottom navigation coordinator (4 tabs)
    │   ├── groups\
    │   │   ├── groups_screen.dart         # Group list & balance summary card
    │   │   └── group_detail_screen.dart   # Expenses, Balances & Settle up tabs
    │   ├── friends\
    │   │   └── friends_screen.dart        # Friends list & individual debts
    │   ├── expenses\
    │   │   ├── add_expense_screen.dart    # Equal/Unequal split + includePayerInSplit
    │   │   └── settle_up_dialog.dart      # Quick settlement dialog
    │   ├── activity\
    │   │   └── activity_screen.dart       # Transaction history
    │   └── account\
    │       └── account_screen.dart        # Profile & Theme switcher
    ├── services\
    │   └── firebase_service.dart          # Firestore collections & data schemas
    └── widgets\
        ├── balance_summary_card.dart      # Hero balance card
        ├── expense_tile.dart              # Interactive expense item
        └── user_avatar.dart               # Initials-based avatar
```

---

## 🚀 How to Run

1. Open a terminal in the project directory:
   ```bash
   cd "F:\Projects\buddy_bills"
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```
4. Run Unit Tests:
   ```bash
   flutter test
   ```

---

## 🧪 Mathematical Verification

In the seed data for **Murree Trip**:
* **Hamad** paid **Rs. 6,000** for Hotel (Share = Rs. 2,000).
* **Friend A** paid **Rs. 3,000** for Dinner (Share = Rs. 1,000).
* **Friend B** paid **Rs. 1,500** for Transport (Share = Rs. 500).

**Total Group Spending:** Rs. 10,500  
**Each Member's Equal Total Share:** Rs. 3,500

$$\text{Balance} = \text{Paid} - \text{Share}$$

* **Hamad:** $6000 - 3500 = \mathbf{+Rs.\ 2,500}$ (Receives)
* **Friend A:** $3000 - 3500 = \mathbf{-Rs.\ 500}$ (Owes)
* **Friend B:** $1500 - 3500 = \mathbf{-Rs.\ 2,000}$ (Owes)

**Settlement Debts:**
1. Friend A pays Hamad Rs. 500.
2. Friend B pays Hamad Rs. 2,000.  
*(All debts simplified to exactly 2 transactions).*
