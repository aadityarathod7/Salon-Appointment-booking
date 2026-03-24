package com.salon.booking.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Brand Colors - Rose Gold Salon Theme
val Brand = Color(0xFFB85C6B)
val BrandDark = Color(0xFF8C384D)
val BrandLight = Color(0xFFEBC0C7)
val BrandContainer = Color(0xFFFAF0F2)

// Accent - Warm Gold
val Accent = Color(0xFFCCA666)
val AccentLight = Color(0xFFF2E0B8)

// Neutrals
val SurfaceBg = Color(0xFFF5F0ED)
val CardBg = Color(0xFFFAF8F5)
val TextPrimary = Color(0xFF2A2421)
val TextSecondary = Color(0xFF736B66)

// Semantic
val Success = Color(0xFF4DB078)
val Warning = Color(0xFFE5AD40)
val Danger = Color(0xFFD94D4D)

// Dark mode variants
val BrandDarkMode = Color(0xFFE8A0AD)
val BrandDarkSurface = Color(0xFF3D2028)
val DarkSurface = Color(0xFF1C1917)
val DarkCard = Color(0xFF292524)

private val LightColorScheme = lightColorScheme(
    primary = Brand,
    onPrimary = Color.White,
    primaryContainer = BrandContainer,
    onPrimaryContainer = BrandDark,
    secondary = Accent,
    onSecondary = Color.White,
    secondaryContainer = AccentLight,
    onSecondaryContainer = Color(0xFF5C4A28),
    tertiary = Color(0xFF60736A),
    background = SurfaceBg,
    onBackground = TextPrimary,
    surface = Color.White,
    onSurface = TextPrimary,
    surfaceVariant = CardBg,
    onSurfaceVariant = TextSecondary,
    outline = Color(0xFFD4CBC5),
    error = Danger,
    onError = Color.White,
)

private val DarkColorScheme = darkColorScheme(
    primary = BrandDarkMode,
    onPrimary = Color(0xFF4A1525),
    primaryContainer = BrandDarkSurface,
    onPrimaryContainer = BrandLight,
    secondary = AccentLight,
    onSecondary = Color(0xFF3E2E0A),
    secondaryContainer = Color(0xFF584420),
    onSecondaryContainer = AccentLight,
    tertiary = Color(0xFFA4D1B8),
    background = DarkSurface,
    onBackground = Color(0xFFEDE0DB),
    surface = DarkCard,
    onSurface = Color(0xFFEDE0DB),
    surfaceVariant = Color(0xFF352F2D),
    onSurfaceVariant = Color(0xFFD4CBC5),
    outline = Color(0xFF9E9590),
    error = Color(0xFFFFB4AB),
    onError = Color(0xFF690005),
)

@Composable
fun SalonBookingTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
