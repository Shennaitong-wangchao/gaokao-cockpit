import Foundation

/// 鼓励文案系统 - 根据学习状态生成温暖的鼓励文案
struct EncouragementSystem {

    // MARK: - 完成率鼓励文案

    /// 根据完成率生成鼓励文案
    static func getMessage(for progress: Double) -> String {
        switch progress {
        case 0:
            return "开始新的一天"
        case 0..<0.3:
            return "加油！每一步都是进步"
        case 0.3..<0.5:
            return "不错！继续保持节奏"
        case 0.5..<0.7:
            return "很棒！今天状态很好"
        case 0.7..<0.9:
            return "太棒了！马上就要完成了"
        case 0.9..<1.0:
            return "就差一点点了！冲刺"
        case 1.0...:
            return "完美！今日目标达成"
        default:
            return "继续加油"
        }
    }

    /// 根据完成率生成简短的状态描述
    static func getStatusLabel(for progress: Double) -> String {
        switch progress {
        case 0:
            return "刚开始"
        case 0..<0.3:
            return "起步中"
        case 0.3..<0.5:
            return "进行中"
        case 0.5..<0.7:
            return "良好"
        case 0.7..<0.9:
            return "优秀"
        case 0.9..<1.0:
            return "接近完成"
        case 1.0...:
            return "已完成"
        default:
            return "进行中"
        }
    }

    // MARK: - 学习连续天数鼓励文案

    /// 根据学习连续天数生成激励语
    static func getStreakMessage(for days: Int) -> String {
        switch days {
        case 0:
            return "今天是新的开始"
        case 1:
            return "很好！开始建立习惯"
        case 2...6:
            return "坚持得不错！继续保持"
        case 7:
            return "太棒了！连续学习一周"
        case 8...13:
            return "习惯正在养成！加油"
        case 14:
            return "两周连续学习！你很自律"
        case 15...20:
            return "持续进步中！非常棒"
        case 21:
            return "三周连续学习！习惯已养成"
        case 22...29:
            return "你的坚持令人钦佩"
        case 30:
            return "一个月连续学习！你是冠军"
        case 31...59:
            return "你的毅力令人惊叹！"
        case 60:
            return "两个月连续学习！太不可思议了"
        case 61...89:
            return "你已经超越了大多数人"
        case 90:
            return "三个月连续学习！你是传奇"
        default:
            return "你的坚持创造了奇迹！"
        }
    }

    /// 根据连续天数获取图标
    static func getStreakIcon(for days: Int) -> String {
        switch days {
        case 0:
            return "circle"
        case 1...6:
            return "flame"
        case 7...13:
            return "flame.fill"
        case 14...29:
            return "star.fill"
        case 30...59:
            return "trophy.fill"
        case 60...89:
            return "medal.fill"
        default:
            return "crown.fill"
        }
    }

    /// 根据连续天数获取颜色
    static func getStreakColor(for days: Int) -> String {
        switch days {
        case 0:
            return "gray"
        case 1...6:
            return "orange"
        case 7...13:
            return "red"
        case 14...29:
            return "yellow"
        case 30...59:
            return "green"
        case 60...89:
            return "blue"
        default:
            return "purple"
        }
    }

    // MARK: - 时间段问候语

    /// 根据时间段生成问候语
    static func getGreeting(for date: Date = Date()) -> String {
        let calendar = AppDateTime.calendar
        let hour = calendar.component(.hour, from: date)

        switch hour {
        case 0..<5:
            return "凌晨了，先放轻一点"
        case 5..<8:
            return "早起好！新的一天开始了"
        case 8..<12:
            return "上午好！学习的黄金时间"
        case 12..<14:
            return "中午好！记得休息一下"
        case 14..<18:
            return "下午好！继续保持专注"
        case 18..<22:
            return "晚上好！稳稳收束今天"
        case 22..<24:
            return "深夜了，注意休息"
        default:
            return "继续保持节奏"
        }
    }

    // MARK: - 状态分数鼓励文案

    /// 根据状态分数生成鼓励文案
    static func getStateMessage(for score: Int) -> String {
        switch score {
        case 1...3:
            return "今天状态不佳？没关系，休息也是进步的一部分"
        case 4...5:
            return "状态一般，先做保底任务，不追求完美"
        case 6...7:
            return "状态不错！可以完成今天的计划"
        case 8...9:
            return "状态很好！今天可以多做一些"
        case 10:
            return "状态极佳！今天是突破的好时机"
        default:
            return "评估一下今天的状态吧"
        }
    }

    /// 根据状态分数获取描述
    static func getStateLabel(for score: Int) -> String {
        switch score {
        case 1...3:
            return "低能量"
        case 4...5:
            return "一般"
        case 6...7:
            return "良好"
        case 8...9:
            return "很好"
        case 10:
            return "极佳"
        default:
            return "未知"
        }
    }

    // MARK: - 累计学习时长鼓励文案

    /// 根据累计学习时长（分钟）生成鼓励文案
    static func getTotalTimeMessage(for minutes: Int) -> String {
        let hours = minutes / 60

        switch hours {
        case 0..<10:
            return "刚开始积累学习时长"
        case 10..<50:
            return "学习时长稳步增长"
        case 50..<100:
            return "已经积累了不少学习时间"
        case 100..<200:
            return "学习时长超过 100 小时！"
        case 200..<500:
            return "你的努力正在累积成果"
        case 500..<1000:
            return "超过 500 小时！你很专注"
        case 1000...:
            return "超过 1000 小时！你是学习达人"
        default:
            return "继续积累学习时长"
        }
    }

    /// 格式化学习时长
    static func formatTime(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return "\(hours) 小时 \(mins) 分钟"
        } else {
            return "\(mins) 分钟"
        }
    }

    // MARK: - 本周完成任务数鼓励文案

    /// 根据本周完成任务数生成鼓励文案
    static func getWeeklyTaskMessage(for count: Int) -> String {
        switch count {
        case 0:
            return "本周还没有完成任务，加油！"
        case 1...5:
            return "本周已完成 \(count) 个任务，继续保持"
        case 6...10:
            return "本周已完成 \(count) 个任务，效率不错"
        case 11...20:
            return "本周已完成 \(count) 个任务，非常高效"
        case 21...:
            return "本周已完成 \(count) 个任务，你太厉害了"
        default:
            return "继续完成本周任务"
        }
    }

    // MARK: - 错题复习鼓励文案

    /// 根据错题掌握率生成鼓励文案
    static func getMistakeMasteryMessage(for masteryRate: Double) -> String {
        switch masteryRate {
        case 0:
            return "开始复习错题，查漏补缺"
        case 0..<0.3:
            return "错题复习刚开始，慢慢来"
        case 0.3..<0.5:
            return "错题掌握率在提升"
        case 0.5..<0.7:
            return "一半以上的错题已掌握"
        case 0.7..<0.9:
            return "错题掌握得很好"
        case 0.9..<1.0:
            return "几乎所有错题都掌握了"
        case 1.0...:
            return "所有错题都已掌握！完美"
        default:
            return "继续复习错题"
        }
    }

    // MARK: - 随机鼓励语

    /// 获取随机鼓励语
    static func getRandomEncouragement() -> String {
        let encouragements = [
            "你做得很好！",
            "继续保持！",
            "每一步都算数！",
            "你在进步！",
            "坚持就是胜利！",
            "你很棒！",
            "相信自己！",
            "加油！",
            "你可以的！",
            "不要放弃！"
        ]

        return encouragements.randomElement() ?? "加油！"
    }
}
