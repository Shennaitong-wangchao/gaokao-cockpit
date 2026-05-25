package com.gaokao.cockpit.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.TrendingDown
import androidx.compose.material.icons.filled.TrendingFlat
import androidx.compose.material.icons.filled.TrendingUp
import com.gaokao.cockpit.ui.theme.DesignTokens
import com.gaokao.cockpit.ui.theme.Success
import com.gaokao.cockpit.ui.theme.Error
import com.gaokao.cockpit.ui.theme.Warning
import com.gaokao.cockpit.ui.theme.withMonoNumbers

sealed class Trend(val text: String) {
    class Up(text: String) : Trend(text)
    class Down(text: String) : Trend(text)
    class Neutral(text: String) : Trend(text)

    val color: Color
        @Composable get() = when (this) {
            is Up -> Success
            is Down -> Error
            is Neutral -> MaterialTheme.colorScheme.onSurfaceVariant
        }

    val icon: ImageVector
        get() = when (this) {
            is Up -> Icons.Default.TrendingUp
            is Down -> Icons.Default.TrendingDown
            is Neutral -> Icons.Default.TrendingFlat
        }
}

@Composable
fun DSStatCard(
    title: String,
    value: String,
    icon: ImageVector? = null,
    trend: Trend? = null,
    valueColor: Color = MaterialTheme.colorScheme.primary,
    isAnimated: Boolean = true,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(DesignTokens.CornerRadius.medium))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
            .padding(vertical = DesignTokens.Spacing.md, horizontal = DesignTokens.Spacing.lg),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = valueColor,
                modifier = Modifier.size(24.dp)
            )
            Spacer(Modifier.height(DesignTokens.Spacing.xs))
        }

        val numericValue = value.toIntOrNull()
        if (isAnimated && numericValue != null) {
            DSAnimatedNumber(
                target = numericValue,
                style = MaterialTheme.typography.headlineMedium
                    .withMonoNumbers()
                    .copy(fontWeight = FontWeight.Bold),
                color = valueColor
            )
        } else {
            Text(
                text = value,
                style = MaterialTheme.typography.headlineMedium
                    .withMonoNumbers()
                    .copy(fontWeight = FontWeight.Bold),
                color = valueColor
            )
        }

        Spacer(Modifier.height(DesignTokens.Spacing.xs))

        Text(
            text = title,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        if (trend != null) {
            Spacer(Modifier.height(DesignTokens.Spacing.xs))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Icon(
                    imageVector = trend.icon,
                    contentDescription = null,
                    tint = trend.color,
                    modifier = Modifier.size(14.dp)
                )
                Text(
                    text = trend.text,
                    style = MaterialTheme.typography.labelSmall,
                    color = trend.color
                )
            }
        }
    }
}
