package com.gaokao.cockpit.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import androidx.hilt.navigation.compose.hiltViewModel
import com.gaokao.cockpit.viewmodel.ThemeViewModel

private val LightColorScheme = lightColorScheme(
    primary = AfternoonBlue,
    secondary = EveningIndigo,
    tertiary = AchievementOrange,
    background = BackgroundLight,
    surface = SurfaceLight,
    surfaceVariant = SurfaceVariantLight,
    onSurface = OnSurfaceLight,
    onSurfaceVariant = OnSurfaceVariantLight,
    outline = OutlineLight,
    error = Error,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = OnSurfaceLight,
    onError = Color.White
)

private val DarkColorScheme = darkColorScheme(
    primary = AfternoonBlue,
    secondary = EveningIndigo,
    tertiary = AchievementOrange,
    background = BackgroundDark,
    surface = SurfaceDark,
    surfaceVariant = SurfaceVariantDark,
    onSurface = OnSurfaceDark,
    onSurfaceVariant = OnSurfaceVariantDark,
    outline = OutlineDark,
    error = Error,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = OnSurfaceDark,
    onError = Color.White
)

@Composable
fun GaokaoCockpitTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val viewModel: ThemeViewModel = hiltViewModel()
    val currentTheme by viewModel.currentTheme.collectAsState()
    val isDynamicEnabled by viewModel.isDynamicEnabled.collectAsState()

    val baseColorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    // 如果启用了动态主题且不是 Material You 动态取色，用 ThemeManager 的主题色覆盖 primary
    val colorScheme = remember(baseColorScheme, currentTheme, isDynamicEnabled, dynamicColor) {
        if (isDynamicEnabled && !(dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)) {
            baseColorScheme.copy(primary = currentTheme.color)
        } else {
            baseColorScheme
        }
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        LaunchedEffect(colorScheme, darkTheme) {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
