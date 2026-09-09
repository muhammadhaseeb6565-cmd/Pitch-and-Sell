<div align="center">
  <h1>🚀 Pitch & Sell</h1>
  <p><strong>The Ultimate Video-First Social Commerce Platform</strong></p>
</div>

---

Pitch & Sell is a revolutionary, dual-mode (Buyer/Seller) mobile commerce application built with **Flutter** and powered by **Supabase**. It merges the highly engaging, infinite-scroll video experience of TikTok with a fully functional, real-time e-commerce engine. 

Buyers can endlessly discover products via engaging video pitches, while sellers have a comprehensive dashboard to track analytics, manage inventory, schedule billboard promotions, and interact with customers in real-time.

---

## 🌟 Key Features

### 🛍️ Customer Experience
- **TikTok-Style Video Feed:** Infinite vertical scrolling feed featuring auto-playing product pitches, demos, and reviews.
- **Save for Later (Watchlist):** Instantly bookmark favorite pitch videos to your profile with a single tap.
- **Real-Time Notifications:** Instant alerts for social interactions (likes, follows, comments, and orders).
- **Seamless Checkout:** Full shopping cart system directly integrated with **Stripe** via secure Supabase Edge Functions.
- **Deep Linking:** Shareable links that instantly route users directly to a specific product or pitch video within the app.
- **Dynamic Theming:** Seamlessly toggle between a custom Dark UI (optimized for video viewing) and a crisp Light Mode.

### 💼 Seller Experience
- **Dual-Mode Architecture:** Switch from Buyer to Seller mode instantly with a single toggle—no separate app required.
- **Seller Dashboard:** Interactive KPI cards displaying Total Views, Engagement Rate, Revenue, and Follower growth.
- **Pitch Management:** Upload real pitch videos, generate AI-assisted scripts, and permanently delete/manage active pitches from your storefront.
- **Billboard Promotions:** Schedule paid, premium promotional slots for your products to boost visibility.
- **Wallet & Payouts:** Track accumulated earnings, pending clearances, and manage withdrawals.
- **Real-Time Chat:** A direct messaging interface to negotiate and communicate with buyers.

### 🛡️ Admin & Security
- **Admin Portal:** Secure portal for moderating platform activity.
- **Legal Enforcement:** Built-in Terms & Conditions enforcement layer for legacy and new users.

---

## 🛠️ Technology Stack

### Frontend Framework
- **[Flutter](https://flutter.dev/):** UI toolkit for building natively compiled applications from a single codebase.
- **[Dart](https://dart.dev/):** The programming language underlying Flutter.
- **State Management:** `provider` and `shared_preferences`.
- **Media Handling:** `video_player` and `image_picker`.

### Backend & Infrastructure
- **[Supabase](https://supabase.com/):** Full Open-Source Firebase alternative handling Postgres Database, Auth, Real-time WebSockets, and Storage.
- **Supabase Edge Functions:** Deno-based edge computing used for secure Stripe payment webhooks and push notifications.
- **Stripe:** Fully integrated payment gateway for processing credit card transactions.
- **PostgreSQL:** Relational database with advanced Row Level Security (RLS) policies and triggers.

---

## 🏗️ Project Architecture & Structure

The codebase strictly follows a feature-first, separation-of-concerns pattern to maintain enterprise-level scalability.

```text
Pitch and Sell/
├── .github/workflows/       # CI/CD pipelines (Automated APK builds)
├── docs/                    # PRDs, Feature Specs, Legal Drafts
├── supabase/                # Database migrations & Edge Functions
├── mobile_app/              # Main Flutter Application
│   ├── android/             # Android native configuration
│   ├── ios/                 # iOS native configuration
│   └── lib/
│       ├── constants/       # App-wide constants and color schemes
│       ├── models/          # Business logic data models
│       ├── providers/       # State management classes
│       ├── screens/         # Individual UI pages & flows
│       ├── services/        # Supabase API integrations & business logic
│       ├── widgets/         # Reusable UI components
│       └── main.dart        # Application entry point
├── render.yaml              # Hosting configuration
└── README.md                # Project documentation
```

---

## 💻 Local Setup & Installation

Follow these steps to run the project locally on your machine.

### 1. Prerequisites
- Install **Flutter** (version 3.10+ recommended). [Installation Guide](https://docs.flutter.dev/get-started/install).
- Install **Android Studio** (for the Android SDK and Emulator) or **Xcode** (for iOS).
- Verify your environment:
  ```bash
  flutter doctor
  ```

### 2. Clone the Repository
```bash
git clone https://github.com/muhammadhaseeb6565-cmd/Pitch-and-Sell.git
cd "Pitch and Sell/mobile_app"
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Configure Environment Variables
You will need your Supabase and Stripe API keys to connect to the backend. Ensure you configure your `.env` or constant files as directed in the developer documentation.

### 5. Run the App
Launch an Android/iOS emulator or connect a physical device, then run:
```bash
flutter run
```

---

## 🤖 CI/CD & Automated Builds

We use **GitHub Actions** to automate the build and distribution process.

1. Navigate to the **[Actions](../../actions)** tab in this repository.
2. Select the **Build APK** workflow.
3. Click **Run workflow** (Manual trigger to save resources).
4. Once completed, scroll to the bottom of the run to the **Artifacts** section and download the `app-release.apk` zip file.

---

<div align="center">
  <p>Built with ❤️ for Pitch & Sell</p>
</div>
