# PITCH & SELL

Welcome to **Pitch & Sell** — a modern social commerce platform! 

Pitch & Sell combines the engaging experience of short-form video feeds (like TikTok/Reels) with an e-commerce backend. It allows users to browse a dynamic feed of product videos, watch live sales streams, and easily purchase items. The app includes a dual-mode system, allowing users to seamlessly switch between a "Customer" and a "Seller".

---

## 🚀 Features

### Core App Features
- **TikTok-Style Video Feed:** Endless vertical scrolling feed of product pitches and demos.
- **Dual Mode (Customer/Seller):** Instantly swap between buying products and managing your own storefront.
- **Session Persistence:** Auto-login functionality ensures you stay logged in even after closing the app.
- **Profile Management:** Set up your personal and business profiles, complete with native gallery image selection.

### Customer Experience
- **Explore:** Search for products, filter by categories (Tech, Fashion, Food, etc.), and discover trending items.
- **Shopping Cart & Checkout:** Add products to your cart, manage quantities, and proceed to a simulated checkout.
- **Order Tracking:** Keep track of past orders and view their shipping statuses.
- **Live Streams:** Watch sellers go live, interact in real-time, and buy products directly from the stream.
- **Real-time Chat:** Message sellers directly to ask questions or negotiate.

### Seller Experience
- **Seller Dashboard:** Track KPIs like views, engagement, and revenue via analytical charts.
- **Pitch Generator:** Use the AI-powered pitch generator to help write scripts for your video demos.
- **Go Live:** Start a live broadcast to sell products directly to your audience.
- **Wallet & Earnings:** Keep track of your earnings and withdraw funds.

---

## 🛠️ Technology Stack

- **Frontend Framework:** Flutter (Dart)
- **State Management:** Provider
- **Storage/Persistence:** SharedPreferences (for sessions & local data)
- **Native Integrations:** `image_picker` (for gallery access), `video_player` (for feeds)
- **Backend (Mocked):** Node.js / Express (Configured in the `backend/` directory, currently using simulated API delays in the mobile app for testing).

---

## 📱 Getting Started (Local Development)

### Prerequisites
1. **Flutter SDK:** Ensure you have the latest stable version of Flutter installed. ([Install Guide](https://docs.flutter.dev/get-started/install))
2. **Android Studio:** Required for setting up the Android SDK and emulators.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/TAHIR-PITAFI/pitch-and-sell.git
   cd "pitch and sell/mobile_app"
   ```

2. Fetch Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app on a connected device or emulator:
   ```bash
   flutter run
   ```

---

## 🏗️ Automated Builds (CI/CD)

This repository is equipped with **GitHub Actions** for Continuous Integration. 

Every time a new feature or fix is pushed to the `main` branch, a GitHub Action is triggered automatically in the background. It sets up Java, configures Flutter, builds the Android project, and generates a fresh `app-release.apk`.

**How to download the latest APK:**
1. Go to the **Actions** tab in this GitHub repository.
2. Click on the most recent successful workflow run (marked with a green checkmark ✅).
3. Scroll down to the **Artifacts** section at the bottom of the page.
4. Download the `app-release.apk` zip file, extract it, and install it on your Android device.

---

## 📂 Folder Structure

```text
pitch-and-sell/
│
├── .github/workflows/       # GitHub Actions YAML files for APK generation
├── backend/                 # Node.js Express server for API endpoints
├── mobile_app/              # Main Flutter application
│   ├── android/             # Android specific build files
│   ├── ios/                 # iOS specific build files
│   ├── lib/
│   │   ├── models/          # Data models
│   │   ├── providers/       # State management (AuthProvider, etc.)
│   │   ├── screens/         # UI Screens (Feed, Dashboard, Profile, etc.)
│   │   ├── services/        # API and Socket integrations
│   │   ├── widgets/         # Reusable UI components
│   │   └── main.dart        # App entry point
│   └── pubspec.yaml         # Flutter dependencies
└── README.md                # You are here!
```

---

*Built with ❤️ for Pitch & Sell.*
