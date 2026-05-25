package com.gaokao.cockpit.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Error
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.gaokao.cockpit.ui.theme.AchievementOrange
import com.gaokao.cockpit.ui.theme.DesignTokens
import com.gaokao.cockpit.ui.theme.Done
import com.gaokao.cockpit.ui.theme.Error
import com.gaokao.cockpit.ui.theme.Info
import com.gaokao.cockpit.ui.theme.InProgress
import com.gaokao.cockpit.ui.theme.LowEnergyBlue
import com.gaokao.cockpit.ui.theme.Pending
import com.gaokao.cockpit.ui.theme.Skipped
import com.gaokao.cockpit.ui.theme.Success
import com.gaokao.cockpit.ui.theme.Warning
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.collectLatest

// ==================== Accent Bar 位置 ====================
enum class AccentPosition {
    Leading, Top, Trailing, Bottom
}

// ==================== DSCard（设计系统卡片）====================
@Composable
fun DSCard(
    modifier: Modifier = Modifier,
    accentColor: Color = MaterialTheme.colorScheme.primary,
    accentPosition: AccentPosition = AccentPosition.Leading,
    shadow: DSShadow = DSShadow.Small,
    backgroundColor: Color = MaterialTheme.colorScheme.surface,
    content: @Composable () -> Unit
) {
    val shape = RoundedCornerShape(DesignTokens.CornerRadius.large)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .dsShadow(shadow = shadow, shape = shape)
            .clip(shape)
            .background(backgroundColor)
            .height(IntrinsicSize.Min)
    ) {
        // Accent Bar
        when (accentPosition) {
            AccentPosition.Leading -> {
                Box(
                    modifier = Modifier
                        .width(4.dp)
                        .background(accentColor)
                        .align(Alignment.CenterStart)
                )
            }
            AccentPosition.Top -> {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .background(accentColor)
                        .align(Alignment.TopCenter)
                )
            }
            AccentPosition.Trailing -> {
                Box(
                    modifier = Modifier
                        .width(4.dp)
                        .background(accentColor)
                        .align(Alignment.CenterEnd)
                )
            }
            AccentPosition.Bottom -> {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .background(accentColor)
                        .align(Alignment.BottomCenter)
                )
            }
        }

        Column(
            modifier = Modifier.padding(DesignTokens.Spacing.lg)
        ) {
            content()
        }
    }
}

// ==================== DSTag（标签）====================
enum class TagStyle {
    Success, Warning, Error, Info, Neutral
}

enum class TagSize {
    Small, Medium
}

@Composable
fun DSTag(
    text: String,
    color: Color = MaterialTheme.colorScheme.primary,
    modifier: Modifier = Modifier
) {
    // 兼容旧版 API：只传 text 和 color
    BaseDSTag(
        text = text,
        color = color,
        icon = null,
        style = TagStyle.Neutral,
        size = TagSize.Small,
        modifier = modifier
    )
}

@Composable
fun DSTag(
    text: String,
    icon: ImageVector? = null,
    style: TagStyle = TagStyle.Neutral,
    size: TagSize = TagSize.Small,
    modifier: Modifier = Modifier
) {
    val color = when (style) {
        TagStyle.Success -> Success
        TagStyle.Warning -> Warning
        TagStyle.Error -> Error
        TagStyle.Info -> Info
        TagStyle.Neutral -> MaterialTheme.colorScheme.primary
    }
    BaseDSTag(
        text = text,
        color = color,
        icon = icon,
        style = style,
        size = size,
        modifier = modifier
    )
}

@Composable
private fun BaseDSTag(
    text: String,
    color: Color,
    icon: ImageVector?,
    style: TagStyle,
    size: TagSize,
    modifier: Modifier = Modifier
) {
    val (horizontalPadding, verticalPadding) = when (size) {
        TagSize.Small -> 8.dp to 3.dp
        TagSize.Medium -> 10.dp to 5.dp
    }
    val textStyle = when (size) {
        TagSize.Small -> MaterialTheme.typography.labelSmall
        TagSize.Medium -> MaterialTheme.typography.labelMedium
    }
    val cornerRadius = when (size) {
        TagSize.Small -> DesignTokens.CornerRadius.small
        TagSize.Medium -> DesignTokens.CornerRadius.medium
    }

    Row(
        modifier = modifier
            .clip(RoundedCornerShape(cornerRadius))
            .background(color.copy(alpha = 0.12f))
            .padding(horizontal = horizontalPadding, vertical = verticalPadding),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(12.dp)
            )
        }
        Text(
            text = text,
            style = textStyle,
            color = color,
            fontWeight = FontWeight.Medium
        )
    }
}

// ==================== Status Colors ====================
@Composable
fun statusColor(status: String): Color = when (status) {
    "done", "已完成" -> Success
    "inProgress", "进行中" -> Info
    "skipped", "已跳过" -> Skipped
    "pending", "未开始" -> Pending
    "new", "新错题" -> MaterialTheme.colorScheme.primary
    "scheduled", "待复习" -> Warning
    "reviewed", "已复习" -> Info
    "mastered", "已掌握" -> Done
    else -> MaterialTheme.colorScheme.onSurfaceVariant
}

// ==================== Section Title ====================
@Composable
fun SectionTitle(
    title: String,
    icon: ImageVector? = null,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp)
            )
            Spacer(Modifier.width(8.dp))
        }
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold
        )
    }
}

// ==================== Empty State ====================
@Composable
fun EmptyState(
    title: String,
    message: String,
    icon: ImageVector = Icons.Default.CheckCircle,
    action: @Composable (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(DesignTokens.Spacing.xxxl),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f),
            modifier = Modifier
                .padding(bottom = DesignTokens.Spacing.md)
                .size(48.dp)
        )
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.SemiBold
        )
        Spacer(Modifier.height(DesignTokens.Spacing.xs))
        Text(
            text = message,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
            textAlign = TextAlign.Center
        )
        if (action != null) {
            Spacer(Modifier.height(DesignTokens.Spacing.xl))
            action()
        }
    }
}

// ==================== Error State ====================
@Composable
fun ErrorState(
    message: String,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(DesignTokens.Spacing.xxxl),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Default.Error,
            contentDescription = null,
            tint = Error,
            modifier = Modifier
                .padding(bottom = DesignTokens.Spacing.md)
                .size(48.dp)
        )
        Text(
            text = "加载失败",
            style = MaterialTheme.typography.titleMedium,
            color = Error,
            fontWeight = FontWeight.SemiBold
        )
        Spacer(Modifier.height(DesignTokens.Spacing.xs))
        Text(
            text = message,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        Spacer(Modifier.height(DesignTokens.Spacing.xl))
        Button(onClick = onRetry) {
            Text("重新加载")
        }
    }
}

// ==================== Snackbar Host with Flow ====================
@Composable
fun DSSnackbarHost(
    snackbarHostState: SnackbarHostState,
    messages: Flow<String?>,
    modifier: Modifier = Modifier
) {
    LaunchedEffect(messages) {
        messages.collectLatest { msg ->
            if (!msg.isNullOrBlank()) {
                snackbarHostState.showSnackbar(
                    message = msg,
                    duration = SnackbarDuration.Short
                )
            }
        }
    }
    SnackbarHost(
        hostState = snackbarHostState,
        modifier = modifier,
        snackbar = { data ->
            val isError = data.visuals.message.contains("失败") || data.visuals.message.contains("错误")
            Snackbar(
                containerColor = if (isError) Error.copy(alpha = 0.9f) else Success.copy(alpha = 0.9f),
                contentColor = Color.White,
                shape = RoundedCornerShape(DesignTokens.CornerRadius.medium)
            ) {
                Text(data.visuals.message, fontWeight = FontWeight.Medium)
            }
        }
    )
}

// ==================== Animated Appear ====================
@Composable
fun AnimatedAppear(
    visible: Boolean = true,
    delayMillis: Int = 0,
    content: @Composable () -> Unit
) {
    AnimatedVisibility(
        visible = visible,
        enter = fadeIn(animationSpec = DSAnimation.Smooth) +
                slideInVertically(initialOffsetY = { it / 4 }),
        exit = fadeOut(animationSpec = DSAnimation.Quick) +
                slideOutVertically(targetOffsetY = { it / 4 })
    ) {
        content()
    }
}
