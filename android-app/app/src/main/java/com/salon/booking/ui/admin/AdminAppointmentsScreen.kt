package com.salon.booking.ui.admin

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.salon.booking.domain.model.AdminBooking

@Composable
fun AdminAppointmentsScreen(viewModel: AdminViewModel) {
    val appointments by viewModel.appointments.collectAsState()
    var selectedStatus by remember { mutableStateOf("") }
    val statuses = listOf("", "PENDING", "CONFIRMED", "IN_PROGRESS", "COMPLETED", "REJECTED", "CANCELLED")

    LaunchedEffect(Unit) { viewModel.loadAppointments() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF8F5F2))
    ) {
        // Header
        Text(
            "Appointments",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF2D1B14),
            modifier = Modifier.padding(16.dp)
        )

        // Status filter chips
        Row(
            modifier = Modifier
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            statuses.forEach { status ->
                FilterChip(
                    selected = selectedStatus == status,
                    onClick = {
                        selectedStatus = status
                        viewModel.loadAppointments(
                            status = status.ifEmpty { null }
                        )
                    },
                    label = {
                        Text(
                            if (status.isEmpty()) "All" else status.replace("_", " "),
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = Color(0xFF8B5E3C),
                        selectedLabelColor = Color.White
                    )
                )
            }
        }

        Spacer(Modifier.height(8.dp))

        // List
        if (appointments.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Filled.EventBusy, contentDescription = null, modifier = Modifier.size(48.dp), tint = Color(0xFFBDAFA3))
                    Spacer(Modifier.height(8.dp))
                    Text("No appointments found", color = Color(0xFF8A7B6B))
                }
            }
        } else {
            LazyColumn(
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(appointments) { booking ->
                    AdminAppointmentCard(booking = booking, onStatusChange = { newStatus ->
                        viewModel.updateStatus(booking.id, newStatus)
                    })
                }
            }
        }
    }
}

@Composable
fun AdminAppointmentCard(booking: AdminBooking, onStatusChange: (String) -> Unit) {
    val statusColor = when (booking.status) {
        "CONFIRMED" -> Color(0xFF4CAF50)
        "PENDING" -> Color(0xFFFFA726)
        "IN_PROGRESS" -> Color(0xFFC49A6C)
        "COMPLETED" -> Color(0xFF8B5E3C)
        "CANCELLED", "REJECTED" -> Color(0xFFE53935)
        else -> Color(0xFF8A7B6B)
    }

    data class ActionBtn(val label: String, val status: String, val destructive: Boolean)

    val actionButtons = when (booking.status) {
        "PENDING" -> listOf(
            ActionBtn("Accept", "CONFIRMED", false),
            ActionBtn("Reject", "REJECTED", true)
        )
        "CONFIRMED" -> listOf(
            ActionBtn("Start", "IN_PROGRESS", false),
            ActionBtn("Cancel", "CANCELLED", true),
            ActionBtn("No Show", "NO_SHOW", true)
        )
        "IN_PROGRESS" -> listOf(
            ActionBtn("Complete", "COMPLETED", false),
            ActionBtn("Cancel", "CANCELLED", true)
        )
        else -> emptyList()
    }

    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(2.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            // Header
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    booking.bookingRef ?: "",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF8A7B6B)
                )
                Spacer(Modifier.weight(1f))
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
            Spacer(Modifier.height(8.dp))

            // Details
            Row {
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.ContentCut, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color(0xFF8A7B6B))
                        Spacer(Modifier.width(4.dp))
                        Text(booking.service?.name ?: "\u2014", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Person, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color(0xFF8A7B6B))
                        Spacer(Modifier.width(4.dp))
                        Text(booking.artist?.name ?: "\u2014", fontSize = 12.sp, color = Color(0xFF8A7B6B))
                    }
                    booking.user?.let { user ->
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.AccountCircle, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color(0xFF8A7B6B))
                            Spacer(Modifier.width(4.dp))
                            Text(user.name ?: user.phone ?: user.email ?: "\u2014", fontSize = 12.sp, color = Color(0xFF8A7B6B))
                        }
                    }
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text("${booking.startTime} - ${booking.endTime}", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Color(0xFF8B5E3C))
                    booking.finalPrice?.let {
                        Text("\u20B9${it.toInt()}", fontSize = 14.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }

            // Action buttons
            if (actionButtons.isNotEmpty()) {
                Spacer(Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    actionButtons.forEach { action ->
                        Text(
                            action.label,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = if (action.destructive) Color(0xFFE53935) else Color(0xFF4CAF50),
                            modifier = Modifier
                                .background(
                                    if (action.destructive) Color(0xFFE53935).copy(alpha = 0.1f) else Color(0xFF4CAF50).copy(alpha = 0.1f),
                                    RoundedCornerShape(6.dp)
                                )
                                .clickable { onStatusChange(action.status) }
                                .padding(horizontal = 10.dp, vertical = 6.dp)
                        )
                    }
                }
            }
        }
    }
}
