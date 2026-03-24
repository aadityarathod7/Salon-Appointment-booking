package com.salon.booking.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.salon.booking.ui.theme.Brand
import com.salon.booking.ui.theme.BrandLight

@Composable
fun RemoteImage(
    url: String?,
    modifier: Modifier = Modifier,
    size: Dp = 60.dp,
    cornerRadius: Dp = 12.dp,
    isCircle: Boolean = false
) {
    val shape = if (isCircle) CircleShape else RoundedCornerShape(cornerRadius)

    if (url != null) {
        AsyncImage(
            model = url,
            contentDescription = null,
            modifier = modifier
                .size(size)
                .clip(shape),
            contentScale = ContentScale.Crop,
        )
    } else {
        Box(
            modifier = modifier
                .size(size)
                .clip(shape)
                .background(BrandLight.copy(alpha = 0.3f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                Icons.Filled.Person,
                contentDescription = null,
                tint = Brand,
                modifier = Modifier.size(size / 2)
            )
        }
    }
}

@Composable
fun ServiceImage(
    url: String?,
    modifier: Modifier = Modifier,
    width: Dp = 160.dp,
    height: Dp = 110.dp,
    cornerRadius: Dp = 12.dp
) {
    if (url != null) {
        AsyncImage(
            model = url,
            contentDescription = null,
            modifier = modifier
                .width(width)
                .height(height)
                .clip(RoundedCornerShape(cornerRadius)),
            contentScale = ContentScale.Crop,
        )
    } else {
        Box(
            modifier = modifier
                .width(width)
                .height(height)
                .clip(RoundedCornerShape(cornerRadius))
                .background(BrandLight.copy(alpha = 0.3f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                Icons.Filled.Person,
                contentDescription = null,
                tint = Brand,
                modifier = Modifier.size(32.dp)
            )
        }
    }
}
