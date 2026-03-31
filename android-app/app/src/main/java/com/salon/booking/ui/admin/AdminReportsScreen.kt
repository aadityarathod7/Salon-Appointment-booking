package com.salon.booking.ui.admin

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun AdminReportsScreen(viewModel: AdminViewModel) {
    val report by viewModel.revenueReport.collectAsState()
    var selectedPeriod by remember { mutableIntStateOf(1) }
    val periods = listOf(7 to "7 Days", 30 to "30 Days", 90 to "90 Days")

    LaunchedEffect(selectedPeriod) {
        viewModel.loadRevenueReport(periods[selectedPeriod].first)
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize().background(Color(0xFFF8F5F2)),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Text("Reports", fontSize = 28.sp, fontWeight = FontWeight.Bold, color = Color(0xFF2D1B14))
        }

        // Period selector
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                periods.forEachIndexed { index, (_, label) ->
                    FilterChip(
                        selected = selectedPeriod == index,
                        onClick = { selectedPeriod = index },
                        label = { Text(label, fontSize = 12.sp) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = Color(0xFF8B5E3C),
                            selectedLabelColor = Color.White
                        )
                    )
                }
            }
        }

        report?.let { r ->
            // Total revenue card
            item {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    elevation = CardDefaults.cardElevation(2.dp)
                ) {
                    Column(
                        modifier = Modifier.fillMaxWidth().padding(20.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("Total Revenue", fontSize = 14.sp, color = Color(0xFF8A7B6B))
                        Text("\u20B9${r.totalRevenue.toInt()}", fontSize = 36.sp, fontWeight = FontWeight.Bold, color = Color(0xFF8B5E3C))
                        Text(r.period, fontSize = 12.sp, color = Color(0xFF8A7B6B))
                    }
                }
            }

            // Breakdown
            if (r.breakdown.isNotEmpty()) {
                item {
                    Text("Daily Breakdown", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Color(0xFF2D1B14))
                }

                val maxRevenue = r.breakdown.maxOfOrNull { it.revenue } ?: 1.0

                items(r.breakdown) { item ->
                    Card(
                        shape = RoundedCornerShape(10.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        elevation = CardDefaults.cardElevation(1.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            val parts = item.date.split("-")
                            val dateLabel = if (parts.size == 3) "${parts[2]}/${parts[1]}" else item.date
                            Text(dateLabel, fontSize = 12.sp, color = Color(0xFF8A7B6B), modifier = Modifier.width(50.dp))
                            Spacer(Modifier.width(8.dp))
                            Box(modifier = Modifier.weight(1f).height(20.dp)) {
                                val fraction = (item.revenue / maxRevenue).toFloat().coerceIn(0.01f, 1f)
                                Box(
                                    Modifier.fillMaxHeight()
                                        .fillMaxWidth(fraction)
                                        .clip(RoundedCornerShape(4.dp))
                                        .background(Color(0xFF8B5E3C))
                                )
                            }
                            Spacer(Modifier.width(8.dp))
                            Text("\u20B9${item.revenue.toInt()}", fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.width(55.dp), textAlign = TextAlign.End)
                        }
                    }
                }
            }
        }
    }
}
