package com.gaokao.cockpit.ui.mistakes

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.gaokao.cockpit.data.model.LearningSubject
import com.gaokao.cockpit.data.model.MistakeRecord
import com.gaokao.cockpit.data.model.MistakeType
import com.gaokao.cockpit.data.model.ReviewStatus
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
import com.gaokao.cockpit.ui.theme.Success
import com.gaokao.cockpit.ui.theme.Warning
import com.gaokao.cockpit.viewmodel.MistakeSurgeryViewModel

@Composable
fun MistakeSurgeryScreen(viewModel: MistakeSurgeryViewModel = hiltViewModel()) {
    val isLoading by viewModel.isLoading.collectAsState()
    val mistakes by viewModel.mistakes.collectAsState()
    val totalCount by viewModel.totalMistakeCount.collectAsState()
    val scheduledCount by viewModel.scheduledCount.collectAsState()
    val reviewedCount by viewModel.reviewedCount.collectAsState()
    val masteredCount by viewModel.masteredCount.collectAsState()
    val selectedSubject by viewModel.selectedSubjectFilter.collectAsState()
    val selectedReview by viewModel.selectedReviewFilter.collectAsState()
    val statusMessage by viewModel.statusMessage.collectAsState()
    val showEditor by viewModel.showEditor.collectAsState()
    val editingMistake by viewModel.editingMistake.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(DesignTokens.Spacing.lg)
    ) {
        Text(
            "错题手术",
            style = MaterialTheme.typography.displayMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(Modifier.height(DesignTokens.Spacing.md))

        // ====== 统计卡片 ======
        DSCard(shadow = DSShadow.Medium) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                DSStatCard(
                    title = "总错题",
                    value = totalCount.toString(),
                    valueColor = MaterialTheme.colorScheme.primary,
                    isAnimated = true
                )
                DSStatCard(
                    title = "待复习",
                    value = scheduledCount.toString(),
                    valueColor = Warning,
                    isAnimated = true
                )
                DSStatCard(
                    title = "已复习",
                    value = reviewedCount.toString(),
                    valueColor = Info,
                    isAnimated = true
                )
                DSStatCard(
                    title = "已掌握",
                    value = masteredCount.toString(),
                    valueColor = Success,
                    isAnimated = true
                )
            }
        }

        Spacer(Modifier.height(DesignTokens.Spacing.md))

        // ====== 科目筛选 ======
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.sm)
        ) {
            FilterChip(
                selected = selectedSubject.isEmpty(),
                onClick = { viewModel.setSubjectFilter("") },
                label = { Text("全部科目") }
            )
            LearningSubject.entries.forEach { subject ->
                FilterChip(
                    selected = selectedSubject == subject.displayName,
                    onClick = { viewModel.setSubjectFilter(subject.displayName) },
                    label = { Text(subject.displayName) }
                )
            }
        }

        Spacer(Modifier.height(DesignTokens.Spacing.sm))

        // ====== 状态筛选 ======
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.sm)
        ) {
            FilterChip(
                selected = selectedReview.isEmpty(),
                onClick = { viewModel.setReviewFilter("") },
                label = { Text("全部状态") }
            )
            ReviewStatus.entries.forEach { status ->
                FilterChip(
                    selected = selectedReview == status.storageValue,
                    onClick = { viewModel.setReviewFilter(status.storageValue) },
                    label = { Text(status.displayName) }
                )
            }
        }

        Spacer(Modifier.height(DesignTokens.Spacing.md))

        // ====== 错题列表 ======
        if (isLoading) {
            Box(
                modifier = Modifier.fillMaxSize().weight(1f),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else if (mistakes.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize().weight(1f),
                contentAlignment = Alignment.Center
            ) {
                EmptyState(
                    title = "还没有错题",
                    message = "下一次做错题时，先拍题图，再拆错因。",
                    icon = Icons.Default.CheckCircle,
                    action = {
                        DSButton(
                            title = "新增错题手术",
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
                items(mistakes, key = { it.id }) { mistake ->
                    MistakeRow(
                        mistake = mistake,
                        onEdit = { viewModel.showEditEditor(mistake) },
                        onChangeStatus = { viewModel.updateReviewStatus(mistake, it) },
                        onDelete = { viewModel.deleteMistake(mistake.id) }
                    )
                }
            }
            Spacer(Modifier.height(DesignTokens.Spacing.sm))
            DSButton(
                title = "新增错题手术",
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
        MistakeEditorSheet(
            mistake = editingMistake,
            onDismiss = { viewModel.dismissEditor() },
            onSave = { viewModel.saveMistake(it) }
        )
    }
}

@Composable
fun MistakeRow(
    mistake: MistakeRecord,
    onEdit: () -> Unit,
    onChangeStatus: (ReviewStatus) -> Unit,
    onDelete: () -> Unit
) {
    val status = ReviewStatus.from(mistake.reviewStatus)
    val statusColor = when (status) {
        ReviewStatus.MASTERED -> Success
        ReviewStatus.REVIEWED -> Info
        ReviewStatus.SCHEDULED -> Warning
        else -> MaterialTheme.colorScheme.primary
    }
    var expanded by remember { mutableStateOf(false) }

    DSCard(
        shadow = DSShadow.Small,
        accentColor = statusColor,
        backgroundColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    ) {
        Row(verticalAlignment = Alignment.Top) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    mistake.questionText.ifBlank { "无题面文本" },
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 2
                )
                Spacer(Modifier.height(DesignTokens.Spacing.xs))
                Row {
                    DSTag(mistake.subject.ifBlank { "未设科目" })
                    Spacer(Modifier.width(DesignTokens.Spacing.xs))
                    DSTag(
                        mistake.chapter.ifBlank { "未设章节" },
                        color = MaterialTheme.colorScheme.secondary
                    )
                    Spacer(Modifier.width(DesignTokens.Spacing.xs))
                    DSTag(
                        MistakeType.from(mistake.mistakeType).displayName,
                        color = statusColor
                    )
                }
                Spacer(Modifier.height(DesignTokens.Spacing.xs))
                Text(
                    "来源: ${mistake.source}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (mistake.rootCause.isNotBlank()) {
                    Spacer(Modifier.height(DesignTokens.Spacing.xs))
                    Text(
                        "错因: ${mistake.rootCause}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 2
                    )
                }
            }
            Box {
                IconButton(onClick = { expanded = true }) {
                    Icon(
                        Icons.Default.CheckCircle,
                        contentDescription = "状态",
                        tint = statusColor
                    )
                }
                androidx.compose.material3.DropdownMenu(
                    expanded = expanded,
                    onDismissRequest = { expanded = false }
                ) {
                    ReviewStatus.entries.forEach { s ->
                        DropdownMenuItem(
                            text = { Text(s.displayName) },
                            onClick = { onChangeStatus(s); expanded = false }
                        )
                    }
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
                title = "编辑",
                icon = Icons.Default.Edit,
                onClick = onEdit,
                style = ButtonStyle.Secondary,
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
fun MistakeEditorSheet(
    mistake: MistakeRecord?,
    onDismiss: () -> Unit,
    onSave: (MistakeRecord) -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var subject by remember { mutableStateOf(mistake?.subject ?: "") }
    var chapter by remember { mutableStateOf(mistake?.chapter ?: "") }
    var source by remember { mutableStateOf(mistake?.source ?: "") }
    var questionText by remember { mutableStateOf(mistake?.questionText ?: "") }
    var mySolution by remember { mutableStateOf(mistake?.mySolution ?: "") }
    var correctSolution by remember { mutableStateOf(mistake?.correctSolution ?: "") }
    var mistakeType by remember { mutableStateOf(mistake?.mistakeType ?: MistakeType.CONCEPT.storageValue) }
    var rootCause by remember { mutableStateOf(mistake?.rootCause ?: "") }
    var questionSignal by remember { mutableStateOf(mistake?.questionSignal ?: "") }
    var correctModel by remember { mutableStateOf(mistake?.correctModel ?: "") }
    var variantTask by remember { mutableStateOf(mistake?.variantTask ?: "") }
    var reviewStatus by remember { mutableStateOf(mistake?.reviewStatus ?: ReviewStatus.NEW.storageValue) }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            modifier = Modifier
                .padding(DesignTokens.Spacing.lg)
                .fillMaxWidth()
                .height(600.dp)
        ) {
            Text(
                if (mistake == null) "新增错题手术" else "编辑错题",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(Modifier.height(DesignTokens.Spacing.lg))

            rememberScrollState().let { scrollState ->
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .verticalScroll(scrollState)
                ) {
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
                        var typeExpanded by remember { mutableStateOf(false) }
                        ExposedDropdownMenuBox(
                            expanded = typeExpanded,
                            onExpandedChange = { typeExpanded = it },
                            modifier = Modifier.weight(1f)
                        ) {
                            OutlinedTextField(
                                value = MistakeType.from(mistakeType).displayName,
                                onValueChange = {},
                                readOnly = true,
                                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = typeExpanded) },
                                modifier = Modifier.menuAnchor().fillMaxWidth()
                            )
                            ExposedDropdownMenu(
                                expanded = typeExpanded,
                                onDismissRequest = { typeExpanded = false }
                            ) {
                                MistakeType.entries.forEach { t ->
                                    DropdownMenuItem(
                                        text = { Text(t.displayName) },
                                        onClick = { mistakeType = t.storageValue; typeExpanded = false }
                                    )
                                }
                            }
                        }
                    }
                    Spacer(Modifier.height(DesignTokens.Spacing.md))

                    DSInputField(
                        value = chapter,
                        onValueChange = { chapter = it },
                        label = "章节",
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    DSInputField(
                        value = source,
                        onValueChange = { source = it },
                        label = "来源",
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    DSInputField(
                        value = questionText,
                        onValueChange = { questionText = it },
                        label = "题面",
                        minLines = 2,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    DSInputField(
                        value = mySolution,
                        onValueChange = { mySolution = it },
                        label = "我的解法",
                        minLines = 2,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    DSInputField(
                        value = correctSolution,
                        onValueChange = { correctSolution = it },
                        label = "正确解法",
                        minLines = 2,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    DSInputField(
                        value = rootCause,
                        onValueChange = { rootCause = it },
                        label = "错因",
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    DSInputField(
                        value = questionSignal,
                        onValueChange = { questionSignal = it },
                        label = "题目信号",
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    DSInputField(
                        value = correctModel,
                        onValueChange = { correctModel = it },
                        label = "正确模型",
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    DSInputField(
                        value = variantTask,
                        onValueChange = { variantTask = it },
                        label = "变式任务",
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(Modifier.height(DesignTokens.Spacing.md))
                    Text("复习状态", style = MaterialTheme.typography.labelLarge)
                    SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                        ReviewStatus.entries.forEachIndexed { index, s ->
                            SegmentedButton(
                                shape = SegmentedButtonDefaults.itemShape(
                                    index = index,
                                    count = ReviewStatus.entries.size
                                ),
                                onClick = { reviewStatus = s.storageValue },
                                selected = reviewStatus == s.storageValue
                            ) { Text(s.displayName) }
                        }
                    }
                }
            }
            Spacer(Modifier.height(DesignTokens.Spacing.lg))
            DSButton(
                title = "保存",
                onClick = {
                    val saved = (mistake?.copy(
                        subject = subject,
                        chapter = chapter,
                        source = source,
                        questionText = questionText,
                        mySolution = mySolution,
                        correctSolution = correctSolution,
                        mistakeType = mistakeType,
                        rootCause = rootCause,
                        questionSignal = questionSignal,
                        correctModel = correctModel,
                        variantTask = variantTask,
                        reviewStatus = reviewStatus,
                        updatedAt = System.currentTimeMillis()
                    ) ?: MistakeRecord(
                        subject = subject,
                        chapter = chapter,
                        source = source,
                        questionText = questionText,
                        mySolution = mySolution,
                        correctSolution = correctSolution,
                        mistakeType = mistakeType,
                        rootCause = rootCause,
                        questionSignal = questionSignal,
                        correctModel = correctModel,
                        variantTask = variantTask,
                        reviewStatus = reviewStatus
                    ))
                    onSave(saved)
                    onDismiss()
                },
                style = ButtonStyle.Primary
            )
            Spacer(Modifier.height(DesignTokens.Spacing.xxl))
        }
    }
}
