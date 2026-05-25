package com.gaokao.cockpit.ui.theme

import androidx.compose.ui.graphics.Color
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalTime
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 动态主题上下文 —— 根据时间段和学习状态切换主题色
 * 对标 iOS 版 ThemeContext
 */
enum class ThemeContext(
    val displayName: String,
    val color: Color,
    val description: String
) {
    Morning(
        displayName = "早晨",
        color = MorningGreen,
        description = "清新的一天开始了"
    ),
    Afternoon(
        displayName = "下午",
        color = AfternoonBlue,
        description = "专注学习的好时光"
    ),
    Evening(
        displayName = "晚上",
        color = EveningIndigo,
        description = "沉稳高效的晚间"
    ),
    Night(
        displayName = "深夜",
        color = NightPurple,
        description = "夜深了，注意休息"
    ),
    Achievement(
        displayName = "目标达成",
        color = AchievementOrange,
        description = "太棒了！目标达成"
    ),
    LowEnergy(
        displayName = "低能量模式",
        color = LowEnergyBlue,
        description = "今天状态不佳？没关系，休息也是进步的一部分"
    );

    companion object {
        fun fromTime(time: LocalTime): ThemeContext = when (time.hour) {
            in 6..11 -> Morning
            in 12..17 -> Afternoon
            in 18..23 -> Evening
            else -> Night
        }
    }
}

/**
 * 动态主题管理器
 * 单例，通过 Hilt 注入
 */
@Singleton
class ThemeManager @Inject constructor() {

    private val _currentTheme = MutableStateFlow(ThemeContext.Afternoon)
    val currentTheme: StateFlow<ThemeContext> = _currentTheme.asStateFlow()

    private val _isDynamicThemeEnabled = MutableStateFlow(true)
    val isDynamicThemeEnabled: StateFlow<Boolean> = _isDynamicThemeEnabled.asStateFlow()

    val themeColor: Color
        get() = _currentTheme.value.color

    val themeDescription: String
        get() = _currentTheme.value.description

    val themeDisplayName: String
        get() = _currentTheme.value.displayName

    /**
     * 更新主题
     * 优先级：低能量模式 > 目标达成 > 时间段
     */
    fun updateTheme(
        time: LocalTime = LocalTime.now(),
        stateScore: Int? = null,
        isGoalAchieved: Boolean = false,
        isLowEnergyMode: Boolean = false
    ) {
        if (!_isDynamicThemeEnabled.value) return

        val newTheme = when {
            isLowEnergyMode -> ThemeContext.LowEnergy
            isGoalAchieved -> ThemeContext.Achievement
            else -> ThemeContext.fromTime(time)
        }

        if (newTheme != _currentTheme.value) {
            _currentTheme.value = newTheme
        }
    }

    fun setTheme(theme: ThemeContext) {
        _currentTheme.value = theme
    }

    fun toggleDynamicTheme() {
        _isDynamicThemeEnabled.value = !_isDynamicThemeEnabled.value
        if (_isDynamicThemeEnabled.value) {
            updateTheme()
        }
    }

    fun setDynamicThemeEnabled(enabled: Boolean) {
        _isDynamicThemeEnabled.value = enabled
        if (enabled) {
            updateTheme()
        }
    }
}
