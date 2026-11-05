# Keep Razorpay classes
-keep class com.razorpay.** { *; }
-keepclassmembers class com.razorpay.** { *; }

# Keep analytics and event classes
-keep class com.razorpay.Analytics* { *; }
-keepclassmembers class com.razorpay.Analytics* { *; }

# Keep classes with @Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# Specifically keep ProGuard annotations if used
-keep class proguard.annotation.** { *; }
-dontwarn proguard.annotation.**

# Keep CheckoutActivity and related
-keep class com.razorpay.CheckoutActivity { *; }

# Google Pay (Tez) in-app API is provided by the Google Pay app at runtime.
# Prevent R8 from failing on these classes referenced by Razorpay's GPay integration.
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }

# Play Services Wallet (sometimes referenced transitively)
-dontwarn com.google.android.gms.wallet.**
-keep class com.google.android.gms.wallet.** { *; }

# OkHttp/Okio/Gson common keeps (defensive for networking libs used by gateways)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class com.google.gson.** { *; }

-keep class com.stripe.** { *; }
-dontwarn com.reactnativestripesdk.**

# Firebase Auth / Phone OTP
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# Play Core split install warnings
-dontwarn com.google.android.play.core.**

# Flutter Engine & Plugins
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Geolocator & Location services
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }

# Connectivity Plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Microsoft Clarity
-keep class com.microsoft.clarity.** { *; }
-dontwarn com.microsoft.clarity.**

# Paystack
-keep class co.paystack.android.** { *; }
-dontwarn co.paystack.android.**
