package com.gaokao.cockpit.ui.components

import android.graphics.BlurMaskFilter
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.gaokao.cockpit.ui.theme.DesignTokens
import com.gaokao.cockpit.ui.theme.ShadowColorLight

/**
 * 弥散式阴影系统 —— 对标 iOS 版阴影效果
 *
 * Compose 默认 elevation 阴影为投影式（ambient + spot），与 iOS 的弥散式阴影不同。
 * 本修饰符使用 drawBehind + BlurMaskFilter 实现柔和弥散阴影。
 */
enum class DSShadow(val radius: Dp, val offsetY: Dp, val alpha: Float) {
    None(0.dp, 0.dp, 0f),
    Small(4.dp, 1.dp, 0.08f),
    Medium(8.dp, 2.dp, 0.10f),
    Large(16.dp, 4.dp, 0.12f);

    companion object {
        val Default = None
    }
}

/**
 * 为任意 Composable 添加弥散式阴影
 *
 * @param shadow 阴影级别
 * @param shape 形状，需与外层 clip 一致
 * @param color 阴影颜色，默认黑色
 */
fun Modifier.dsShadow(
    shadow: DSShadow = DSShadow.None,
    shape: Shape = RoundedCornerShape(DesignTokens.CornerRadius.large),
    color: Color = ShadowColorLight
): Modifier = composed {
    if (shadow == DSShadow.None) return@composed this

    val density = LocalDensity.current
    val radiusPx = with(density) { shadow.radius.toPx() }
    val offsetYPx = with(density) { shadow.offsetY.toPx() }
    val shadowColor = color.copy(alpha = shadow.alpha)

    this.drawBehind {
        val outline = shape.createOutline(size, layoutDirection, density)
        drawIntoCanvas { canvas ->
            val paint = Paint().apply {
                this.color = shadowColor
                asFrameworkPaint().apply {
                    isAntiAlias = true
                    this.color = shadowColor.toArgb()
                    maskFilter = BlurMaskFilter(radiusPx, BlurMaskFilter.Blur.NORMAL)
                }
            }
            canvas.save()
            canvas.translate(0f, offsetYPx)
            canvas.drawOutline(outline, paint)
            canvas.restore()
        }
    }
}

/**
 * 带阴影的 Surface 包装器
 * 内部已处理好 shape + shadow 的一致性
 */
@Composable
fun DSShadowSurface(
    modifier: Modifier = Modifier,
    shadow: DSShadow = DSShadow.Small,
    shape: Shape = RoundedCornerShape(DesignTokens.CornerRadius.large),
    color: Color = MaterialTheme.colorScheme.surface,
    content: @Composable () -> Unit
) {
    Box(
        modifier = modifier
            .dsShadow(shadow = shadow, shape = shape)
            .clip(shape)
            .background(color)
    ) {
        content()
    }
}
