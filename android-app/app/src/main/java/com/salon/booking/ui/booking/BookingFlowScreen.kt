package com.salon.booking.ui.booking

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import java.time.LocalDate

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookingFlowScreen(
    onDone: () -> Unit,
    viewModel: BookingViewModel = hiltViewModel()
) {
    val currentStep by viewModel.currentStep.collectAsState()
    val bookedAppointment by viewModel.bookedAppointment.collectAsState()

    LaunchedEffect(Unit) { viewModel.loadServices() }

    // Show confirmation dialog
    bookedAppointment?.let { apt ->
        AlertDialog(
            onDismissRequest = onDone,
            title = { Text("Booking Confirmed!") },
            text = { Text("Ref: ${apt.bookingRef}\n${apt.appointmentDate} at ${apt.startTime}") },
            confirmButton = { TextButton(onClick = onDone) { Text("Done") } }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(when (currentStep) {
                        BookingStep.SELECT_SERVICE -> "Select Service"
                        BookingStep.SELECT_ARTIST -> "Select Artist"
                        BookingStep.SELECT_DATE -> "Select Date"
                        BookingStep.SELECT_SLOT -> "Select Slot"
                        BookingStep.SUMMARY -> "Confirm Booking"
                    })
                },
                navigationIcon = {
                    if (currentStep != BookingStep.SELECT_SERVICE) {
                        IconButton(onClick = { viewModel.goBack() }) {
                            Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                        }
                    } else {
                        IconButton(onClick = onDone) {
                            Icon(Icons.Filled.Close, contentDescription = "Close")
                        }
                    }
                }
            )
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            // Progress
            val progress = (currentStep.ordinal + 1).toFloat() / BookingStep.entries.size
            LinearProgressIndicator(
                progress = { progress },
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(8.dp))

            when (currentStep) {
                BookingStep.SELECT_SERVICE -> ServiceStepContent(viewModel)
                BookingStep.SELECT_ARTIST -> ArtistStepContent(viewModel)
                BookingStep.SELECT_DATE -> DateStepContent(viewModel)
                BookingStep.SELECT_SLOT -> SlotStepContent(viewModel)
                BookingStep.SUMMARY -> SummaryStepContent(viewModel)
            }
        }
    }
}

@Composable
fun ServiceStepContent(viewModel: BookingViewModel) {
    val services by viewModel.services.collectAsState()
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(services) { service ->
            Card(
                modifier = Modifier.fillMaxWidth().clickable { viewModel.selectService(service) }
            ) {
                Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(service.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                        Text("${service.durationMinutes} min", style = MaterialTheme.typography.bodySmall)
                    }
                    Text("₹${service.price.toInt()}", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                }
            }
        }
    }
}

@Composable
fun ArtistStepContent(viewModel: BookingViewModel) {
    val artists by viewModel.artists.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    if (isLoading) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
    } else {
        LazyColumn(
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(artists) { artist ->
                Card(
                    modifier = Modifier.fillMaxWidth().clickable { viewModel.selectArtist(artist) }
                ) {
                    Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Person, contentDescription = null, modifier = Modifier.size(40.dp), tint = MaterialTheme.colorScheme.primary)
                        Spacer(modifier = Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(artist.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                            Row {
                                Icon(Icons.Filled.Star, contentDescription = null, modifier = Modifier.size(16.dp), tint = MaterialTheme.colorScheme.primary)
                                Text(" ${artist.avgRating} (${artist.totalReviews})", style = MaterialTheme.typography.bodySmall)
                            }
                        }
                        Text("${artist.experienceYears} yrs", style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DateStepContent(viewModel: BookingViewModel) {
    val selectedDate by viewModel.selectedDate.collectAsState()

    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Simple date selection with buttons for next 14 days
        Text("Select a Date", style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(16.dp))

        val dates = (1L..14L).map { LocalDate.now().plusDays(it) }
        LazyVerticalGrid(
            columns = GridCells.Fixed(3),
            contentPadding = PaddingValues(8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(dates) { date ->
                val isSelected = date == selectedDate
                OutlinedCard(
                    modifier = Modifier.clickable { viewModel.selectDate(date) },
                    border = BorderStroke(
                        2.dp,
                        if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
                    ),
                    colors = CardDefaults.outlinedCardColors(
                        containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(12.dp).fillMaxWidth(),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(date.dayOfWeek.name.take(3), style = MaterialTheme.typography.labelSmall)
                        Text("${date.dayOfMonth}", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                        Text(date.month.name.take(3), style = MaterialTheme.typography.labelSmall)
                    }
                }
            }
        }
    }
}

@Composable
fun SlotStepContent(viewModel: BookingViewModel) {
    val slots by viewModel.slots.collectAsState()
    val selectedSlot by viewModel.selectedSlot.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    Column(modifier = Modifier.fillMaxSize()) {
        if (isLoading) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else if (slots.isEmpty()) {
            Box(modifier = Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                Text("No slots available for this date", style = MaterialTheme.typography.bodyLarge)
            }
        } else {
            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                contentPadding = PaddingValues(16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.weight(1f)
            ) {
                items(slots) { slot ->
                    val isSelected = selectedSlot?.startTime == slot.startTime
                    OutlinedCard(
                        modifier = Modifier.clickable(enabled = slot.available) { viewModel.selectSlot(slot) },
                        border = BorderStroke(
                            2.dp,
                            when {
                                !slot.available -> MaterialTheme.colorScheme.outline.copy(alpha = 0.3f)
                                isSelected -> MaterialTheme.colorScheme.primary
                                else -> MaterialTheme.colorScheme.outline
                            }
                        ),
                        colors = CardDefaults.outlinedCardColors(
                            containerColor = when {
                                !slot.available -> MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                                isSelected -> MaterialTheme.colorScheme.primaryContainer
                                else -> MaterialTheme.colorScheme.surface
                            }
                        )
                    ) {
                        Box(
                            modifier = Modifier.padding(12.dp).fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                slot.startTime,
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                                color = if (!slot.available) MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f) else MaterialTheme.colorScheme.onSurface
                            )
                        }
                    }
                }
            }
        }

        // Continue button
        Button(
            onClick = { viewModel.goToSummary() },
            modifier = Modifier.fillMaxWidth().padding(16.dp).height(50.dp),
            enabled = selectedSlot != null
        ) {
            Text("Continue")
        }
    }
}

@Composable
fun SummaryStepContent(viewModel: BookingViewModel) {
    val service by viewModel.selectedService.collectAsState()
    val artist by viewModel.selectedArtist.collectAsState()
    val date by viewModel.selectedDate.collectAsState()
    val slot by viewModel.selectedSlot.collectAsState()
    val paymentMethod by viewModel.paymentMethod.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.errorMessage.collectAsState()

    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                SummaryRow("Service", service?.name ?: "")
                SummaryRow("Artist", artist?.name ?: "")
                SummaryRow("Date", date.toString())
                SummaryRow("Time", "${slot?.startTime ?: ""} - ${slot?.endTime ?: ""}")
                Divider()
                SummaryRow("Price", "₹${service?.price?.toInt() ?: 0}")
            }
        }

        // Payment method
        Text("Payment Method", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf("PAY_AT_SALON" to "At Salon", "UPI" to "UPI", "CARD" to "Card").forEach { (value, label) ->
                FilterChip(
                    selected = paymentMethod == value,
                    onClick = { viewModel.setPaymentMethod(value) },
                    label = { Text(label) }
                )
            }
        }

        error?.let {
            Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
        }

        Spacer(modifier = Modifier.weight(1f))

        Button(
            onClick = { viewModel.confirmBooking() },
            modifier = Modifier.fillMaxWidth().height(50.dp),
            enabled = !isLoading
        ) {
            if (isLoading) CircularProgressIndicator(modifier = Modifier.size(24.dp), color = MaterialTheme.colorScheme.onPrimary)
            else Text("Confirm Booking")
        }
    }
}

@Composable
fun SummaryRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth()) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.weight(1f))
        Text(value, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
    }
}
