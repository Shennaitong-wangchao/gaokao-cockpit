package com.gaokao.cockpit.ui.prompts

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
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Message
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.foundation.clickable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.gaokao.cockpit.data.model.PromptCategory
import com.gaokao.cockpit.data.model.PromptTemplate
import com.gaokao.cockpit.ui.components.DSButton
import com.gaokao.cockpit.ui.components.DSCard
import com.gaokao.cockpit.ui.components.DSInputField
import com.gaokao.cockpit.ui.components.DSShadow
import com.gaokao.cockpit.ui.components.DSTag
import com.gaokao.cockpit.ui.components.EmptyState
import com.gaokao.cockpit.ui.components.ButtonStyle
import com.gaokao.cockpit.ui.theme.DesignTokens
import com.gaokao.cockpit.viewmodel.PromptLibraryViewModel

@Composable
fun PromptLibraryScreen(
    onTemplateClick: (String) -> Unit,
    viewModel: PromptLibraryViewModel = hiltViewModel()
) {
    val isLoading by viewModel.isLoading.collectAsState()
    val templates by viewModel.templates.collectAsState()
    val selectedCategory by viewModel.selectedCategory.collectAsState()
    val statusMessage by viewModel.statusMessage.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(DesignTokens.Spacing.lg)
    ) {
        Text(
            "提示词库",
            style = MaterialTheme.typography.displayMedium,
            fontWeight = FontWeight.Bold
        )
        Spacer(Modifier.height(DesignTokens.Spacing.md))

        // ====== 分类筛选 ======
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.sm)
        ) {
            FilterChip(
                selected = selectedCategory.isEmpty(),
                onClick = { viewModel.setCategory("") },
                label = { Text("全部") }
            )
            PromptCategory.entries.filter { it != PromptCategory.ALL }.forEach { cat ->
                FilterChip(
                    selected = selectedCategory == cat.storageValue,
                    onClick = { viewModel.setCategory(cat.storageValue) },
                    label = { Text(cat.displayName) }
                )
            }
        }

        Spacer(Modifier.height(DesignTokens.Spacing.md))

        // ====== 模板列表 ======
        if (isLoading) {
            Box(
                modifier = Modifier.fillMaxSize().weight(1f),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else if (templates.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize().weight(1f),
                contentAlignment = Alignment.Center
            ) {
                EmptyState(
                    title = "暂无提示词模板",
                    message = "还没有可用的 Prompt 模板"
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(DesignTokens.Spacing.md)
            ) {
                items(templates, key = { it.id }) { template ->
                    PromptTemplateCard(
                        template = template,
                        onClick = { onTemplateClick(template.id) },
                        onCopy = { viewModel.incrementUsage(template) }
                    )
                }
            }
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
}

@Composable
private fun PromptTemplateCard(
    template: PromptTemplate,
    onClick: () -> Unit,
    onCopy: () -> Unit
) {
    val clipboardManager = LocalClipboardManager.current

    DSCard(
        shadow = DSShadow.Small,
        modifier = Modifier.clickable(onClick = onClick)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                Icons.Default.Message,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(Modifier.width(DesignTokens.Spacing.sm))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    template.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(Modifier.height(DesignTokens.Spacing.xs))
                DSTag(
                    PromptCategory.from(template.category).displayName,
                    color = MaterialTheme.colorScheme.primary
                )
                Spacer(Modifier.height(DesignTokens.Spacing.xs))
                Text(
                    template.templateDescription,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2
                )
                Spacer(Modifier.height(DesignTokens.Spacing.xs))
                Text(
                    "使用次数: ${template.usageCount}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                )
            }
            IconButton(onClick = {
                clipboardManager.setText(AnnotatedString(template.templateText))
                onCopy()
            }) {
                Icon(
                    Icons.Default.ContentCopy,
                    contentDescription = "复制",
                    tint = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

@Composable
fun PromptTemplateDetailScreen(
    templateId: String,
    onBack: () -> Unit,
    viewModel: PromptLibraryViewModel = hiltViewModel()
) {
    val templates by viewModel.templates.collectAsState()
    val template = templates.find { it.id == templateId }
    val clipboardManager = LocalClipboardManager.current
    val variables = remember(template?.variablesText) {
        template?.variablesText?.split(",")?.map { it.trim() } ?: emptyList()
    }
    val variableValues = remember(variables) { mutableStateOf<Map<String, String>>(emptyMap()) }
    var renderedText by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(DesignTokens.Spacing.lg)
    ) {
        if (template == null) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("模板未找到", style = MaterialTheme.typography.titleMedium)
            }
        } else {
            TextButton(onClick = onBack) { Text("返回") }
            Spacer(Modifier.height(DesignTokens.Spacing.sm))
            Text(
                template.title,
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            DSTag(
                PromptCategory.from(template.category).displayName,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(Modifier.height(DesignTokens.Spacing.md))
            Text(
                template.templateDescription,
                style = MaterialTheme.typography.bodyLarge
            )
            Spacer(Modifier.height(DesignTokens.Spacing.lg))

            Text(
                "变量",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(Modifier.height(DesignTokens.Spacing.md))
            variables.forEach { variable ->
                DSInputField(
                    value = variableValues.value[variable] ?: "",
                    onValueChange = {
                        variableValues.value = variableValues.value.toMutableMap().apply { put(variable, it) }
                    },
                    label = variable,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(DesignTokens.Spacing.sm))
            }

            DSButton(
                title = "生成",
                onClick = {
                    var result = template.templateText
                    variableValues.value.forEach { (k, v) ->
                        result = result.replace("{{$k}}", v)
                    }
                    renderedText = result
                },
                style = ButtonStyle.Primary
            )

            if (renderedText.isNotBlank()) {
                Spacer(Modifier.height(DesignTokens.Spacing.lg))
                DSCard(shadow = DSShadow.Medium) {
                    Column {
                        Text(
                            "生成结果",
                            style = MaterialTheme.typography.titleMedium
                        )
                        Spacer(Modifier.height(DesignTokens.Spacing.md))
                        Text(
                            renderedText,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Spacer(Modifier.height(DesignTokens.Spacing.md))
                        DSButton(
                            title = "复制到剪贴板",
                            icon = Icons.Default.ContentCopy,
                            onClick = {
                                clipboardManager.setText(AnnotatedString(renderedText))
                                viewModel.incrementUsage(template)
                            },
                            style = ButtonStyle.Secondary
                        )
                    }
                }
            }
        }
    }
}
