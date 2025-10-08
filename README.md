# Ice Cream POS System

A comprehensive Point of Sale (POS) system built with Flutter that works both online and offline, featuring attendance tracking with location validation.

## Features

### 🛒 Point of Sale (POS)
- **Product Management**: Add, edit, and manage products with categories
- **Shopping Cart**: Add/remove products, adjust quantities
- **Payment Processing**: Support for multiple payment methods (Cash, Card, UPI, Wallet)
- **Customer Information**: Store customer name and phone number
- **Tax Calculation**: Automatic tax calculation (10%)
- **Receipt Generation**: Detailed order receipts

### 📊 Sales Management
- **Sales History**: View all sales transactions
- **Sales Analytics**: Total sales, transaction count, and average sale value
- **Detailed Reports**: View individual sale details with items and totals

### ⏰ Attendance System
- **Location-Based Attendance**: Mark attendance only within specified coordinates
- **Check-in/Check-out**: Track staff arrival and departure times
- **Location Validation**: Prevent attendance marking from unauthorized locations
- **Attendance History**: View all attendance records with timestamps

### 🔄 Offline/Online Sync
- **Local Storage**: Hive database for offline functionality
- **Automatic Sync**: Sync data with Firebase when internet is available
- **Conflict Resolution**: Handles data synchronization between local and cloud storage
- **Real-time Updates**: Live connectivity status indicator

### 👥 User Management
- **Role-Based Access**: Admin and Staff user roles
- **Location Configuration**: Set allowed attendance locations per user
- **User Profiles**: Store user information and preferences

## Technology Stack

- **Framework**: Flutter
- **State Management**: BLoC (Business Logic Component)
- **Local Database**: Hive
- **Cloud Database**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Location Services**: Geolocator
- **Connectivity**: Connectivity Plus

## Getting Started

### Prerequisites
- Flutter SDK (3.7.2 or higher)
- Firebase project setup
- Android/iOS development environment

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ice_cream
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Firebase Setup**
   - Create a Firebase project
   - Add your app to the Firebase project
   - Download and place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in their respective directories
   - Enable Firestore and Authentication in Firebase Console

5. **Run the app**
   ```bash
   flutter run

### Initial Setup
1. Launch the app
2. Complete the setup form with your details
3. Set your allowed attendance location (latitude, longitude, radius)
4. Optionally load sample data for testing

### POS Operations
1. Navigate to the POS tab
2. Browse products by category or search
3. Add products to cart
4. Adjust quantities as needed
5. Process payment with customer details

### Attendance Tracking
1. Go to the Attendance tab
2. Ensure location permissions are granted
3. Verify you're within the allowed location
4. Mark check-in or check-out

### Viewing Sales
1. Navigate to the Sales tab
2. View all transactions
3. Use filters to find specific sales
4. Tap on any sale for detailed information

## Configuration

### Location Settings
- **Latitude/Longitude**: Set the center point for attendance marking
- **Radius**: Define the allowed area in meters (default: 100m)

### User Roles
- **Admin**: Full access to all features, can manage products and users
- **Staff**: Limited access for POS operations and attendance marking

### Payment Methods
- Cash
- Card
- UPI
- Wallet

## Offline Capabilities

The app works seamlessly offline:
- All data is stored locally using Hive
- Sales and attendance can be recorded without internet
- Data automatically syncs when connection is restored
- Visual indicator shows sync status

## Firebase Collections

- **products**: Product catalog
- **sales**: Sales transactions
- **attendance**: Attendance records
- **users**: User profiles and settings

## Permissions

### Android
- Location permissions for attendance tracking
- Internet permission for Firebase sync


For support and questions, please open an issue in the repository.

---

**Note**: This is a demo application. For production use, ensure proper security measures, data validation, and error handling are implemented.
