# Rules for release builds (R8 shrinks the app). Required by flutter_stripe.
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.google.android.gms.tapandpay.**
-dontwarn kotlinx.parcelize.Parceler$DefaultImpls
-dontwarn kotlinx.parcelize.Parceler
-dontwarn kotlinx.parcelize.Parcelize
# Keep Stripe classes
-keep class com.stripe.** { *; }
