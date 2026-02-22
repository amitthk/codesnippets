# Flutter Quick Reference

This reference guide provides the specific command-line workflow and configuration steps required to build, secure, and publish a Flutter app in 2026.

---

## 1. Environment Setup

### SDK Installation

1. **Flutter SDK:** Download from [flutter.dev](https://docs.flutter.dev/install) and add the `bin` folder to your system PATH.
2. **Verification:** ```bash
flutter doctor
```
*Follow the prompts to install missing dependencies (Java, Android Toolchain, etc.).*


```



### Android Setup (Android Studio)

1. **Install Android Studio:** Open **SDK Manager** > **SDK Tools**.
2. **Required Tools:** Check *Android SDK Command-line Tools*, *Android Emulator*, and *SDK Platform-Tools*.
3. **Emulator:** Open **Device Manager** > **Create Virtual Device** > Select Hardware > Download System Image (API 34+).
4. **Licenses:**
```bash
flutter doctor --android-licenses

```



### iOS Setup (macOS only)

1. **Install Xcode:** Download from the App Store.
2. **Tools & Simulator:**
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcode-select --install

```


3. **CocoaPods:**
```bash
sudo gem install cocoapods

```



---

## 2. Project Lifecycle Commands

| Command | Purpose |
| --- | --- |
| `flutter create my_app` | Generates a new Flutter project. |
| `flutter list devices` | Shows all connected physical and virtual devices. |
| `flutter pub get` | Fetches and installs dependencies from `pubspec.yaml`. |
| `flutter clean` | Deletes `build/` and `.dart_tool/` (Fixes 90% of build errors). |
| `flutter run` | Runs app on the default device/emulator. |
| `flutter run -d <id>` | Runs app on a specific device ID (from `list devices`). |

---

## 3. Firebase & OAuth Configuration

The **FlutterFire CLI** is the modern standard for configuration.

### Initialization

```bash
# Install Firebase CLI (requires Node.js)
npm install -g firebase-tools
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Project (Automates GoogleService-Info.plist and google-services.json)
flutterfire configure

```

### OAuth (Google/Apple)

1. **Firebase Console:** Go to **Authentication** > **Sign-in method** > Enable Google/Apple.
2. **Dependencies:** `flutter pub add firebase_auth google_sign_in`
3. **Android SHA-1:** ```bash
cd android && ./gradlew signingReport
```
*Copy the SHA-1 key to your Firebase Project Settings.*

```


4. **iOS Apple Sign-in:** In Xcode, go to **Runner** > **Signing & Capabilities** > **+ Capability** > **Sign In with Apple**.

---

## 4. Stripe Payments Integration

Stripe in Flutter uses the `flutter_stripe` package and a backend (Firebase Functions) to handle the `PaymentIntent`.

### Frontend Setup

1. **Install:** `flutter pub add flutter_stripe`
2. **Initialize:** ```dart
Stripe.publishableKey = "pk_test_your_key";
await Stripe.instance.applySettings();
```


```



### Backend (Firebase Functions)

1. **Initialize:** `firebase init functions` (Choose JavaScript/TypeScript).
2. **Function Logic:**
```javascript
const stripe = require('stripe')('sk_test_secret_key');
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  return await stripe.paymentIntents.create({
    amount: data.amount,
    currency: 'usd',
    automatic_payment_methods: { enabled: true },
  });
});

```


3. **Deploy:** `firebase deploy --only functions`

---

## 5. Build & Marketplace Publishing

### Android (Google Play)

1. **Keystore:** ```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

```


2. **Configure:** Map the keystore in `android/key.properties` and `android/app/build.gradle`.
3. **Build AAB:** ```bash
flutter build appbundle
```


```



### iOS (App Store)

1. **Xcode Signing:** Open `ios/Runner.xcworkspace`. Under **Signing & Capabilities**, select your Team and App ID.
2. **Build IPA:**
```bash
flutter build ipa

```


3. **Upload:** Use **Transporter** or **Xcode** > **Product** > **Archive** > **Distribute App**.


# **Stripe + Firebase Payment Implementation (Dart)**

To integrate Stripe with a Firebase backend, you need a **Payment Intent**. This script handles the frontend flow: initializing the payment sheet, calling your Firebase Function to get the "secret," and presenting the checkout to the user.

## **1. Dependencies (`pubspec.yaml`)**

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_stripe: ^10.1.1 # Use the latest 2026 version
  cloud_functions: ^5.0.0

```

## **2. Implementation Script**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Set your Stripe Publishable Key
  Stripe.publishableKey = "pk_test_your_key_here";
  await Stripe.instance.applySettings();
  
  runApp(const MaterialApp(home: StripePaymentScreen()));
}

class StripePaymentScreen extends StatelessWidget {
  const StripePaymentScreen({super.key});

  Future<void> makePayment() async {
    try {
      // 2. Call your Firebase Function to create a PaymentIntent
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('createPaymentIntent');
      final response = await callable.call({'amount': 2000, 'currency': 'usd'}); // $20.00
      
      final clientSecret = response.data['client_secret'];

      // 3. Initialize the Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Your Business Name',
        ),
      );

      // 4. Display the Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      print("Payment Successful!");
    } catch (e) {
      print("Payment Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stripe Checkout")),
      body: Center(
        child: ElevatedButton(
          onPressed: makePayment,
          child: const Text("Pay $20.00"),
        ),
      ),
    );
  }
}

```

---

### **3. Required Platform Configurations**

Before running the code above, you **must** update these files or the app will crash:

#### **Android (`android/app/src/main/kotlin/.../MainActivity.kt`)**

Stripe requires `FlutterFragmentActivity` instead of `FlutterActivity` for biometric/secure checkouts.

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}

```

#### **iOS (`ios/Runner/Info.plist`)**

Add this key to allow the payment sheet to display correctly:

```xml
<key>NSCameraUsageDescription</key>
<string>Scan cards for easier payment</string>

```

---

### **Final Checklist for Production**

* **Switch Keys:** Replace `pk_test` with `pk_live` and `sk_test` with `sk_live`.
* **Apple Merchant ID:** If using Apple Pay, register a Merchant ID in the Apple Developer Portal and add it to `initPaymentSheet`.
* **Webhooks:** Set up Stripe Webhooks in Firebase Functions to listen for `payment_intent.succeeded` events to update your database securely.

# **Firebase Cloud Function: Stripe Backend (TypeScript)**

This backend script lives in your `functions/src/index.ts` file. It securely handles your **Stripe Secret Key** to create a `PaymentIntent` and returns a `client_secret` to your Flutter app.

---

## 1. Backend Setup

1. **Navigate to functions folder:** `cd functions`
2. **Install Stripe SDK:** `npm install stripe`
3. **Set Stripe Secret Key:** ```bash
firebase functions:config:set stripe.secret="sk_test_your_secret_key"
```


```



---

## 2. The Cloud Function (`index.ts`)

```typescript
import * as functions from "firebase-functions";
import Stripe from "stripe";

// Initialize Stripe with your secret key from environment config
const stripe = new Stripe(functions.config().stripe.secret, {
  apiVersion: "2023-10-16", // Use the latest stable version
});

/**
 * Callable function to create a Stripe PaymentIntent.
 * Data expected: { amount: number, currency: string }
 */
export const createPaymentIntent = functions.https.onCall(async (data, context) => {
  // 1. Security Check: Ensure the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  try {
    const { amount, currency } = data;

    // 2. Create the PaymentIntent on Stripe's servers
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // e.g., 2000 for $20.00
      currency: currency || "usd",
      automatic_payment_methods: { enabled: true },
      // Optional: Add metadata to track the user in Stripe dashboard
      metadata: { firebaseUID: context.auth.uid },
    });

    // 3. Return the client_secret to the Flutter app
    return {
      client_secret: paymentIntent.client_secret,
    };
  } catch (error: any) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});

```

---

## 3. Handling Webhooks (Crucial for Production)

Webhooks ensure that even if a user’s app crashes during payment, your database knows the payment succeeded.

```typescript
export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"] as string;
  const endpointSecret = functions.config().stripe.webhook_secret;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err: any) {
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  // Handle the event
  if (event.type === "payment_intent.succeeded") {
    const paymentIntent = event.data.object as Stripe.PaymentIntent;
    // Logic to update your Firestore database (e.g., mark order as "paid")
    console.log(`Payment for ${paymentIntent.amount} succeeded!`);
  }

  res.json({ received: true });
});

```

---

## 4. Deployment

Deploy your functions to the cloud:

```bash
firebase deploy --only functions

```

### **Tip**

Always use **`onCall`** for your `createPaymentIntent` function. It automatically handles Firebase Authentication tokens, meaning you don't have to manually pass headers from Flutter.
