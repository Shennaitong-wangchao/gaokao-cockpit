package com.gaokao.cockpit.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ProgressIndicatorDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.gaokao.cockpit.ui.theme.DesignTokens
import com.gaokao.cockpit.ui.theme.withMonoNumbers

enum class ProgressStyle {
    Linear, Ring
}

@Composable
fun DSProgressBar(
    progress: Float,
    style: ProgressStyle = ProgressStyle.Linear,
    color: Color = MaterialTheme.colorScheme.primary,
    showPercentage: Boolean = true,
    isAnimated: Boolean = true,
    modifier: Modifier = Modifier
) {
    val animatedProgress by animateFloatAsState(
        targetValue = progress.coerceIn(0f, 1f),
        animationSpec = DSAnimation.Smooth,
        label = "progress_animation"
    )

    when (style) {
        ProgressStyle.Linear -> LinearProgress(
            progress = if (isAnimated) animatedProgress else progress,
            color = color,
            showPercentage = showPercentage,
            modifier = modifier
        )
        ProgressStyle.Ring -> RingProgress(
            progress = if (isAnimated) animatedProgress else progress,
            color = color,
            showPercentage = showPercentage,
            modifier = modifier
        )
    }
}

@Composable
private fun LinearProgress(
    progress: Float,
    color: Color,
    showPercentage: Boolean,
    modifier: Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.Start
    ) {
        if (showPercentage) {
            Text(
                text = "${(progress * 100).toInt()}%",
                style = MaterialTheme.typography.labelSmall.copy(
                    fontWeight = FontWeight.Medium
                ),
                color = color
            )
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(DesignTokens.Size.progressBarHeight)
                .clip(RoundedCornerShape(DesignTokens.Size.progressBarHeight / 2))
                .background(MaterialTheme.colorScheme.surfaceVariant)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .fillMaxWidth(progress)
                    .clip(RoundedCornerShape(DesignTokens.Size.progressBarHeight / 2))
                    .background(color)
            )
        }
    }
}

@Composable
private fun RingProgress(
    progress: Float,
    color: Color,
    showPercentage: Boolean,
    modifier: Modifier
) {
    Box(
        modifier = modifier.size(DesignTokens.Size.progressRingSize),
        contentAlignment = Alignment.Center
    ) {
        // 背景圆环
        CircularProgressIndicator(
            progress = { 1f },
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.surfaceVariant,
            strokeWidth = DesignTokens.Size.progressRingStroke,
            trackColor = Color.Transparent,
            strokeCap = StrokeCap.Round
        )
        // 进度圆环
        CircularProgressIndicator(
            progress = { progress },
            modifier = Modifier.fillMaxSize(),
            color = color,
            strokeWidth = DesignTokens.Size.progressRingStroke,
            trackColor = Color.Transparent,
            strokeCap = StrokeCap.Round
        )

        if (showPercentage) {
            Text(
                text = "${(progress * 100).toInt()}%",
                style = MaterialTheme.typography.bodyMedium
                    .withMonoNumbers()
                    .copy(fontWeight = FontWeight.Bold),
                color = color
            )
        }
    }
}
