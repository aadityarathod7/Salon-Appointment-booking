package com.salon.booking.ui.appointments

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.salon.booking.data.repository.SalonRepository
import com.salon.booking.domain.model.Appointment
import com.salon.booking.domain.model.TimeSlot
import com.salon.booking.ui.reviews.ReviewViewModel
import com.salon.booking.ui.reviews.WriteReviewScreen
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import javax.inject.Inject

@HiltViewModel
class AppointmentViewModel @Inject constructor(
    private val repository: SalonRepository
) : ViewModel() {

    private val _appointments = MutableStateFlow<List<Appointment>>(emptyList())
    val appointments: StateFlow<List<Appointment>> = _appointments

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage

    private val _selectedTab = MutableStateFlow("UPCOMING")
    val selectedTab: StateFlow<String> = _selectedTab

    // Reschedule state
    private val _rescheduleSlots = MutableStateFlow<List<TimeSlot>>(emptyList())
    val rescheduleSlots: StateFlow<List<TimeSlot>> = _rescheduleSlots

    private val _rescheduleSlotsLoading = MutableStateFlow(false)
    val rescheduleSlotsLoading: StateFlow<Boolean> = _rescheduleSlotsLoading

    fun setTab(tab: String) {
        _selectedTab.value = tab
        loadAppointments()
    }

    fun loadAppointments() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            repository.getAppointments(_selectedTab.value).fold(
                onSuccess = { _appointments.value = it.content },
                onFailure = { _errorMessage.value = it.message ?: "Failed to load appointments" }
            )
            _isLoading.value = false
        }
    }

    fun cancelAppointment(id: String) {
        viewModelScope.launch {
            repository.cancelAppointment(id).fold(
                onSuccess = { loadAppointments() },
                onFailure = { _errorMessage.value = it.message ?: "Failed to cancel" }
            )
        }
    }

    fun loadRescheduleSlots(artistId: String, serviceId: String, date: LocalDate) {
        val dateStr = date.format(DateTimeFormatter.ISO_LOCAL_DATE)
        viewModelScope.launch {
            _rescheduleSlotsLoading.value = true
            _rescheduleSlots.value = emptyList()
            repository.getAvailableSlots(artistId, serviceId, dateStr).fold(
                onSuccess = { _rescheduleSlots.value = it.slots },
                onFailure = { _errorMessage.value = it.message ?: "Failed to load slots" }
            )
            _rescheduleSlotsLoading.value = false
        }
    }

    fun rescheduleAppointment(id: String, date: String, startTime: String) {
        viewModelScope.launch {
            repository.rescheduleAppointment(id, date, startTime).fold(
                onSuccess = { loadAppointments() },
                onFailure = { _errorMessage.value = it.message ?: "Failed to reschedule" }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppointmentListScreen(
    onBookAgain: () -> Unit = {},
    viewModel: AppointmentViewModel = hiltViewModel()
) {
    val appointments by viewModel.appointments.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val selectedTab by viewModel.selectedTab.collectAsState()

    var reviewAppointment by remember { mutableStateOf<Appointment?>(null) }
    var rescheduleAppointment by remember { mutableStateOf<Appointment?>(null) }

    LaunchedEffect(Unit) { viewModel.loadAppointments() }

    Scaffold(
        topBar = { TopAppBar(title = { Text("My Bookings") }) }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            // Tab selector
            TabRow(selectedTabIndex = if (selectedTab == "UPCOMING") 0 else 1) {
                Tab(selected = selectedTab == "UPCOMING", onClick = { viewModel.setTab("UPCOMING") }) {
                    Text("Upcoming", modifier = Modifier.padding(16.dp))
                }
                Tab(selected = selectedTab == "PAST", onClick = { viewModel.setTab("PAST") }) {
                    Text("Past", modifier = Modifier.padding(16.dp))
                }
            }

            if (isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            } else if (appointments.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("No ${selectedTab.lowercase()} appointments")
                }
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(appointments) { apt ->
                        AppointmentCard(
                            appointment = apt,
                            onCancel = { viewModel.cancelAppointment(apt.id) },
                            onReview = { reviewAppointment = apt },
                            onReschedule = { rescheduleAppointment = apt },
                            onBookAgain = onBookAgain
                        )
                    }
                }
            }
        }
    }

    // Review bottom sheet
    reviewAppointment?.let { apt ->
        val reviewViewModel: ReviewViewModel = hiltViewModel()
        ModalBottomSheet(onDismissRequest = { reviewAppointment = null }) {
            WriteReviewScreen(
                appointmentId = apt.id,
                onDismiss = {
                    reviewAppointment = null
                    viewModel.loadAppointments()
                },
                viewModel = reviewViewModel
            )
        }
    }

    // Reschedule bottom sheet
    rescheduleAppointment?.let { apt ->
        RescheduleBottomSheet(
            appointment = apt,
            viewModel = viewModel,
            onDismiss = { rescheduleAppointment = null }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RescheduleBottomSheet(
    appointment: Appointment,
    viewModel: AppointmentViewModel,
    onDismiss: () -> Unit
) {
    var selectedDate by remember { mutableStateOf(LocalDate.now().plusDays(1)) }
    var selectedSlot by remember { mutableStateOf<TimeSlot?>(null) }
    val slots by viewModel.rescheduleSlots.collectAsState()
    val slotsLoading by viewModel.rescheduleSlotsLoading.collectAsState()

    LaunchedEffect(selectedDate) {
        viewModel.loadRescheduleSlots(
            artistId = appointment.artist.id,
            serviceId = appointment.service.id,
            date = selectedDate
        )
        selectedSlot = null
    }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp)
        ) {
            Text(
                "Reschedule Appointment",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                "Select Date",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))

            // Date selection (next 14 days)
            val dates = (1L..14L).map { LocalDate.now().plusDays(it) }
            LazyVerticalGrid(
                columns = GridCells.Fixed(4),
                modifier = Modifier.heightIn(max = 200.dp),
                contentPadding = PaddingValues(4.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                items(dates) { date ->
                    val isSelected = date == selectedDate
                    OutlinedCard(
                        modifier = Modifier.clickable { selectedDate = date },
                        border = BorderStroke(
                            if (isSelected) 2.dp else 1.dp,
                            if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
                        ),
                        colors = CardDefaults.outlinedCardColors(
                            containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(8.dp).fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(date.dayOfWeek.name.take(3), style = MaterialTheme.typography.labelSmall)
                            Text("${date.dayOfMonth}", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                "Select Time Slot",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))

            if (slotsLoading) {
                Box(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(modifier = Modifier.size(32.dp))
                }
            } else if (slots.isEmpty()) {
                Text(
                    "No slots available for this date",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(vertical = 8.dp)
                )
            } else {
                LazyVerticalGrid(
                    columns = GridCells.Fixed(3),
                    modifier = Modifier.heightIn(max = 160.dp),
                    contentPadding = PaddingValues(4.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    items(slots.filter { it.available }) { slot ->
                        val isSelected = selectedSlot?.startTime == slot.startTime
                        OutlinedCard(
                            modifier = Modifier.clickable { selectedSlot = slot },
                            border = BorderStroke(
                                if (isSelected) 2.dp else 1.dp,
                                if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
                            ),
                            colors = CardDefaults.outlinedCardColors(
                                containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface
                            )
                        ) {
                            Box(
                                modifier = Modifier.padding(10.dp).fillMaxWidth(),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    slot.startTime,
                                    style = MaterialTheme.typography.bodySmall,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                                )
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = {
                    selectedSlot?.let { slot ->
                        val dateStr = selectedDate.format(DateTimeFormatter.ISO_LOCAL_DATE)
                        viewModel.rescheduleAppointment(appointment.id, dateStr, slot.startTime)
                        onDismiss()
                    }
                },
                modifier = Modifier.fillMaxWidth().height(50.dp),
                enabled = selectedSlot != null
            ) {
                Text("Confirm Reschedule")
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
fun AppointmentCard(
    appointment: Appointment,
    onCancel: () -> Unit,
    onReview: () -> Unit = {},
    onReschedule: () -> Unit = {},
    onBookAgain: () -> Unit = {}
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row {
                Text(appointment.bookingRef, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary)
                Spacer(modifier = Modifier.weight(1f))
                StatusChip(appointment.status)
            }

            Row {
                Column(modifier = Modifier.weight(1f)) {
                    Text(appointment.service.name, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                    Text("with ${appointment.artist.name}", style = MaterialTheme.typography.bodySmall)
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(appointment.appointmentDate, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold)
                    Text("${appointment.startTime} - ${appointment.endTime}", style = MaterialTheme.typography.bodySmall)
                }
            }

            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("₹${appointment.finalPrice.toInt()}", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
                Spacer(modifier = Modifier.weight(1f))

                // Action buttons based on status
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    when (appointment.status) {
                        "CONFIRMED", "PENDING" -> {
                            OutlinedButton(
                                onClick = onReschedule,
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                            ) {
                                Text("Reschedule", style = MaterialTheme.typography.labelSmall)
                            }
                            OutlinedButton(
                                onClick = onCancel,
                                colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                            ) {
                                Text("Cancel", style = MaterialTheme.typography.labelSmall)
                            }
                        }
                        "COMPLETED" -> {
                            OutlinedButton(
                                onClick = onReview,
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                            ) {
                                Icon(Icons.Filled.Star, contentDescription = null, modifier = Modifier.size(14.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Review", style = MaterialTheme.typography.labelSmall)
                            }
                            OutlinedButton(
                                onClick = onBookAgain,
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                            ) {
                                Text("Book Again", style = MaterialTheme.typography.labelSmall)
                            }
                        }
                        "CANCELLED" -> {
                            OutlinedButton(
                                onClick = onBookAgain,
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                            ) {
                                Text("Book Again", style = MaterialTheme.typography.labelSmall)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun StatusChip(status: String) {
    val color = when (status) {
        "CONFIRMED" -> Color(0xFF4DB078)
        "PENDING" -> Color(0xFFE5AD40)
        "IN_PROGRESS" -> Color(0xFF5B8DEF)
        "COMPLETED" -> Color(0xFFB85C6B)
        "CANCELLED" -> Color(0xFFD94D4D)
        else -> Color.Gray
    }
    Surface(
        shape = MaterialTheme.shapes.small,
        color = color.copy(alpha = 0.1f)
    ) {
        Text(
            status,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            style = MaterialTheme.typography.labelSmall,
            color = color,
            fontWeight = FontWeight.Bold
        )
    }
}
