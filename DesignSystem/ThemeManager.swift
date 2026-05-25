import SwiftUI
import Observation

/// 主题上下文
enum ThemeContext: String, CaseIterable {
    case morning        // 早晨 6:00-12:00 - 清新青绿
    case afternoon      // 下午 12:00-18:00 - 专注深蓝
    case evening        // 晚上 18:00-24:00 - 沉稳靛蓝
    case night          // 深夜 0:00-6:00 - 柔和紫色
    case achievement    // 完成目标 - 温暖橙金
    case lowEnergy      // 低能量模式 - 柔和灰蓝

    var displayName: String {
        switch self {
        case .morning: return "早晨"
        case .afternoon: return "下午"
        case .evening: return "晚上"
        case .night: return "深夜"
        case .achievement: return "目标达成"
        case .lowEnergy: return "低能量模式"
        }
    }

    var color: Color {
        switch self {
        case .morning: return DesignSystem.ThemeColors.morning
        case .afternoon: return DesignSystem.ThemeColors.afternoon
        case .evening: return DesignSystem.ThemeColors.evening
        case .night: return DesignSystem.ThemeColors.night
        case .achievement: return DesignSystem.ThemeColors.achievement
        case .lowEnergy: return DesignSystem.ThemeColors.lowEnergy
        }
    }

    var description: String {
        switch self {
        case .morning: return "清新的一天开始了"
        case .afternoon: return "专注学习的好时光"
        case .evening: return "沉稳高效的晚间"
        case .night: return "夜深了，注意休息"
        case .achievement: return "太棒了！目标达成"
        case .lowEnergy: return "今天状态不佳？没关系，休息也是进步的一部分"
        }
    }
}

/// 动态主题管理器
@Observable
class ThemeManager {
    /// 当前主题上下文
    var currentTheme: ThemeContext = .afternoon

    /// 是否启用动态主题（用户可关闭）
    var isDynamicThemeEnabled: Bool = true

    /// 单例
    static let shared = ThemeManager()

    private init() {
        updateTheme()
    }

    /// 更新主题（根据时间段、学习状态等）
    func updateTheme(
        basedOn time: Date = Date(),
        stateScore: Int? = nil,
        isGoalAchieved: Bool = false,
        isLowEnergyMode: Bool = false
    ) {
        guard isDynamicThemeEnabled else { return }

        // 优先级：低能量模式 > 目标达成 > 时间段
        if isLowEnergyMode {
            currentTheme = .lowEnergy
        } else if isGoalAchieved {
            currentTheme = .achievement
        } else {
            currentTheme = themeForTime(time)
        }
    }

    /// 根据时间段获取主题
    private func themeForTime(_ time: Date) -> ThemeContext {
        let calendar = AppDateTime.calendar
        let hour = calendar.component(.hour, from: time)

        switch hour {
        case 6..<12:
            return .morning
        case 12..<18:
            return .afternoon
        case 18..<24:
            return .evening
        default:
            return .night
        }
    }

    /// 获取当前主题色
    var themeColor: Color {
        currentTheme.color
    }

    /// 获取当前主题描述
    var themeDescription: String {
        currentTheme.description
    }

    /// 手动设置主题（用于测试或用户偏好）
    func setTheme(_ theme: ThemeContext) {
        currentTheme = theme
    }

    /// 切换动态主题开关
    func toggleDynamicTheme() {
        isDynamicThemeEnabled.toggle()
        if isDynamicThemeEnabled {
            updateTheme()
        }
    }
}
