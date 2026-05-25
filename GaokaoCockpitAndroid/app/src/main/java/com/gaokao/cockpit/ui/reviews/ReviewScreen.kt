package com.gaokao.cockpit.ui.reviews

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoFixHigh
import androidx.compose.material.icons.filled.Backup
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CalendarViewWeek
import androidx.compose.material.icons.filled.CloudUpload
import androidx.compose.material.icons.filled.Save
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.gaokao.cockpit.data.model.DateKey
import com.gaokao.cockpit.ui.components.DSButton
import com.gaokao.cockpit.ui.components.DSCard
import com.gaokao.cockpit.ui.components.DSInputField
import com.gaokao.cockpit.ui.components.DSShadow
import com.gaokao.cockpit.ui.components.DSTag
import com.gaokao.cockpit.ui.components.SectionTitle
import com.gaokao.cockpit.ui.components.ButtonStyle
import com.gaokao.cockpit.ui.theme.DesignTokens
import com.gaokao.cockpit.ui.theme.Error
import com.gaokao.cockpit.ui.theme.Success
import com.gaokao.cockpit.viewmodel.LoadState
import com.gaokao.cockpit.viewmodel.ReviewMode
import com.gaokao.cockpit.viewmodel.ReviewViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReviewScreen(
    onNavigateToImport: () -> Unit = {},
    viewModel: ReviewViewModel = hiltViewModel()
) {
    val loadState by viewModel.loadState.collectAsState()
    val selectedMode by viewModel.selectedMode.collectAsState()
    val todayDate by viewModel.todayDate.collectAsState()
    val dailyReview by viewModel.dailyReview.collectAsState()
    val weeklyReview by viewModel.weeklyReview.collectAsState()
    val todayMistakes by viewModel.todayMistakes.collectAsState()
    val completedSummary by viewModel.completedSummary.collectAsState()
    val unfinishedSummary by viewModel.unfinishedSummary.collectAsState()
    val biggestProblem by viewModel.biggestProblem.collectAsState()
    val stateScoreEnd by viewModel.stateScoreEnd.collectAsState()
    val tomorrowFirstAction by viewModel.tomorrowFirstAction.collectAsState()
    val keyProblemsText by viewModel.keyProblemsText.collectAsState()
    val nextWeekFocusText by viewModel.nextWeekFocusText.collectAsState()
    val statusMessage by viewModel.statusMessage.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(DesignTokens.Spacing.lg)
    ) {
        Text(
            "复盘",
            style = MaterialTheme.typography.displayMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(Modifier.height(DesignTokens.Spacing.md))

        when (loadState) {
            is LoadState.Loading -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            is LoadState.Failed -> {
                Column(
                    modifier = Modifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text("复盘加载失败", style = MaterialTheme.typography.titleMedium)
                    Text(
                        (loadState as LoadState.Failed).message,
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.lg))
                    DSButton(
                        title = "重新加载",
                        onClick = { viewModel.loadReviews() },
                        style = ButtonStyle.Primary
                    )
                }
            }
            is LoadState.Loaded -> {
                SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                    ReviewMode.entries.forEachIndexed { index, mode ->
                        SegmentedButton(
                            shape = SegmentedButtonDefaults.itemShape(
                                index = index,
                                count = ReviewMode.entries.size
                            ),
                            onClick = { viewModel.setMode(mode) },
                            selected = selectedMode == mode,
                            icon = {}
                        ) {
                            Text(if (mode == ReviewMode.DAILY) "每日复盘" else "周复盘")
                        }
                    }
                }

                Spacer(Modifier.height(DesignTokens.Spacing.md))

                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                ) {
                    if (selectedMode == ReviewMode.DAILY) {
                        // ====== 每日复盘 ======
                        DSCard(shadow = DSShadow.Medium) {
                            SectionTitle(
                                title = "每日复盘",
                                icon = Icons.Default.CalendarToday
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.md))
                            Text(
                                DateKey.displayString(todayDate),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.lg))

                            DSInputField(
                                value = completedSummary,
                                onValueChange = { viewModel.setCompletedSummary(it) },
                                label = "已完成总结",
                                minLines = 3,
                                modifier = Modifier.fillMaxWidth()
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.md))
                            DSInputField(
                                value = unfinishedSummary,
                                onValueChange = { viewModel.setUnfinishedSummary(it) },
                                label = "未完成总结",
                                minLines = 3,
                                modifier = Modifier.fillMaxWidth()
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.md))
                            DSInputField(
                                value = biggestProblem,
                                onValueChange = { viewModel.setBiggestProblem(it) },
                                label = "最大问题",
                                minLines = 2,
                                modifier = Modifier.fillMaxWidth()
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.md))
                            Text(
                                "结束状态评分: ${stateScoreEnd ?: 7}",
                                style = MaterialTheme.typography.labelLarge
                            )
                            Slider(
                                value = (stateScoreEnd ?: 7).toFloat(),
                                onValueChange = { viewModel.setStateScoreEnd(it.toInt()) },
                                valueRange = 1f..10f,
                                steps = 8
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.md))
                            DSInputField(
                                value = tomorrowFirstAction,
                                onValueChange = { viewModel.setTomorrowFirstAction(it) },
                                label = "明日第一件事",
                                modifier = Modifier.fillMaxWidth()
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.md))
                            if (todayMistakes.isNotEmpty()) {
                                Text(
                                    "今日错题",
                                    style = MaterialTheme.typography.labelLarge
                                )
                                Spacer(Modifier.height(DesignTokens.Spacing.xs))
                                todayMistakes.forEach { mistake ->
                                    Text(
                                        "- ${mistake.questionText.take(30)}",
                                        style = MaterialTheme.typography.bodySmall
                                    )
                                }
                                Spacer(Modifier.height(DesignTokens.Spacing.md))
                            }
                            DSButton(
                                title = "应用快捷模板",
                                icon = Icons.Default.AutoFixHigh,
                                onClick = { viewModel.applyDailyQuickTemplate() },
                                style = ButtonStyle.Secondary
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.md))
                            DSButton(
                                title = "保存每日复盘",
                                icon = Icons.Default.Save,
                                onClick = { viewModel.saveDailyReview() },
                                style = ButtonStyle.Primary
                            )
                        }
                    } else {
                        // ====== 周复盘 ======
                        DSCard(shadow = DSShadow.Medium) {
                            SectionTitle(
                                title = "周复盘",
                                icon = Icons.Default.CalendarViewWeek
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.lg))
                            DSInputField(
                                value = keyProblemsText,
                                onValueChange = { viewModel.setKeyProblemsText(it) },
                                label = "本周关键问题",
                                minLines = 3,
                                modifier = Modifier.fillMaxWidth()
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.md))
                            DSInputField(
                                value = nextWeekFocusText,
                                onValueChange = { viewModel.setNextWeekFocusText(it) },
                                label = "下周重点",
                                minLines = 3,
                                modifier = Modifier.fillMaxWidth()
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.md))
                            DSButton(
                                title = "自动生成统计",
                                icon = Icons.Default.AutoFixHigh,
                                onClick = { viewModel.generateWeeklySummary() },
                                style = ButtonStyle.Secondary
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.md))
                            DSButton(
                                title = "保存周复盘",
                                icon = Icons.Default.Save,
                                onClick = { viewModel.saveWeeklyReview() },
                                style = ButtonStyle.Primary
                            )
                        }
                    }

                    // ====== 数据备份 ======
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    DSCard(shadow = DSShadow.Medium) {
                        SectionTitle(
                            title = "数据备份",
                            icon = Icons.Default.Backup
                        )
                        Spacer(Modifier.height(DesignTokens.Spacing.md))
                        Text(
                            "导出最近30天的所有数据为JSON文件，可通过微信、邮件等方式分享保存。",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(Modifier.height(DesignTokens.Spacing.md))
                        val backupViewModel: com.gaokao.cockpit.viewmodel.BackupViewModel = hiltViewModel()
                        val isExporting by backupViewModel.isExporting.collectAsState()
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.sm),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            DSButton(
                                title = if (isExporting) "正在导出..." else "导出",
                                icon = Icons.Default.Backup,
                                onClick = { backupViewModel.exportAllData() },
                                isLoading = isExporting,
                                style = ButtonStyle.Secondary,
                                modifier = Modifier.weight(1f)
                            )
                            DSButton(
                                title = "恢复",
                                icon = Icons.Default.CloudUpload,
                                onClick = onNavigateToImport,
                                style = ButtonStyle.Tertiary,
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }

                    if (statusMessage != null) {
                        Spacer(Modifier.height(DesignTokens.Spacing.md))
                        Text(
                            statusMessage!!,
                            style = MaterialTheme.typography.bodyMedium,
                            color = if (statusMessage!!.contains("失败")) Error else Success
                        )
                    }

                    Spacer(Modifier.height(DesignTokens.Spacing.xxl))
                }
            }
        }
    }
}
