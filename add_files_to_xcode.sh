#!/bin/bash

# 添加设计系统文件到 Xcode 项目的脚本

PROJECT_DIR="/Users/shennaitong/Documents/GaoKao cockpit"
PROJECT_FILE="$PROJECT_DIR/GaokaoCockpit.xcodeproj"

echo "📦 准备添加设计系统文件到 Xcode 项目..."

# 需要添加的文件列表
FILES=(
    "GaokaoCockpit/DesignSystem/DesignSystem.swift"
    "GaokaoCockpit/DesignSystem/ThemeManager.swift"
    "GaokaoCockpit/DesignSystem/DSComponents.swift"
    "GaokaoCockpit/DesignSystem/AnimationSystem.swift"
    "GaokaoCockpit/DesignSystem/EncouragementSystem.swift"
    "GaokaoCockpit/Views/Shared/Charts/DSRingChart.swift"
    "GaokaoCockpit/Views/Shared/Charts/DSBarChart.swift"
    "GaokaoCockpit/Views/Shared/Charts/DSPieChart.swift"
    "GaokaoCockpit/Views/Shared/Charts/DSLineChart.swift"
    "GaokaoCockpit/Views/Shared/Charts/DSHeatMap.swift"
    "GaokaoCockpit/Views/Today/Components/TodayAchievementCard.swift"
    "GaokaoCockpit/Views/Shared/AchievementBadge.swift"
)

echo ""
echo "需要添加的文件："
for file in "${FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (文件不存在)"
    fi
done

echo ""
echo "⚠️  注意：由于 Xcode 项目文件格式复杂，建议使用以下方法之一："
echo ""
echo "方法 1 - 在 Xcode 中手动添加（推荐）："
echo "  1. 在 Xcode 左侧项目导航器中，右键点击 'GaokaoCockpit' 文件夹"
echo "  2. 选择 'Add Files to GaokaoCockpit...'"
echo "  3. 选择以下文件夹中的所有文件："
echo "     - GaokaoCockpit/DesignSystem/"
echo "     - GaokaoCockpit/Views/Shared/Charts/"
echo "     - GaokaoCockpit/Views/Today/Components/TodayAchievementCard.swift"
echo "     - GaokaoCockpit/Views/Shared/AchievementBadge.swift"
echo "  4. 确保勾选 'Add to targets: GaokaoCockpit'"
echo "  5. 点击 'Add'"
echo ""
echo "方法 2 - 使用 Xcode 命令行工具："
echo "  打开 Xcode，然后按 Cmd+B 重新构建项目"
echo ""
echo "方法 3 - 创建新的 Group 并拖拽文件："
echo "  1. 在 Xcode 中右键点击 'GaokaoCockpit' → New Group"
echo "  2. 命名为 'DesignSystem'"
echo "  3. 从 Finder 拖拽文件到这个 Group"
echo ""
