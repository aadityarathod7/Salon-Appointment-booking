package com.salon.booking.ui.admin

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
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
import com.salon.booking.domain.model.Artist

@Composable
fun AdminArtistsScreen(viewModel: AdminViewModel) {
    val artists by viewModel.artists.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadArtists() }

    Column(
        modifier = Modifier.fillMaxSize().background(Color(0xFFF8F5F2))
    ) {
        Text("Artists", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Color(0xFF2D1B14), modifier = Modifier.padding(16.dp))

        if (artists.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("No artists found", color = Color(0xFF8A7B6B))
            }
        } else {
            LazyColumn(
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(artists) { artist ->
                    var showDialog by remember { mutableStateOf(false) }

                    Card(
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(2.dp)
                    ) {
                        Column(modifier = Modifier.padding(14.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(48.dp)
                                        .clip(CircleShape)
                                        .background(Color(0xFFEDE0D4)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        artist.name.take(1),
                                        fontSize = 20.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color(0xFF8B5E3C)
                                    )
                                }
                                Spacer(Modifier.width(12.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(artist.name, fontWeight = FontWeight.SemiBold)
                                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                        Text("${artist.experienceYears} yrs", fontSize = 12.sp, color = Color(0xFF8A7B6B))
                                        Text("\u2605 ${String.format("%.1f", artist.avgRating)}", fontSize = 12.sp, color = Color(0xFF8A7B6B))
                                        Text("${artist.totalReviews} reviews", fontSize = 12.sp, color = Color(0xFF8A7B6B))
                                    }
                                }
                                Box(
                                    Modifier.size(10.dp).clip(CircleShape)
                                        .background(if (artist.isActive) Color(0xFF4CAF50) else Color(0xFFE53935))
                                )
                            }

                            Spacer(Modifier.height(8.dp))

                            artist.phone?.let {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Filled.Phone, contentDescription = null, modifier = Modifier.size(14.dp), tint = Color(0xFF8A7B6B))
                                    Spacer(Modifier.width(4.dp))
                                    Text(it, fontSize = 12.sp, color = Color(0xFF8A7B6B))
                                }
                            }

                            Spacer(Modifier.height(8.dp))
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                                TextButton(onClick = { showDialog = true }, colors = ButtonDefaults.textButtonColors(contentColor = Color(0xFFE53935))) {
                                    Text("Deactivate", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                                }
                            }
                        }
                    }

                    if (showDialog) {
                        AlertDialog(
                            onDismissRequest = { showDialog = false },
                            title = { Text("Deactivate ${artist.name}?") },
                            confirmButton = {
                                TextButton(onClick = { viewModel.deactivateArtist(artist.id); showDialog = false }) { Text("Deactivate", color = Color(0xFFE53935)) }
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
