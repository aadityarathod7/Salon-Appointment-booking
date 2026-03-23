# Retrofit
-keepattributes Signature
-keepattributes *Annotation*
-keep class retrofit2.** { *; }
-keepclasseswithmembers class * { @retrofit2.http.* <methods>; }

# Gson
-keep class com.salon.booking.data.remote.dto.** { *; }
-keep class com.salon.booking.domain.model.** { *; }

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
