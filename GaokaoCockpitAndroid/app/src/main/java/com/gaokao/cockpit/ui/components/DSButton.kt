package com.gaokao.cockpit.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.gaokao.cockpit.ui.theme.DesignTokens

enum class ButtonStyle {
    Primary, Secondary, Tertiary, Destructive
}

@Composable
fun DSButton(
    title: String,
    icon: ImageVector? = null,
    onClick: () -> Unit,
    style: ButtonStyle = ButtonStyle.Primary,
    isLoading: Boolean = false,
    isDisabled: Boolean = false,
    modifier: Modifier = Modifier
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.97f else 1f,
        animationSpec = DSAnimation.Spring,
        label = "button_scale"
    )

    val (backgroundColor, foregroundColor) = when (style) {
        ButtonStyle.Primary -> MaterialTheme.colorScheme.primary to Color.White
        ButtonStyle.Secondary -> MaterialTheme.colorScheme.surfaceVariant to MaterialTheme.colorScheme.onSurface
        ButtonStyle.Tertiary -> Color.Transparent to MaterialTheme.colorScheme.primary
        ButtonStyle.Destructive -> MaterialTheme.colorScheme.error to Color.White
    }

    val alpha = if (isDisabled || isLoading) DesignTokens.Alpha.disabled else 1f

    Row(
        modifier = modifier
            .fillMaxWidth()
            .scale(scale)
            .clip(RoundedCornerShape(DesignTokens.CornerRadius.medium))
            .background(backgroundColor)
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                enabled = !isDisabled && !isLoading,
                onClick = onClick
            )
            .padding(vertical = DesignTokens.Spacing.md)
            .padding(horizontal = DesignTokens.Spacing.lg),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(20.dp),
                color = foregroundColor,
                strokeWidth = 2.dp
            )
        } else {
            if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = foregroundColor.copy(alpha = alpha),
                    modifier = Modifier.size(20.dp)
                )
                Spacer(Modifier.width(DesignTokens.Spacing.sm))
            }
            Text(
                text = title,
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color = foregroundColor.copy(alpha = alpha)
            )
        }
    }
}

