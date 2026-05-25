package com.gaokao.cockpit.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import com.gaokao.cockpit.ui.theme.DesignTokens

@Composable
fun DSAnimatedNumber(
    target: Int,
    modifier: Modifier = Modifier,
    style: TextStyle = MaterialTheme.typography.headlineMedium,
    color: Color = MaterialTheme.colorScheme.primary,
    durationMillis: Int = 800
) {
    val animatedValue = remember { Animatable(0f) }

    LaunchedEffect(target) {
        animatedValue.animateTo(
            targetValue = target.toFloat(),
            animationSpec = tween(
                durationMillis = durationMillis,
                easing = androidx.compose.animation.core.FastOutSlowInEasing
            )
        )
    }

    Text(
        text = "${animatedValue.value.toInt()}",
        style = style,
        color = color,
        modifier = modifier
    )
}
