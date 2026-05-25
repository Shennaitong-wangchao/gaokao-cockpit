package com.gaokao.cockpit.ui.resources

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
import androidx.compose.material.icons.filled.Book
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
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import com.gaokao.cockpit.data.model.LearningSubject
import com.gaokao.cockpit.data.model.ResourceItem
import com.gaokao.cockpit.data.model.ResourceStatus
import com.gaokao.cockpit.ui.components.DSButton
import com.gaokao.cockpit.ui.components.DSCard
import com.gaokao.cockpit.ui.components.DSInputField
import com.gaokao.cockpit.ui.components.DSShadow
import com.gaokao.cockpit.ui.components.DSTag
import com.gaokao.cockpit.ui.components.EmptyState
import com.gaokao.cockpit.ui.components.ButtonStyle
import com.gaokao.cockpit.ui.components.statusColor
import com.gaokao.cockpit.ui.theme.DesignTokens
import com.gaokao.cockpit.viewmodel.ResourceLibraryViewModel

@Composable
fun ResourceLibraryScreen(viewModel: ResourceLibraryViewModel = hiltViewModel()) {
    val resources by viewModel.resources.collectAsState()
    val selectedStatus by viewModel.selectedStatusFilter.collectAsState()
    val selectedSubject by viewModel.selectedSubjectFilter.collectAsState()
    val showEditor by viewModel.showEditor.collectAsState()
    val editingResource by viewModel.editingResource.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadResources() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(DesignTokens.Spacing.lg)
    ) {
        Text(
            "资源库",
            style = MaterialTheme.typography.displayMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(Modifier.height(DesignTokens.Spacing.md))

        // ====== 状态筛选 ======
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.sm)
        ) {
            FilterChip(
                selected = selectedStatus.isEmpty(),
                onClick = { viewModel.setStatusFilter("") },
                label = { Text("全部") }
            )
            ResourceStatus.entries.forEach { status ->
                FilterChip(
                    selected = selectedStatus == status.storageValue,
                    onClick = { viewModel.setStatusFilter(status.storageValue) },
                    label = { Text(status.displayName) }
                )
            }
        }

        Spacer(Modifier.height(DesignTokens.Spacing.sm))

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

        Spacer(Modifier.height(DesignTokens.Spacing.md))

        // ====== 资源列表 ======
        if (resources.isEmpty()) {
            EmptyState(
                title = "暂无资源",
                message = "点击按钮添加学习资料、参考书或网课链接",
                icon = Icons.Default.Book,
                action = {
                    DSButton(
                        title = "添加资源",
                        icon = Icons.Default.Add,
                        onClick = { viewModel.showAddEditor() }
                    )
                },
                modifier = Modifier.weight(1f)
            )
        } else {
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.md)
            ) {
                items(resources, key = { it.id }) { resource ->
                    ResourceRow(
                        resource = resource,
                        onEdit = { viewModel.showEditEditor(resource) },
                        onDelete = { viewModel.deleteResource(resource.id) },
                        onChangeStatus = { viewModel.updateResourceStatus(resource, it) }
                    )
                }
            }
            Spacer(Modifier.height(DesignTokens.Spacing.sm))
            DSButton(
                title = "添加资源",
                icon = Icons.Default.Add,
                onClick = { viewModel.showAddEditor() },
                style = ButtonStyle.Primary
            )
        }
    }

    if (showEditor) {
        ResourceEditorSheet(
            resource = editingResource,
            onDismiss = { viewModel.dismissEditor() },
            onSave = { viewModel.saveResource(it) }
        )
    }
}

@Composable
private fun ResourceRow(
    resource: ResourceItem,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    onChangeStatus: (ResourceStatus) -> Unit
) {
    val status = ResourceStatus.from(resource.status)
    var expanded by remember { mutableStateOf(false) }

    DSCard(
        shadow = DSShadow.Small,
        accentColor = statusColor(status.storageValue),
        backgroundColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    ) {
        Row(verticalAlignment = Alignment.Top) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    resource.title.ifBlank { "未命名资源" },
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(Modifier.height(DesignTokens.Spacing.xs))
                Row {
                    DSTag(resource.subject.ifBlank { "未分类" })
                    Spacer(Modifier.width(DesignTokens.Spacing.xs))
                    DSTag(
                        resource.type.ifBlank { "未知类型" },
                        color = MaterialTheme.colorScheme.secondary
                    )
                    Spacer(Modifier.width(DesignTokens.Spacing.xs))
                    DSTag(
                        status.displayName,
                        color = statusColor(status.storageValue)
                    )
                }
                if (resource.uri.isNotBlank()) {
                    Spacer(Modifier.height(DesignTokens.Spacing.xs))
                    Text(
                        resource.uri,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                if (resource.note.isNotBlank()) {
                    Spacer(Modifier.height(DesignTokens.Spacing.xs))
                    Text(
                        resource.note,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 2
                    )
                }
            }
            Box {
                IconButton(onClick = { expanded = true }) {
                    Icon(
                        Icons.Default.Edit,
                        contentDescription = "状态",
                        tint = statusColor(status.storageValue)
                    )
                }
                androidx.compose.material3.DropdownMenu(
                    expanded = expanded,
                    onDismissRequest = { expanded = false }
                ) {
                    ResourceStatus.entries.forEach { s ->
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
fun ResourceEditorSheet(
    resource: ResourceItem?,
    onDismiss: () -> Unit,
    onSave: (ResourceItem) -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var title by remember { mutableStateOf(resource?.title ?: "") }
    var subject by remember { mutableStateOf(resource?.subject ?: "") }
    var type by remember { mutableStateOf(resource?.type ?: "") }
    var uri by remember { mutableStateOf(resource?.uri ?: "") }
    var status by remember { mutableStateOf(resource?.status ?: ResourceStatus.UNREAD.storageValue) }
    var note by remember { mutableStateOf(resource?.note ?: "") }

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState) {
        Column(
            modifier = Modifier
                .padding(DesignTokens.Spacing.lg)
                .fillMaxWidth()
        ) {
            Text(
                if (resource == null) "添加资源" else "编辑资源",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(Modifier.height(DesignTokens.Spacing.lg))

            DSInputField(
                value = title,
                onValueChange = { title = it },
                label = "标题",
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
                DSInputField(
                    value = type,
                    onValueChange = { type = it },
                    label = "类型",
                    modifier = Modifier.weight(1f)
                )
            }
            Spacer(Modifier.height(DesignTokens.Spacing.md))
            DSInputField(
                value = uri,
                onValueChange = { uri = it },
                label = "链接/位置",
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(Modifier.height(DesignTokens.Spacing.md))
            DSInputField(
                value = note,
                onValueChange = { note = it },
                label = "备注",
                minLines = 2,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(Modifier.height(DesignTokens.Spacing.lg))
            DSButton(
                title = "保存",
                onClick = {
                    val saved = (resource?.copy(
                        title = title,
                        subject = subject,
                        type = type,
                        uri = uri,
                        status = status,
                        note = note,
                        updatedAt = System.currentTimeMillis()
                    ) ?: ResourceItem(
                        title = title,
                        subject = subject,
                        type = type,
                        uri = uri,
                        status = status,
                        note = note
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
