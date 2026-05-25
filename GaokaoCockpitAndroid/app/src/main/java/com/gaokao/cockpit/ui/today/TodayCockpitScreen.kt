package com.gaokao.cockpit.ui.today

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AutoFixHigh
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Save
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.gaokao.cockpit.data.model.DateKey
import com.gaokao.cockpit.data.model.LearningSubject
import com.gaokao.cockpit.data.model.StudyTask
import com.gaokao.cockpit.data.model.StudyTaskStatus
import com.gaokao.cockpit.ui.components.AnimatedAppear
import com.gaokao.cockpit.ui.components.DSButton
import com.gaokao.cockpit.ui.components.DSCard
import com.gaokao.cockpit.ui.components.DSInputField
import com.gaokao.cockpit.ui.components.DSProgressBar
import com.gaokao.cockpit.ui.components.DSShadow
import com.gaokao.cockpit.ui.components.DSStatCard
import com.gaokao.cockpit.ui.components.DSTag
import com.gaokao.cockpit.ui.components.EmptyState
import com.gaokao.cockpit.ui.components.ErrorState
import com.gaokao.cockpit.ui.components.ProgressStyle
import com.gaokao.cockpit.ui.components.SectionTitle
import com.gaokao.cockpit.ui.theme.DesignTokens
import com.gaokao.cockpit.ui.theme.Error
import com.gaokao.cockpit.ui.theme.Info
import com.gaokao.cockpit.ui.theme.LowEnergyBlue
import com.gaokao.cockpit.ui.theme.Success
import com.gaokao.cockpit.ui.theme.Warning
import com.gaokao.cockpit.viewmodel.LoadState
import com.gaokao.cockpit.viewmodel.TodayCockpitViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TodayCockpitScreen(
    onViewTasks: () -> Unit,
    viewModel: TodayCockpitViewModel = hiltViewModel()
) {
    val loadState by viewModel.loadState.collectAsState()
    val dayPlan by viewModel.dayPlan.collectAsState()
    val todayDate by viewModel.todayDate.collectAsState()
    val todayKey by viewModel.todayKey.collectAsState()
    val stateScore by viewModel.stateScore.collectAsState()
    val mainSubject by viewModel.mainSubject.collectAsState()
    val topTasksText by viewModel.topTasksText.collectAsState()
    val baselineTasksText by viewModel.baselineTasksText.collectAsState()
    val bonusTasksText by viewModel.bonusTasksText.collectAsState()
    val tomorrowFirstAction by viewModel.tomorrowFirstAction.collectAsState()
    val tasks by viewModel.tasks.collectAsState()
    val totalTaskCount by viewModel.totalTaskCount.collectAsState()
    val completedTaskCount by viewModel.completedTaskCount.collectAsState()
    val planTaskMessage by viewModel.planTaskMessage.collectAsState()
    val showPlanDialog by viewModel.showPlanTaskDialog.collectAsState()
    val parsedPlanTasks by viewModel.parsedPlanTasks.collectAsState()
    val isLowEnergy by remember(stateScore) { mutableStateOf(stateScore <= 4) }

    Column(modifier = Modifier.fillMaxSize()) {
        when (loadState) {
            is LoadState.Loading -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            is LoadState.Failed -> {
                ErrorState(
                    message = (loadState as LoadState.Failed).message,
                    onRetry = { viewModel.loadToday() },
                    modifier = Modifier.fillMaxSize()
                )
            }
            is LoadState.Loaded -> {
                if (dayPlan == null) {
                    EmptyState(
                        title = "今日计划为空",
                        message = "没有找到今日 DayPlan。",
                        action = { Button(onClick = { viewModel.loadToday() }) { Text("创建今日计划") } },
                        modifier = Modifier.fillMaxSize()
                    )
                } else {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(DesignTokens.Spacing.lg)
                    ) {
                        // ====== Header ======
                        AnimatedAppear {
                            DSCard(
                                shadow = DSShadow.Medium,
                                accentColor = MaterialTheme.colorScheme.primary,
                                backgroundColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                            ) {
                                Row(verticalAlignment = Alignment.Top) {
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            "今日驾驶舱",
                                            style = MaterialTheme.typography.displayMedium,
                                            color = MaterialTheme.colorScheme.primary
                                        )
                                        Text(
                                            DateKey.displayString(todayDate),
                                            style = MaterialTheme.typography.titleMedium,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                    Box(
                                        modifier = Modifier
                                            .size(12.dp)
                                            .clip(CircleShape)
                                            .background(MaterialTheme.colorScheme.primary)
                                    )
                                }
                                Spacer(Modifier.height(DesignTokens.Spacing.xs))
                                Text(
                                    todayKey,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }

                        Spacer(Modifier.height(DesignTokens.Spacing.md))

                        // ====== 今日启动 / 状态评分 ======
                        AnimatedAppear(delayMillis = 100) {
                            val scoreColor = when (stateScore) {
                                in 1..4 -> Error
                                in 5..6 -> Warning
                                in 7..8 -> Info
                                else -> Success
                            }
                            DSCard(
                                shadow = DSShadow.Medium,
                                accentColor = if (isLowEnergy) LowEnergyBlue else scoreColor
                            ) {
                                SectionTitle(title = "今日启动", icon = Icons.Default.WbSunny)
                                Spacer(Modifier.height(DesignTokens.Spacing.md))
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    // 状态评分圆环
                                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                        DSProgressBar(
                                            progress = stateScore / 10f,
                                            style = ProgressStyle.Ring,
                                            color = scoreColor,
                                            showPercentage = false,
                                            modifier = Modifier.size(88.dp)
                                        )
                                        Spacer(Modifier.height(DesignTokens.Spacing.xs))
                                        Text(
                                            "$stateScore / 10",
                                            style = MaterialTheme.typography.labelMedium,
                                            fontWeight = FontWeight.Bold,
                                            color = scoreColor
                                        )
                                        Text(
                                            when (stateScore) {
                                                in 1..4 -> "低能量"
                                                in 5..6 -> "一般"
                                                in 7..8 -> "良好"
                                                else -> "极佳"
                                            },
                                            style = MaterialTheme.typography.labelSmall,
                                            color = scoreColor
                                        )
                                    }
                                    Spacer(Modifier.width(DesignTokens.Spacing.lg))
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text("状态评分", style = MaterialTheme.typography.labelLarge)
                                        Slider(
                                            value = stateScore.toFloat(),
                                            onValueChange = { viewModel.setStateScore(it.toInt()) },
                                            valueRange = 1f..10f,
                                            steps = 8
                                        )
                                        Spacer(Modifier.height(DesignTokens.Spacing.sm))
                                        Text("主攻科目", style = MaterialTheme.typography.labelLarge)
                                        var expanded by remember { mutableStateOf(false) }
                                        val subjects = listOf("先选主攻科目") + LearningSubject.allDisplayNames()
                                        ExposedDropdownMenuBox(
                                            expanded = expanded,
                                            onExpandedChange = { expanded = it }
                                        ) {
                                            OutlinedTextField(
                                                value = if (mainSubject.isBlank()) "先选主攻科目" else LearningSubject.from(mainSubject).displayName,
                                                onValueChange = {},
                                                readOnly = true,
                                                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                                                modifier = Modifier.menuAnchor().fillMaxWidth()
                                            )
                                            ExposedDropdownMenu(
                                                expanded = expanded,
                                                onDismissRequest = { expanded = false }
                                            ) {
                                                subjects.forEach { subject ->
                                                    DropdownMenuItem(
                                                        text = { Text(subject) },
                                                        onClick = {
                                                            if (subject != "先选主攻科目") {
                                                                viewModel.setMainSubject(subject)
                                                            }
                                                            expanded = false
                                                        }
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ====== 低能量提示 ======
                        if (isLowEnergy) {
                            Spacer(Modifier.height(DesignTokens.Spacing.md))
                            AnimatedAppear {
                                DSCard(
                                    shadow = DSShadow.Small,
                                    accentColor = LowEnergyBlue,
                                    backgroundColor = LowEnergyBlue.copy(alpha = 0.12f)
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(
                                            imageVector = Icons.Default.WbSunny,
                                            contentDescription = null,
                                            tint = LowEnergyBlue,
                                            modifier = Modifier.size(20.dp)
                                        )
                                        Spacer(Modifier.width(DesignTokens.Spacing.sm))
                                        Column {
                                            Text(
                                                "低能量模式",
                                                style = MaterialTheme.typography.titleSmall,
                                                color = LowEnergyBlue,
                                                fontWeight = FontWeight.SemiBold
                                            )
                                            Text(
                                                "状态评分较低，建议减少任务量，优先完成保底任务。",
                                                style = MaterialTheme.typography.bodySmall,
                                                color = MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        Spacer(Modifier.height(DesignTokens.Spacing.md))

                        // ====== 任务概览 ======
                        AnimatedAppear(delayMillis = 200) {
                            DSCard(shadow = DSShadow.Medium) {
                                SectionTitle(title = "任务概览", icon = Icons.Default.CheckCircle)
                                Spacer(Modifier.height(DesignTokens.Spacing.md))
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceEvenly
                                ) {
                                    DSStatCard(
                                        title = "总任务",
                                        value = totalTaskCount.toString(),
                                        valueColor = MaterialTheme.colorScheme.primary,
                                        isAnimated = true
                                    )
                                    DSStatCard(
                                        title = "已完成",
                                        value = completedTaskCount.toString(),
                                        valueColor = Success,
                                        isAnimated = true
                                    )
                                    DSStatCard(
                                        title = "待完成",
                                        value = viewModel.pendingTaskCount.toString(),
                                        valueColor = Warning,
                                        isAnimated = true
                                    )
                                }
                                Spacer(Modifier.height(DesignTokens.Spacing.md))
                                DSProgressBar(
                                    progress = if (totalTaskCount > 0) completedTaskCount / totalTaskCount.toFloat() else 0f,
                                    color = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.fillMaxWidth()
                                )
                            }
                        }

                        Spacer(Modifier.height(DesignTokens.Spacing.md))

                        // ====== 今日任务预览 ======
                        AnimatedAppear(delayMillis = 300) {
                            DSCard(shadow = DSShadow.Medium) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    SectionTitle(
                                        title = "今日任务",
                                        modifier = Modifier.weight(1f)
                                    )
                                    TextButton(onClick = onViewTasks) {
                                        Text("查看全部")
                                    }
                                }
                                Spacer(Modifier.height(DesignTokens.Spacing.sm))
                                if (tasks.isEmpty()) {
                                    Text(
                                        "暂无任务",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                                    )
                                } else {
                                    tasks.take(5).forEach { task ->
                                        TodayTaskRow(
                                            task = task,
                                            onToggle = { viewModel.toggleTaskStatus(task) }
                                        )
                                    }
                                    if (tasks.size > 5) {
                                        Text(
                                            "+ ${tasks.size - 5} 更多任务",
                                            style = MaterialTheme.typography.labelMedium,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                                        )
                                    }
                                }
                                Spacer(Modifier.height(DesignTokens.Spacing.sm))
                                DSButton(
                                    title = "快速添加任务",
                                    icon = Icons.Default.Add,
                                    onClick = { viewModel.showQuickAdd() },
                                    style = com.gaokao.cockpit.ui.components.ButtonStyle.Secondary
                                )
                            }
                        }

                        Spacer(Modifier.height(DesignTokens.Spacing.md))

                        // ====== 今日计划 ======
                        AnimatedAppear(delayMillis = 400) {
                            DSCard(shadow = DSShadow.Medium) {
                                SectionTitle(title = "今日计划")
                                Spacer(Modifier.height(DesignTokens.Spacing.md))
                                DSInputField(
                                    value = topTasksText,
                                    onValueChange = { viewModel.setTopTasksText(it) },
                                    label = "重点任务",
                                    minLines = 2
                                )
                                Spacer(Modifier.height(DesignTokens.Spacing.md))
                                DSInputField(
                                    value = baselineTasksText,
                                    onValueChange = { viewModel.setBaselineTasksText(it) },
                                    label = "保底任务",
                                    minLines = 2
                                )
                                if (!isLowEnergy) {
                                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                                    DSInputField(
                                        value = bonusTasksText,
                                        onValueChange = { viewModel.setBonusTasksText(it) },
                                        label = "加分任务",
                                        minLines = 2
                                    )
                                }
                                Spacer(Modifier.height(DesignTokens.Spacing.md))
                                DSButton(
                                    title = "从计划生成任务",
                                    icon = Icons.Default.AutoFixHigh,
                                    onClick = { viewModel.preparePlanTaskGeneration() },
                                    style = com.gaokao.cockpit.ui.components.ButtonStyle.Secondary
                                )
                                if (planTaskMessage != null) {
                                    Spacer(Modifier.height(DesignTokens.Spacing.xs))
                                    Text(
                                        planTaskMessage!!,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = if (planTaskMessage!!.contains("失败")) Error else MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }

                        Spacer(Modifier.height(DesignTokens.Spacing.md))

                        // ====== 明日第一件事 ======
                        AnimatedAppear(delayMillis = 500) {
                            DSCard(shadow = DSShadow.Medium) {
                                SectionTitle(title = "明日第一件事")
                                Spacer(Modifier.height(DesignTokens.Spacing.md))
                                DSInputField(
                                    value = tomorrowFirstAction,
                                    onValueChange = { viewModel.setTomorrowFirstAction(it) },
                                    placeholder = "写下明天醒来第一件事做什么..."
                                )
                            }
                        }

                        Spacer(Modifier.height(DesignTokens.Spacing.md))

                        // ====== 保存按钮 ======
                        AnimatedAppear(delayMillis = 600) {
                            DSButton(
                                title = "保存今日计划",
                                icon = Icons.Default.Save,
                                onClick = { viewModel.saveTodayPlan() },
                                style = com.gaokao.cockpit.ui.components.ButtonStyle.Primary
                            )
                        }

                        Spacer(Modifier.height(DesignTokens.Spacing.xxl))
                    }
                }
            }
        }
    }

    // ====== 生成任务确认弹窗 ======
    if (showPlanDialog) {
        val selectedTasks = remember { mutableStateMapOf<Int, Boolean>() }
        AlertDialog(
            onDismissRequest = { viewModel.dismissPlanTaskDialog() },
            title = { Text("确认生成任务") },
            text = {
                Column {
                    Text("以下任务将从计划文本生成：")
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    parsedPlanTasks.forEachIndexed { index, task ->
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Checkbox(
                                checked = selectedTasks[index] != false,
                                onCheckedChange = { selectedTasks[index] = it }
                            )
                            Column {
                                Text(
                                    task.title,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.SemiBold
                                )
                                Row {
                                    if (task.subject.isNotBlank()) DSTag(task.subject)
                                    Spacer(Modifier.width(DesignTokens.Spacing.xs))
                                    if (task.estimatedMinutes != null) DSTag("${task.estimatedMinutes}分钟")
                                }
                            }
                        }
                    }
                }
            },
            confirmButton = {
                Button(onClick = {
                    val toCreate = parsedPlanTasks.filterIndexed { index, _ -> selectedTasks[index] != false }
                    viewModel.createTasksFromPlan(toCreate)
                }) {
                    Text("生成")
                }
            },
            dismissButton = {
                TextButton(onClick = { viewModel.dismissPlanTaskDialog() }) { Text("取消") }
            }
        )
    }
}

@Composable
private fun TodayTaskRow(task: StudyTask, onToggle: () -> Unit) {
    val status = StudyTaskStatus.from(task.status)
    val isDone = status == StudyTaskStatus.DONE
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = DesignTokens.Spacing.xs),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Checkbox(checked = isDone, onCheckedChange = { onToggle() })
        Text(
            text = task.title.ifBlank { "未命名任务" },
            style = MaterialTheme.typography.bodyMedium,
            textDecoration = if (isDone) TextDecoration.LineThrough else null,
            color = if (isDone) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f)
        )
        if (task.subject.isNotBlank()) {
            Spacer(Modifier.width(DesignTokens.Spacing.xs))
            DSTag(task.subject)
        }
    }
}
