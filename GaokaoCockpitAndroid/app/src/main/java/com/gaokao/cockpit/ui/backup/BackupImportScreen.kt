package com.gaokao.cockpit.ui.backup

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CloudUpload
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.FileOpen
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.gaokao.cockpit.ui.components.DSButton
import com.gaokao.cockpit.ui.components.DSCard
import com.gaokao.cockpit.ui.components.DSShadow
import com.gaokao.cockpit.ui.components.DSTag
import com.gaokao.cockpit.ui.components.EmptyState
import com.gaokao.cockpit.ui.components.ButtonStyle
import com.gaokao.cockpit.ui.theme.DesignTokens
import com.gaokao.cockpit.ui.theme.Error
import com.gaokao.cockpit.ui.theme.Success
import com.gaokao.cockpit.viewmodel.BackupImportViewModel
import com.gaokao.cockpit.viewmodel.ImportPreviewState

@Composable
fun BackupImportScreen(
    onBack: () -> Unit,
    viewModel: BackupImportViewModel = hiltViewModel()
) {
    val previewState by viewModel.previewState.collectAsState()
    val isImporting by viewModel.isImporting.collectAsState()
    val importResult by viewModel.importResult.collectAsState()

    val filePicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument(),
        onResult = { uri ->
            uri?.let { viewModel.parseBackupFile(it) }
        }
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(DesignTokens.Spacing.lg)
            .verticalScroll(rememberScrollState())
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "返回")
            }
            Text(
                "数据恢复",
                style = MaterialTheme.typography.displayMedium,
                fontWeight = FontWeight.Bold
            )
        }

        Spacer(Modifier.height(DesignTokens.Spacing.lg))

        when (previewState) {
            is ImportPreviewState.Idle -> {
                IdleState(
                    onPickFile = { filePicker.launch(arrayOf("application/json", "*/*")) },
                    importResult = importResult,
                    onReset = { viewModel.reset() }
                )
            }
            is ImportPreviewState.Parsing -> {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(DesignTokens.Spacing.xxxl),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    CircularProgressIndicator()
                    Spacer(Modifier.height(DesignTokens.Spacing.lg))
                    Text(
                        "正在解析备份文件...",
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            }
            is ImportPreviewState.Error -> {
                val error = previewState as ImportPreviewState.Error
                EmptyState(
                    title = "解析失败",
                    message = error.message,
                    icon = Icons.Default.Error,
                    action = {
                        DSButton(
                            title = "重新选择",
                            onClick = { viewModel.reset() },
                            style = ButtonStyle.Primary
                        )
                    },
                    modifier = Modifier.fillMaxWidth().padding(DesignTokens.Spacing.xxxl)
                )
            }
            is ImportPreviewState.Preview -> {
                val preview = previewState as ImportPreviewState.Preview
                PreviewState(
                    preview = preview,
                    isImporting = isImporting,
                    onImport = {
                        viewModel.executeImport(
                            tasks = preview.tasks,
                            dayPlans = preview.dayPlans,
                            focusSessions = preview.focusSessions,
                            mistakes = preview.mistakes,
                            dailyReviews = preview.dailyReviews,
                            weeklyReviews = preview.weeklyReviews,
                            resources = preview.resources
                        )
                    },
                    onCancel = { viewModel.reset() }
                )
            }
        }

        Spacer(Modifier.height(DesignTokens.Spacing.xxl))
    }
}

@Composable
private fun IdleState(
    onPickFile: () -> Unit,
    importResult: String?,
    onReset: () -> Unit
) {
    DSCard(
        shadow = DSShadow.Medium,
        backgroundColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.2f)
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.CloudUpload,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(Modifier.height(DesignTokens.Spacing.lg))
            Text(
                "从备份文件恢复数据",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Spacer(Modifier.height(DesignTokens.Spacing.sm))
            Text(
                "选择之前导出的 JSON 备份文件，系统会解析并预览将要恢复的数据，确认后执行导入。",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(DesignTokens.Spacing.xxl))
            DSButton(
                title = "选择备份文件",
                icon = Icons.Default.FileOpen,
                onClick = onPickFile,
                style = ButtonStyle.Primary
            )
        }
    }

    if (importResult != null) {
        Spacer(Modifier.height(DesignTokens.Spacing.lg))
        DSCard(
            shadow = DSShadow.Small,
            backgroundColor = if (importResult.contains("失败"))
                Error.copy(alpha = 0.1f)
            else
                Success.copy(alpha = 0.1f)
        ) {
            Column {
                Text(
                    importResult,
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (importResult.contains("失败")) Error else Success
                )
                Spacer(Modifier.height(DesignTokens.Spacing.sm))
                TextButton(onClick = onReset) { Text("关闭") }
            }
        }
    }
}

@Composable
private fun PreviewState(
    preview: ImportPreviewState.Preview,
    isImporting: Boolean,
    onImport: () -> Unit,
    onCancel: () -> Unit
) {
    val selectedCategories = remember { mutableStateMapOf<String, Boolean>() }
    val categories = listOf(
        Triple("dayPlans", "DayPlan", preview.dayPlans.size),
        Triple("tasks", "任务", preview.tasks.size),
        Triple("mistakes", "错题", preview.mistakes.size),
        Triple("focusSessions", "专注记录", preview.focusSessions.size),
        Triple("dailyReviews", "每日复盘", preview.dailyReviews.size),
        Triple("weeklyReviews", "周复盘", preview.weeklyReviews.size),
        Triple("resources", "资源", preview.resources.size),
    ).filter { it.third > 0 }

    categories.forEach { (key, _, _) ->
        if (selectedCategories[key] == null) selectedCategories[key] = true
    }

    DSCard(shadow = DSShadow.Medium) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                Icons.Default.CheckCircle,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(Modifier.width(DesignTokens.Spacing.sm))
            Text(
                "数据预览",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        }
        Spacer(Modifier.height(DesignTokens.Spacing.xs))
        Text(
            "共发现 ${preview.totalCount} 条数据，选择要导入的类别后确认。",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(Modifier.height(DesignTokens.Spacing.lg))

        categories.forEach { (key, label, count) ->
            val isSelected = selectedCategories[key] == true
            DSCard(
                shadow = DSShadow.None,
                accentColor = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline,
                backgroundColor = if (isSelected)
                    MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                else
                    MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f),
                modifier = Modifier.padding(vertical = DesignTokens.Spacing.xs)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(
                            checked = isSelected,
                            onCheckedChange = { selectedCategories[key] = it }
                        )
                        Spacer(Modifier.width(DesignTokens.Spacing.sm))
                        Text(label, style = MaterialTheme.typography.bodyLarge)
                    }
                    DSTag("$count 条")
                }
            }
        }

        Spacer(Modifier.height(DesignTokens.Spacing.lg))
        val selectedCount = categories.filter { selectedCategories[it.first] == true }.sumOf { it.third }
        Text(
            "已选择导入 $selectedCount 条数据",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.Medium
        )
        Spacer(Modifier.height(DesignTokens.Spacing.md))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.sm)
        ) {
            DSButton(
                title = "取消",
                onClick = onCancel,
                style = ButtonStyle.Tertiary,
                modifier = Modifier.weight(1f)
            )
            DSButton(
                title = if (isImporting) "导入中..." else "确认导入 ($selectedCount)",
                icon = Icons.Default.CloudUpload,
                onClick = onImport,
                isLoading = isImporting,
                style = ButtonStyle.Primary,
                modifier = Modifier.weight(1f)
            )
        }
    }
}
