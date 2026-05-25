package com.gaokao.cockpit.ui.theme

import androidx.compose.ui.graphics.Color

// ==================== 主题色（时段）====================
val MorningGreen = Color(0xFF34C759)
val AfternoonBlue = Color(0xFF007AFF)
val EveningIndigo = Color(0xFF5856D6)
val NightPurple = Color(0xFFAF52DE)

// ==================== 主题色（状态）====================
val AchievementOrange = Color(0xFFFF9500)
val LowEnergyBlue = Color(0xFF5A78A6)

// ==================== 语义色 ====================
val Success = Color(0xFF34C759)
val Warning = Color(0xFFFF9500)
val Error = Color(0xFFFF3B30)
val Info = Color(0xFF007AFF)

// ==================== 任务/错题状态色 ====================
val Pending = Color(0xFFFF9500)
val InProgress = Color(0xFF007AFF)
val Done = Color(0xFF34C759)
val Skipped = Color(0xFF8E8E93)

// ==================== 中性色（亮色模式）====================
val BackgroundLight = Color(0xFFF2F2F7)
val SurfaceLight = Color(0xFFFFFFFF)
val SurfaceVariantLight = Color(0xFFF2F2F7)
val OnSurfaceLight = Color(0xFF000000)
val OnSurfaceVariantLight = Color(0xFF3C3C43)
val OutlineLight = Color(0xFFE5E5EA)
val SeparatorLight = Color(0xFFC6C6C8)

// ==================== 中性色（暗色模式）====================
val BackgroundDark = Color(0xFF000000)
val SurfaceDark = Color(0xFF1C1C1E)
val SurfaceVariantDark = Color(0xFF2C2C2E)
val OnSurfaceDark = Color(0xFFFFFFFF)
val OnSurfaceVariantDark = Color(0xFFEBEBF5)
val OutlineDark = Color(0xFF38383A)
val SeparatorDark = Color(0xFF48484A)

// ==================== 阴影色 ====================
val ShadowColorLight = Color(0xFF000000)
val ShadowColorDark = Color(0xFF000000)

// ==================== 标签背景色 ====================
fun tagBackground(color: Color): Color = color.copy(alpha = 0.15f)

// ==================== 卡片背景色 ====================
val CardBackgroundLight = Color(0xFFFFFFFF)
val CardBackgroundDark = Color(0xFF1C1C1E)

// ==================== 低能量模式专用 ====================
val LowEnergyBackgroundLight = LowEnergyBlue.copy(alpha = 0.12f)
val LowEnergyBackgroundDark = LowEnergyBlue.copy(alpha = 0.20f)

// ==================== 成就模式专用 ====================
val AchievementBackgroundLight = AchievementOrange.copy(alpha = 0.12f)
val AchievementBackgroundDark = AchievementOrange.copy(alpha = 0.20f)
