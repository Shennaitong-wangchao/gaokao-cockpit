package com.gaokao.cockpit.ui.focus

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.gaokao.cockpit.data.model.LearningSubject
import com.gaokao.cockpit.data.model.StudyTaskCategory
import com.gaokao.cockpit.ui.components.DSButton
import com.gaokao.cockpit.ui.components.DSCard
import com.gaokao.cockpit.ui.components.DSInputField
import com.gaokao.cockpit.ui.components.DSProgressBar
import com.gaokao.cockpit.ui.components.DSShadow
import com.gaokao.cockpit.ui.components.DSStatCard
import com.gaokao.cockpit.ui.components.DSTag
import com.gaokao.cockpit.ui.components.ButtonStyle
import com.gaokao.cockpit.ui.components.ProgressStyle
import com.gaokao.cockpit.ui.theme.DesignTokens
import com.gaokao.cockpit.ui.theme.Error
import com.gaokao.cockpit.ui.theme.Warning
import com.gaokao.cockpit.ui.theme.withMonoNumbers
import com.gaokao.cockpit.viewmodel.FocusSessionViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FocusSessionScreen(
    taskId: String,
    onBack: () -> Unit,
    viewModel: FocusSessionViewModel = hiltViewModel()
) {
    LaunchedEffect(taskId) {
        viewModel.loadTask(taskId)
    }

    val task by viewModel.task.collectAsState()
    val plannedMinutes by viewModel.plannedMinutes.collectAsState()
    val elapsedSeconds by viewModel.elapsedSeconds.collectAsState()
    val distractionCount by viewModel.distractionCount.collectAsState()
    val isRunning by viewModel.isRunning.collectAsState()
    val hasStarted by viewModel.hasStarted.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()
    val showFinishSheet by viewModel.showFinishSheet.collectAsState()

    val formattedTime = viewModel.formattedElapsedTime
    val minuteOptions = remember(task) {
        val base = listOf(15, 25, 45, 60, 90)
        val estimate = task?.estimatedMinutes?.takeIf { it > 0 }
        (base + listOfNotNull(estimate)).distinct().sorted()
    }

    // 计算进度：已用时间 / 计划时间
    val progress = remember(elapsedSeconds, plannedMinutes) {
        if (plannedMinutes > 0) (elapsedSeconds / 60f / plannedMinutes).coerceIn(0f, 1f) else 0f
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(DesignTokens.Spacing.lg)
    ) {
        if (task == null) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
            ) {
                Text(
                    "专注计时",
                    style = MaterialTheme.typography.displayMedium,
                    fontWeight = FontWeight.Bold
                )
                Spacer(Modifier.height(DesignTokens.Spacing.lg))

                // ====== 当前任务卡片 ======
                DSCard(shadow = DSShadow.Medium) {
                    Text(
                        "当前任务",
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.xs))
                    Text(
                        task!!.title.ifBlank { "未命名任务" },
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    Row(horizontalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.sm)) {
                        DSTag(
                            task!!.subject.ifBlank { "未设科目" }
                                .let { LearningSubject.from(it).displayName }
                        )
                        DSTag(
                            task!!.category.ifBlank { "未分类" }
                                .let { StudyTaskCategory.from(it).displayName },
                            color = MaterialTheme.colorScheme.secondary
                        )
                        if (task!!.estimatedMinutes != null) {
                            DSTag("预计 ${task!!.estimatedMinutes} 分钟")
                        }
                    }
                }

                Spacer(Modifier.height(DesignTokens.Spacing.lg))

                if (!hasStarted) {
                    // ====== 设置时长 ======
                    DSCard(shadow = DSShadow.Medium) {
                        Text(
                            "计划时长",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(Modifier.height(DesignTokens.Spacing.md))
                        SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                            minuteOptions.forEachIndexed { index, minutes ->
                                SegmentedButton(
                                    shape = SegmentedButtonDefaults.itemShape(
                                        index = index,
                                        count = minuteOptions.size
                                    ),
                                    onClick = { viewModel.setPlannedMinutes(minutes) },
                                    selected = plannedMinutes == minutes
                                ) { Text("$minutes") }
                            }
                        }
                        Spacer(Modifier.height(DesignTokens.Spacing.lg))
                        DSButton(
                            title = "开始专注",
                            icon = Icons.Default.PlayArrow,
                            onClick = { viewModel.startFocus() },
                            style = ButtonStyle.Primary
                        )
                    }
                } else {
                    // ====== 计时中卡片 ======
                    DSCard(
                        shadow = DSShadow.Large,
                        accentColor = if (isRunning) MaterialTheme.colorScheme.primary else Warning
                    ) {
                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(
                                if (isRunning) "专注中" else "已暂停",
                                style = MaterialTheme.typography.labelLarge,
                                color = if (isRunning) MaterialTheme.colorScheme.primary else Warning
                            )
                            Spacer(Modifier.height(DesignTokens.Spacing.md))

                            // 环形进度 + 时间
                            Box(
                                modifier = Modifier.size(180.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                DSProgressBar(
                                    progress = progress,
                                    style = ProgressStyle.Ring,
                                    color = if (isRunning) MaterialTheme.colorScheme.primary else Warning,
                                    showPercentage = false,
                                    modifier = Modifier.fillMaxSize()
                                )
                                Text(
                                    formattedTime,
                                    style = MaterialTheme.typography.displayLarge
                                        .withMonoNumbers()
                                        .copy(
                                            fontWeight = FontWeight.Bold,
                                            fontSize = 48.sp
                                        ),
                                    textAlign = TextAlign.Center
                                )
                            }

                            Spacer(Modifier.height(DesignTokens.Spacing.md))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceEvenly
                            ) {
                                DSStatCard(
                                    title = "计划",
                                    value = "$plannedMinutes 分钟",
                                    valueColor = MaterialTheme.colorScheme.onSurface
                                )
                                DSStatCard(
                                    title = "分心",
                                    value = "${distractionCount} 次",
                                    valueColor = if (distractionCount > 0) Warning else MaterialTheme.colorScheme.onSurface
                                )
                            }
                            Spacer(Modifier.height(DesignTokens.Spacing.sm))
                            Text(
                                task!!.title.ifBlank { "未命名任务" },
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                maxLines = 2,
                                textAlign = TextAlign.Center
                            )
                        }
                    }

                    Spacer(Modifier.height(DesignTokens.Spacing.lg))

                    // ====== 控制按钮 ======
                    DSCard(shadow = DSShadow.Small) {
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.sm),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            DSButton(
                                title = "分心 +1",
                                onClick = { viewModel.addDistraction() },
                                style = ButtonStyle.Secondary,
                                modifier = Modifier.weight(1f)
                            )
                            DSButton(
                                title = if (isRunning) "暂停" else "继续",
                                icon = if (isRunning) Icons.Default.Pause else Icons.Default.PlayArrow,
                                onClick = { viewModel.togglePause() },
                                style = if (isRunning) ButtonStyle.Tertiary else ButtonStyle.Primary,
                                modifier = Modifier.weight(1f)
                            )
                        }
                        Spacer(Modifier.height(DesignTokens.Spacing.md))
                        DSButton(
                            title = "结束专注",
                            icon = Icons.Default.Stop,
                            onClick = { viewModel.prepareFinish() },
                            style = ButtonStyle.Destructive
                        )
                    }
                }

                if (errorMessage != null) {
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    Text(
                        errorMessage!!,
                        color = Error,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }

                Spacer(Modifier.height(DesignTokens.Spacing.xxl))
            }
        }
    }

    // ====== 结束确认弹窗 ======
    if (showFinishSheet) {
        var sessionNote by remember { mutableStateOf("") }
        var nextAction by remember { mutableStateOf("") }
        var completionScore by remember { mutableIntStateOf(7) }

        AlertDialog(
            onDismissRequest = { viewModel.cancelFinish() },
            title = { Text("结束专注") },
            text = {
                Column {
                    Text("专注时长: $formattedTime")
                    Text("分心次数: $distractionCount")
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    Text("完成度评分: $completionScore")
                    Slider(
                        value = completionScore.toFloat(),
                        onValueChange = { completionScore = it.toInt() },
                        valueRange = 1f..10f,
                        steps = 8
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    DSInputField(
                        value = sessionNote,
                        onValueChange = { sessionNote = it },
                        label = "专注记录",
                        minLines = 2,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    DSInputField(
                        value = nextAction,
                        onValueChange = { nextAction = it },
                        label = "下一步行动",
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                DSButton(
                    title = "保存并结束",
                    onClick = {
                        viewModel.finishSession(sessionNote, nextAction, completionScore)
                        onBack()
                    },
                    style = ButtonStyle.Primary
                )
            },
            dismissButton = {
                TextButton(onClick = { viewModel.cancelFinish() }) {
                    Text("取消")
                }
            }
        )
    }
}
