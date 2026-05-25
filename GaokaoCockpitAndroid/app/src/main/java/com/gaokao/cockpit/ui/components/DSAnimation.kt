package com.gaokao.cockpit.ui.components

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween

/**
 * 设计系统动画规范 —— 统一曲线定义
 * 对标 iOS 版 DesignSystem.Animation
 */
object DSAnimation {

    /**
     * 弹性动画 —— 用于按钮点击、卡片展开、状态切换
     * 类似 iOS spring(response: 0.3, dampingFraction: 0.7)
     */
    val Spring = spring<Float>(
        dampingRatio = 0.7f,
        stiffness = 300f,
        visibilityThreshold = 0.01f
    )

    /**
     * 平滑动画 —— 用于进度条、颜色过渡、布局变化
     * 类似 iOS easeInOut(duration: 0.3)
     */
    val Smooth = tween<Float>(
        durationMillis = 300,
        easing = FastOutSlowInEasing
    )

    /**
     * 快速动画 —— 用于开关切换、Snackbar、小元素变化
     * 类似 iOS easeInOut(duration: 0.2)
     */
    val Quick = tween<Float>(
        durationMillis = 200,
        easing = FastOutSlowInEasing
    )

    /**
     * 慢速动画 —— 用于页面级过渡、主题切换
     * 类似 iOS easeInOut(duration: 0.5)
     */
    val Slow = tween<Float>(
        durationMillis = 500,
        easing = FastOutSlowInEasing
    )

    /**
     * 数字动画 —— 用于 DSAnimatedNumber
     */
    val Number = tween<Float>(
        durationMillis = 800,
        easing = FastOutSlowInEasing
    )

    /**
     * 列表项进入错开延迟
     */
    const val StaggerDelay = 80
}

/**
 * 用于 Int 类型的弹簧动画规格
 */
fun dsSpringInt() = spring<Int>(
    dampingRatio = 0.7f,
    stiffness = 300f
)
