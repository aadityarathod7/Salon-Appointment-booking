package com.salon.booking.ui.appointments

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
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
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppointmentListScreen(viewModel: AppointmentViewModel = hiltViewModel()) {
    val appointments by viewModel.appointments.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val selectedTab by viewModel.selectedTab.collectAsState()

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
                        AppointmentCard(apt) { viewModel.cancelAppointment(apt.id) }
                    }
                }
            }
        }
    }
}

@Composable
fun AppointmentCard(appointment: Appointment, onCancel: () -> Unit) {
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

            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("₹${appointment.finalPrice.toInt()}", style = MaterialTheme.typography.titleSmall, color = MaterialTheme.colorScheme.primary)
                Spacer(modifier = Modifier.weight(1f))
                if (appointment.status == "CONFIRMED" || appointment.status == "PENDING") {
                    OutlinedButton(onClick = onCancel, colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error)) {
                        Text("Cancel")
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
