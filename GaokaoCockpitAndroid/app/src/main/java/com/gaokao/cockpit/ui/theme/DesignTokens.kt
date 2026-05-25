package com.gaokao.cockpit.ui.theme

import androidx.compose.ui.unit.dp

/**
 * 设计系统基础 Token —— 间距、圆角、阴影、尺寸规范
 * 基于 4dp 基准，对标 iOS 版 DesignSystem
 */
object DesignTokens {

    // ==================== 间距系统 ====================
    object Spacing {
        val xxs = 2.dp
        val xs = 4.dp
        val sm = 8.dp
        val md = 12.dp
        val lg = 16.dp
        val xl = 20.dp
        val xxl = 24.dp
        val xxxl = 32.dp
    }

    // ==================== 圆角系统 ====================
    object CornerRadius {
        val small = 6.dp
        val medium = 8.dp
        val large = 12.dp
        val xlarge = 16.dp
        val xxlarge = 20.dp
        val full = 1000.dp // 用于胶囊形、圆形
    }

    // ==================== 阴影系统 ====================
    object Elevation {
        val none = 0.dp
        val small = 2.dp
        val medium = 4.dp
        val large = 8.dp
        val xlarge = 16.dp
    }

    // ==================== 尺寸系统 ====================
    object Size {
        val iconSmall = 16.dp
        val iconMedium = 20.dp
        val iconLarge = 24.dp
        val iconXLarge = 32.dp

        val buttonHeight = 48.dp
        val buttonHeightSmall = 36.dp

        val inputHeight = 56.dp
        val inputHeightMin = 92.dp

        val cardMinHeight = 64.dp
        val chipHeight = 32.dp

        val progressBarHeight = 8.dp
        val progressRingSize = 80.dp
        val progressRingStroke = 8.dp
    }

    // ==================== 透明度 ====================
    object Alpha {
        const val disabled = 0.38f
        const val pressed = 0.12f
        const val hover = 0.08f
        const val focus = 0.12f
        const val divider = 0.12f
        const val hint = 0.6f
        const val placeholder = 0.4f
    }
}
