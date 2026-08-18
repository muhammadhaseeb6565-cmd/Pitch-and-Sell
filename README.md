<div align="center">
  <h1>🛒 PITCH & SELL</h1>
  <p><strong>A Modern Social Commerce & Live Shopping Platform</strong></p>
  
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
  [![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)
</div>

<br/>

Welcome to **Pitch & Sell** — a cutting-edge social commerce application built with Flutter. 

Pitch & Sell bridges the gap between entertainment and e-commerce by combining the addictive experience of short-form video feeds (like TikTok and Instagram Reels) with a fully-fledged storefront. It allows users to browse a dynamic feed of product video pitches, watch live sales streams, and purchase items seamlessly.

---

## 📑 Table of Contents

1. [Key Features](#-key-features)
2. [Dual-Mode Architecture](#-dual-mode-architecture)
3. [Screens & User Flow](#-screens--user-flow)
4. [Technology Stack](#-technology-stack)
5. [Project Architecture & Structure](#-project-architecture--structure)
6. [Local Setup & Installation](#-local-setup--installation)
7. [CI/CD & Automated APKs](#-cicd--automated-apks)
8. [Future Roadmap](#-future-roadmap)

---

## 🚀 Key Features

- **TikTok-Style Video Feed:** Infinite vertical scrolling feed featuring auto-playing product pitches, demos, and reviews.
- **Live Streaming Commerce:** Real-time live stream viewer where sellers can interact with buyers and pin products for instant purchase.
- **Session Persistence:** Secure, automatic login functionality utilizing local device storage (`SharedPreferences`).
- **Rich Profile Management:** Set up both Personal and Business profiles. Includes native gallery image selection for profile avatars using `image_picker`.
- **Dynamic Theming:** Custom dark UI optimized for video consumption with vibrant orange (`#FF5722`) accents.
- **Cart & Order System:** Add products to cart, increment/decrement quantities, proceed through a mock checkout, and track past orders.
- **Real-Time Chat:** A direct messaging interface for buyers and sellers to negotiate and communicate.

---

## 🎭 Dual-Mode Architecture

Pitch & Sell introduces a **Single-App Dual-Mode** philosophy. Instead of building separate apps for buyers and sellers, users can instantly swap contexts via a toggle on the home screen.

### 🛍️ Customer Mode
- **Feed & Explore:** Discover new products via an algorithm-driven vertical video feed or search by categories (Tech, Fashion, Food, Handmade).
- **Shopping Cart:** Review selected items, see total prices, and checkout.
- **Order Tracking:** Monitor the status of pending shipments.

### 🏬 Seller Mode (Dashboard)
- **Analytics:** View interactive KPI cards showing Total Views, Engagement Rate, Revenue, and Follower growth.
- **Funnel Visualization:** Analyze the conversion funnel from Video Views ➔ Cart Adds ➔ Purchases.
- **Pitch Generator:** An AI-assisted tool where sellers can generate high-converting video scripts by simply inputting a product name and key selling points.
- **Wallet:** Track accumulated earnings, pending clearances, and request withdrawals.

---

## 📱 Screens & User Flow

| Screen | Description |
|--------|-------------|
| **Splash Screen** | Handles initialization, checks local storage for an active session, and dynamically routes the user to the Feed or Welcome screen. |
| **Welcome/Auth** | Features a professional login/signup UI. Users can create an account, select a role (Buyer/Seller), and pick a gallery avatar. |
| **Feed Screen** | The core landing page. Features a full-screen vertical video pager. Includes floating action buttons for liking, commenting, and adding items to the cart. |
| **Explore Screen** | A staggered grid view for discovering new shops, trending categories, and top-rated products. |
| **Profile Screen** | Displays the user's details, uploaded videos, and saved items. Includes a bottom-sheet modal to edit profile details locally. |
| **Dashboard** | The Seller's command center. Displays financial metrics, recent orders, and quick actions (Add Product, Go Live). |
| **Live Stream** | A simulated RTMP live streaming UI with floating hearts, real-time chat overlays, and a sticky "Buy Now" product card. |

---

## 🛠️ Technology Stack

### Frontend Framework
- **[Flutter](https://flutter.dev/):** UI toolkit for building natively compiled applications from a single codebase.
- **[Dart](https://dart.dev/):** The programming language underlying Flutter.

### Core Packages & Plugins
- **`provider`:** For reactive state management and dependency injection (e.g., `AuthProvider`).
- **`shared_preferences`:** For persistent, asynchronous, key-value local storage (session caching).
- **`image_picker`:** For accessing the native iOS/Android photo gallery to upload avatars.
- **`video_player`:** For rendering and controlling the auto-playing video feed.

### Backend (Currently Mocked)
- **Node.js / Express:** A backend directory (`backend/`) is initialized and ready for deployment.
- **API Service:** The app uses an `ApiService` class that simulates network latency and returns mock JSON data to ensure UI responsiveness testing.

---

## 🏗️ Project Architecture & Structure

The codebase strictly follows a feature-first, separation-of-concerns pattern.

```text
pitch-and-sell/
│
├── .github/workflows/       # CI/CD pipelines (APK automated builds)
├── backend/                 # Node.js backend environment (WIP)
├── mobile_app/              # Main Flutter Application
│   ├── android/             # Android native configuration (minSdk: 21)
│   ├── ios/                 # iOS native configuration
│   ├── lib/
│   │   ├── models/          # Dart classes representing business logic (User, Product)
│   │   ├── providers/       # State Management classes (AuthProvider)
│   │   ├── screens/         # Individual UI pages
│   │   ├── services/        # HTTP API integrations & WebSocket logic
│   │   ├── widgets/         # Reusable UI components (Buttons, VideoPlayers)
│   │   └── main.dart        # Application entry point & Provider initialization
│   └── pubspec.yaml         # Package dependencies & asset declarations
└── README.md                # Project documentation
```

---

## 💻 Local Setup & Installation

Follow these steps to run the project locally on your machine.

### 1. Prerequisites
- Install **Flutter** (version 3.10+ recommended). [Installation Guide](https://docs.flutter.dev/get-started/install).
- Install **Android Studio** (for the Android SDK and Emulator).
- Verify your environment by running:
  ```bash
  flutter doctor
  ```

### 2. Clone the Repository
```bash
git clone https://github.com/TAHIR-PITAFI/pitch-and-sell.git
cd "pitch-and-sell/mobile_app"
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the App
Launch an Android/iOS emulator or connect a physical device, then run:
```bash
flutter run
```

---

## ⚙️ CI/CD & Automated APKs

We use **GitHub Actions** to automate the build and distribution process. You never have to build the APK manually if you don't want to!

Every time code is pushed to the `main` branch, our workflow will:
1. Setup an Ubuntu runner.
2. Install the Java JDK and Flutter SDK.
3. Fetch dependencies and run static analysis (`flutter analyze`).
4. Build a signed, release-ready Android application.

### How to download the latest APK:
1. Navigate to the **[Actions](../../actions)** tab in this repository.
2. Click on the latest successful workflow run (marked with a green ✅).
3. Scroll to the bottom of the page to the **Artifacts** section.
4. Download the `app-release.apk` zip file.
5. Extract the `.apk` file, transfer it to your Android device, and install it.

---

## 🗺️ Future Roadmap

While the UI and core mock logic are fully functional, the following integrations are planned for upcoming releases:
- [ ] **Firebase Authentication:** Replace mock logins with real Google/Email sign-ins.
- [ ] **Stripe Payment Gateway:** Process real credit card transactions during checkout.
- [ ] **AWS S3 / Cloudinary:** Handle real video uploads and image hosting instead of local paths.
- [ ] **WebSockets (Socket.io):** Enable real-time, low-latency chat and live stream commenting.
- [ ] **Mux/Agora:** Integrate true RTMP live video broadcasting for sellers.

---

<div align="center">
  <p>Built with ❤️ for Pitch & Sell</p>
</div>
