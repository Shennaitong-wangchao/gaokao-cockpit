package com.gaokao.cockpit.ui.tasks

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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.gaokao.cockpit.data.model.DateKey
import com.gaokao.cockpit.data.model.LearningSubject
import com.gaokao.cockpit.data.model.StudyTask
import com.gaokao.cockpit.data.model.StudyTaskCategory
import com.gaokao.cockpit.data.model.StudyTaskStatus
import com.gaokao.cockpit.ui.components.DSButton
import com.gaokao.cockpit.ui.components.DSCard
import com.gaokao.cockpit.ui.components.DSInputField
import com.gaokao.cockpit.ui.components.DSShadow
import com.gaokao.cockpit.ui.components.DSStatCard
import com.gaokao.cockpit.ui.components.DSTag
import com.gaokao.cockpit.ui.components.EmptyState
import com.gaokao.cockpit.ui.components.ButtonStyle
import com.gaokao.cockpit.ui.theme.DesignTokens
import com.gaokao.cockpit.ui.theme.Info
import com.gaokao.cockpit.ui.theme.Pending
import com.gaokao.cockpit.ui.theme.Skipped
import com.gaokao.cockpit.ui.theme.Success
import com.gaokao.cockpit.viewmodel.TaskFilter
import com.gaokao.cockpit.viewmodel.TaskListViewModel

@Composable
fun TaskListScreen(
    onFocusTask: (String) -> Unit,
    viewModel: TaskListViewModel = hiltViewModel()
) {
    val isLoading by viewModel.isLoading.collectAsState()
    val tasks by viewModel.tasks.collectAsState()
    val selectedFilter by viewModel.selectedFilter.collectAsState()
    val totalTaskCount by viewModel.totalTaskCount.collectAsState()
    val completedTaskCount by viewModel.completedTaskCount.collectAsState()
    val unfinishedTaskCount = viewModel.unfinishedTaskCount
    val todayDate by viewModel.todayDate.collectAsState()
    val statusMessage by viewModel.statusMessage.collectAsState()
    val showEditor by viewModel.showEditor.collectAsState()
    val editingTask by viewModel.editingTask.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(DesignTokens.Spacing.lg)
    ) {
        // ====== Header ======
        Text(
            "任务",
            style = MaterialTheme.typography.displayMedium,
            fontWeight = FontWeight.Bold
        )
        Text(
            DateKey.displayString(todayDate),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(Modifier.height(DesignTokens.Spacing.md))

        // ====== 统计卡片 ======
        DSCard(shadow = DSShadow.Medium) {
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
                    title = "未完成",
                    value = unfinishedTaskCount.toString(),
                    valueColor = Pending,
                    isAnimated = true
                )
            }
        }

        Spacer(Modifier.height(DesignTokens.Spacing.md))

        // ====== 筛选 Chip ======
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.sm)
        ) {
            TaskFilter.entries.forEach { filter ->
                FilterChip(
                    selected = selectedFilter == filter,
                    onClick = { viewModel.setFilter(filter) },
                    label = { Text(filter.title) }
                )
            }
        }

        Spacer(Modifier.height(DesignTokens.Spacing.md))

        // ====== 任务列表 ======
        if (isLoading) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else if (tasks.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize().weight(1f),
                contentAlignment = Alignment.Center
            ) {
                EmptyState(
                    title = "还没有任务",
                    message = "点击按钮添加今日任务",
                    icon = Icons.Default.CheckCircle,
                    action = {
                        DSButton(
                            title = "新增任务",
                            icon = Icons.Default.Add,
                            onClick = { viewModel.showAddEditor() }
                        )
                    }
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.md)
            ) {
                items(tasks, key = { it.id }) { task ->
                    TaskRow(
                        task = task,
                        onEdit = { viewModel.showEditEditor(task) },
                        onFocus = { onFocusTask(task.id) },
                        onChangeStatus = { viewModel.updateTaskStatus(task, it) },
                        onDelete = { viewModel.deleteTask(task) }
                    )
                }
            }
            Spacer(Modifier.height(DesignTokens.Spacing.sm))
            DSButton(
                title = "新增任务",
                icon = Icons.Default.Add,
                onClick = { viewModel.showAddEditor() },
                style = ButtonStyle.Primary
            )
        }

        if (statusMessage != null) {
            Spacer(Modifier.height(DesignTokens.Spacing.sm))
            Text(
                statusMessage!!,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
            )
        }
    }

    if (showEditor) {
        TaskEditorSheet(
            task = editingTask,
            dayKey = viewModel.todayKey.value,
            dayPlanId = viewModel.dayPlan.value?.id,
            onDismiss = { viewModel.dismissEditor() },
            onSave = { task ->
                if (editingTask == null) viewModel.addTask(task)
                else viewModel.updateTask(task)
                viewModel.dismissEditor()
            }
        )
    }
}

@Composable
fun TaskRow(
    task: StudyTask,
    onEdit: () -> Unit,
    onFocus: () -> Unit,
    onChangeStatus: (StudyTaskStatus) -> Unit,
    onDelete: () -> Unit
) {
    val status = StudyTaskStatus.from(task.status)
    var expanded by remember { mutableStateOf(false) }
    val statusColor = when (status) {
        StudyTaskStatus.DONE -> Success
        StudyTaskStatus.IN_PROGRESS -> Info
        StudyTaskStatus.SKIPPED -> Skipped
        else -> Pending
    }

    DSCard(
        shadow = DSShadow.Small,
        accentColor = statusColor,
        backgroundColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    ) {
        Row(verticalAlignment = Alignment.Top) {
            IconButton(onClick = { expanded = true }) {
                Icon(
                    Icons.Default.MoreVert,
                    contentDescription = "切换状态",
                    tint = statusColor
                )
            }
            DropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                StudyTaskStatus.entries.forEach { s ->
                    DropdownMenuItem(
                        text = { Text(s.displayName) },
                        onClick = {
                            onChangeStatus(s)
                            expanded = false
                        }
                    )
                }
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = task.title.ifBlank { "未命名任务" },
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold,
                    textDecoration = if (status == StudyTaskStatus.DONE) TextDecoration.LineThrough else null,
                    color = if (status == StudyTaskStatus.DONE)
                        MaterialTheme.colorScheme.onSurfaceVariant
                    else
                        MaterialTheme.colorScheme.onSurface
                )
                Spacer(Modifier.height(DesignTokens.Spacing.xs))
                Row {
                    val subjectDisplay = if (task.subject.isBlank()) "未设科目" else LearningSubject.from(task.subject).displayName
                    val categoryDisplay = if (task.category.isBlank()) "未分类" else StudyTaskCategory.from(task.category).displayName
                    DSTag(subjectDisplay)
                    Spacer(Modifier.width(DesignTokens.Spacing.xs))
                    DSTag(categoryDisplay, color = MaterialTheme.colorScheme.secondary)
                }
                Spacer(Modifier.height(DesignTokens.Spacing.xs))
                val estimatedText = task.estimatedMinutes?.let { "预计 $it 分钟" } ?: "预计未填写"
                val actualText = task.actualMinutes?.let { "实际 $it 分钟" } ?: "实际未填写"
                Text(
                    "$estimatedText / $actualText",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (task.outputNote.isNotBlank()) {
                    Spacer(Modifier.height(DesignTokens.Spacing.xs))
                    Text(
                        task.outputNote,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 2
                    )
                }
            }
        }
        Spacer(Modifier.height(DesignTokens.Spacing.sm))
        HorizontalDivider(color = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f))
        Spacer(Modifier.height(DesignTokens.Spacing.sm))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.sm)
        ) {
            DSButton(
                title = "专注",
                icon = Icons.Default.Timer,
                onClick = onFocus,
                style = ButtonStyle.Secondary,
                modifier = Modifier.weight(1f)
            )
            DSButton(
                title = "编辑",
                icon = Icons.Default.Edit,
                onClick = onEdit,
                style = ButtonStyle.Tertiary,
                modifier = Modifier.weight(1f)
            )
            DSButton(
                title = "删除",
                icon = Icons.Default.Delete,
                onClick = onDelete,
                style = ButtonStyle.Destructive,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TaskEditorSheet(
    task: StudyTask?,
    dayKey: String,
    dayPlanId: String?,
    onDismiss: () -> Unit,
    onSave: (StudyTask) -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var title by remember { mutableStateOf(task?.title ?: "") }
    var subject by remember { mutableStateOf(task?.subject ?: "") }
    var category by remember { mutableStateOf(task?.category ?: "") }
    var estimated by remember { mutableIntStateOf(task?.estimatedMinutes ?: 25) }
    var status by remember { mutableStateOf(task?.status ?: StudyTaskStatus.PENDING.storageValue) }
    var outputNote by remember { mutableStateOf(task?.outputNote ?: "") }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            modifier = Modifier
                .padding(DesignTokens.Spacing.lg)
                .fillMaxWidth()
        ) {
            Text(
                if (task == null) "新增任务" else "编辑任务",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(Modifier.height(DesignTokens.Spacing.lg))

            DSInputField(
                value = title,
                onValueChange = { title = it },
                label = "任务标题",
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(Modifier.height(DesignTokens.Spacing.md))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.sm)
            ) {
                var subjectExpanded by remember { mutableStateOf(false) }
                ExposedDropdownMenuBox(
                    expanded = subjectExpanded,
                    onExpandedChange = { subjectExpanded = it },
                    modifier = Modifier.weight(1f)
                ) {
                    OutlinedTextField(
                        value = if (subject.isBlank()) "科目" else LearningSubject.from(subject).displayName,
                        onValueChange = {},
                        readOnly = true,
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = subjectExpanded) },
                        modifier = Modifier.menuAnchor().fillMaxWidth()
                    )
                    ExposedDropdownMenu(
                        expanded = subjectExpanded,
                        onDismissRequest = { subjectExpanded = false }
                    ) {
                        LearningSubject.entries.forEach { s ->
                            DropdownMenuItem(
                                text = { Text(s.displayName) },
                                onClick = { subject = s.displayName; subjectExpanded = false }
                            )
                        }
                    }
                }
                var categoryExpanded by remember { mutableStateOf(false) }
                ExposedDropdownMenuBox(
                    expanded = categoryExpanded,
                    onExpandedChange = { categoryExpanded = it },
                    modifier = Modifier.weight(1f)
                ) {
                    OutlinedTextField(
                        value = if (category.isBlank()) "类型" else StudyTaskCategory.from(category).displayName,
                        onValueChange = {},
                        readOnly = true,
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded) },
                        modifier = Modifier.menuAnchor().fillMaxWidth()
                    )
                    ExposedDropdownMenu(
                        expanded = categoryExpanded,
                        onDismissRequest = { categoryExpanded = false }
                    ) {
                        StudyTaskCategory.entries.forEach { c ->
                            DropdownMenuItem(
                                text = { Text(c.displayName) },
                                onClick = { category = c.storageValue; categoryExpanded = false }
                            )
                        }
                    }
                }
            }
            Spacer(Modifier.height(DesignTokens.Spacing.md))

            Text(
                "预计时长: $estimated 分钟",
                style = MaterialTheme.typography.labelLarge
            )
            Slider(
                value = estimated.toFloat(),
                onValueChange = { estimated = it.toInt() },
                valueRange = 5f..180f,
                steps = 34
            )
            Spacer(Modifier.height(DesignTokens.Spacing.md))

            Text("状态", style = MaterialTheme.typography.labelLarge)
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                StudyTaskStatus.entries.forEachIndexed { index, s ->
                    SegmentedButton(
                        shape = SegmentedButtonDefaults.itemShape(
                            index = index,
                            count = StudyTaskStatus.entries.size
                        ),
                        onClick = { status = s.storageValue },
                        selected = status == s.storageValue
                    ) { Text(s.displayName) }
                }
            }
            Spacer(Modifier.height(DesignTokens.Spacing.md))

            DSInputField(
                value = outputNote,
                onValueChange = { outputNote = it },
                label = "产出记录",
                minLines = 2,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(Modifier.height(DesignTokens.Spacing.lg))

            DSButton(
                title = "保存",
                onClick = {
                    val saved = (task?.copy(
                        title = title,
                        subject = subject,
                        category = category,
                        estimatedMinutes = estimated,
                        status = status,
                        outputNote = outputNote,
                        updatedAt = System.currentTimeMillis()
                    ) ?: StudyTask(
                        dayPlanId = dayPlanId,
                        dayKey = dayKey,
                        title = title,
                        subject = subject,
                        category = category,
                        estimatedMinutes = estimated,
                        status = status,
                        outputNote = outputNote
                    ))
                    onSave(saved)
                },
                style = ButtonStyle.Primary
            )
            Spacer(Modifier.height(DesignTokens.Spacing.xxl))
        }
    }
}
