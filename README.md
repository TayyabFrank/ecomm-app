# E-Commerce App (Flutter)

A high-performance, responsive e-commerce mobile and web application built with Flutter.

## Features

- **Product Catalog & Details**: Browse products by category, view rich product details and ratings.
- **Cart & Checkout**: Real-time cart management, state handling with Provider, and streamlined checkout.
- **User Authentication**: Firebase Authentication for secure sign-in and registration.
- **Cloud Firestore Integration**: Real-time data sync for products, orders, and user profiles.
- **Admin Management Panel**: Admin tools for orders, product management, and activity logs.
- **Local Notifications**: In-app alerts and notifications using `flutter_local_notifications`.
- **Currency & Performance Optimizations**: Real-time currency conversions, background isolates, and performance dashboards.

## Tech Stack

- **Framework**: Flutter & Dart (SDK `>=3.3.0 <4.0.0`)
- **State Management**: `provider`
- **Backend / Services**: Firebase (Auth, Firestore, Core)
- **Networking & Utilities**: `http`, `cached_network_image`, `encrypt`, `intl`, `logger`

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/TayyabFrank/ecomm-app.git
   cd ecomm-app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.