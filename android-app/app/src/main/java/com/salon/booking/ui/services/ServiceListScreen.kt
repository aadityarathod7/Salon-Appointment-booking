package com.salon.booking.ui.services

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ServiceListScreen(
    onBookClick: () -> Unit = {},
    viewModel: ServiceViewModel = hiltViewModel()
) {
    val services by viewModel.services.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    var selectedService by remember { mutableStateOf<com.salon.booking.domain.model.SalonService?>(null) }

    LaunchedEffect(Unit) { viewModel.loadServices() }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Services") }) }
    ) { padding ->
        if (isLoading) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(services) { service ->
                    Card(
                        modifier = Modifier.fillMaxWidth().clickable { selectedService = service },
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            com.salon.booking.ui.components.ServiceImage(
                                url = service.imageUrl,
                                width = 56.dp,
                                height = 56.dp,
                                cornerRadius = 12.dp
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(service.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                                Text("${service.durationMinutes} min", style = MaterialTheme.typography.bodySmall)
                                service.description?.let {
                                    Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 2)
                                }
                            }
                            Text("₹${service.price.toInt()}", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                        }
                    }
                }
            }
        }
    }

    // Service detail bottom sheet
    selectedService?.let { service ->
        ModalBottomSheet(onDismissRequest = { selectedService = null }) {
            Column(modifier = Modifier.padding(24.dp)) {
                Text(service.name, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(8.dp))
                Row {
                    Text("${service.durationMinutes} min", style = MaterialTheme.typography.bodyMedium)
                    Spacer(Modifier.weight(1f))
                    Text("₹${service.price.toInt()}", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                }
                service.description?.let {
                    Spacer(Modifier.height(12.dp))
                    Text(it, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Spacer(Modifier.height(24.dp))
                Button(
                    onClick = {
                        selectedService = null
                        onBookClick()
                    },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Book Now")
                }
                Spacer(Modifier.height(16.dp))
            }
        }
    }
}
