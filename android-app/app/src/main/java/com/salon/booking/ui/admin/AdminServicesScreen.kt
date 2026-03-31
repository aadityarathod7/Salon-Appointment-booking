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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.salon.booking.domain.model.SalonService

@Composable
fun AdminServicesScreen(viewModel: AdminViewModel) {
    val services by viewModel.services.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadServices() }

    Column(
        modifier = Modifier.fillMaxSize().background(Color(0xFFF8F5F2))
    ) {
        Text("Services", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Color(0xFF2D1B14), modifier = Modifier.padding(16.dp))

        if (services.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("No services found", color = Color(0xFF8A7B6B))
            }
        } else {
            LazyColumn(
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(services) { service ->
                    var showDialog by remember { mutableStateOf(false) }

                    Card(
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(2.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier.size(50.dp).clip(RoundedCornerShape(12.dp)).background(Color(0xFFEDE0D4)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Filled.ContentCut, contentDescription = null, tint = Color(0xFF8B5E3C))
                            }
                            Spacer(Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(service.name, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Text("${service.durationMinutes}m", fontSize = 12.sp, color = Color(0xFF8A7B6B))
                                    service.category?.let {
                                        Text(it, fontSize = 12.sp, color = Color(0xFF8A7B6B))
                                    }
                                }
                            }
                            Column(horizontalAlignment = Alignment.End) {
                                Text("\u20B9${service.price.toInt()}", fontWeight = FontWeight.Bold, color = Color(0xFF8B5E3C))
                                IconButton(onClick = { showDialog = true }, modifier = Modifier.size(24.dp)) {
                                    Icon(Icons.Filled.Delete, contentDescription = "Delete", tint = Color(0xFFE53935), modifier = Modifier.size(16.dp))
                                }
                            }
                        }
                    }

                    if (showDialog) {
                        AlertDialog(
                            onDismissRequest = { showDialog = false },
                            title = { Text("Deactivate ${service.name}?") },
                            confirmButton = {
                                TextButton(onClick = { viewModel.deactivateService(service.id); showDialog = false }) { Text("Deactivate", color = Color(0xFFE53935)) }
                            },
                            dismissButton = {
                                TextButton(onClick = { showDialog = false }) { Text("Cancel") }
                            }
                        )
                    }
                }
            }
        }
    }
}
