package com.salon.booking.ui.admin

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.salon.booking.domain.model.AdminBooking
import com.salon.booking.domain.model.AdminDashboard

@Composable
fun AdminDashboardScreen(viewModel: AdminViewModel) {
    val dashboard by viewModel.dashboard.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadDashboard() }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF8F5F2)),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Text("Dashboard", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Color(0xFF2D1B14))
        }

        dashboard?.let { data ->
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    StatCard("Bookings", "${data.todayBookings}", Icons.Filled.CalendarMonth, Color(0xFF8B5E3C), Modifier.weight(1f))
                    StatCard("Revenue", "\u20B9${data.todayRevenue.toInt()}", Icons.Filled.CurrencyRupee, Color(0xFF4CAF50), Modifier.weight(1f))
                }
            }
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    StatCard("Artists", "${data.activeArtists}", Icons.Filled.People, Color(0xFFC49A6C), Modifier.weight(1f))
                    StatCard("Customers", "${data.totalCustomers}", Icons.Filled.Groups, Color(0xFF5D3A1A), Modifier.weight(1f))
                }
            }

            if (data.recentBookings.isNotEmpty()) {
                item {
                    Text("Today's Schedule", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color(0xFF2D1B14))
                }
                items(data.recentBookings) { booking ->
                    BookingRow(booking)
                }
            }
        }

        if (isLoading) {
            item {
                Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = Color(0xFF8B5E3C))
                }
            }
        }
    }
}

@Composable
fun StatCard(title: String, value: String, icon: ImageVector, color: Color, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(2.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(24.dp))
            Spacer(Modifier.height(8.dp))
            Text(value, fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Color(0xFF2D1B14))
            Text(title, fontSize = 12.sp, color = Color(0xFF8A7B6B))
        }
    }
}

@Composable
fun BookingRow(booking: AdminBooking) {
    val statusColor = when (booking.status) {
        "CONFIRMED" -> Color(0xFF4CAF50)
        "PENDING" -> Color(0xFFFFA726)
        "IN_PROGRESS" -> Color(0xFFC49A6C)
        "COMPLETED" -> Color(0xFF8B5E3C)
        "CANCELLED" -> Color(0xFFE53935)
        else -> Color(0xFF8A7B6B)
    }

    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(1.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(booking.startTime, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color(0xFF8B5E3C))
                Text(booking.endTime, fontSize = 11.sp, color = Color(0xFF8A7B6B))
            }
            Spacer(Modifier.width(12.dp))
            Box(Modifier.width(3.dp).height(36.dp).clip(RoundedCornerShape(2.dp)).background(statusColor))
            Spacer(Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(booking.service?.name ?: "\u2014", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                Text(booking.artist?.name ?: "\u2014", fontSize = 12.sp, color = Color(0xFF8A7B6B))
            }
            Text(
                booking.status.replace("_", " "),
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                color = statusColor,
                modifier = Modifier
                    .background(statusColor.copy(alpha = 0.1f), RoundedCornerShape(6.dp))
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            )
        }
    }
}
