package com.salon.booking.ui.admin

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.salon.booking.data.remote.api.SalonApi
import com.salon.booking.domain.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject

@HiltViewModel
class AdminViewModel @Inject constructor(
    private val api: SalonApi
) : ViewModel() {

    private val _dashboard = MutableStateFlow<AdminDashboard?>(null)
    val dashboard: StateFlow<AdminDashboard?> = _dashboard

    private val _appointments = MutableStateFlow<List<AdminBooking>>(emptyList())
    val appointments: StateFlow<List<AdminBooking>> = _appointments

    private val _artists = MutableStateFlow<List<Artist>>(emptyList())
    val artists: StateFlow<List<Artist>> = _artists

    private val _services = MutableStateFlow<List<SalonService>>(emptyList())
    val services: StateFlow<List<SalonService>> = _services

    private val _revenueReport = MutableStateFlow<RevenueReport?>(null)
    val revenueReport: StateFlow<RevenueReport?> = _revenueReport

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error

    fun loadDashboard() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val response = api.getAdminDashboard()
                _dashboard.value = response.data
            } catch (e: Exception) {
                _error.value = e.message
            }
            _isLoading.value = false
        }
    }

    fun loadAppointments(date: String? = null, status: String? = null) {
        viewModelScope.launch {
            try {
                val response = api.getAdminAppointments(date = date, status = status)
                _appointments.value = response.data?.content ?: emptyList()
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    fun updateStatus(id: String, status: String) {
        viewModelScope.launch {
            try {
                api.updateAppointmentStatus(id, StatusUpdateRequest(status))
                loadDashboard()
                val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                loadAppointments(date = fmt.format(Date()))
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    fun loadArtists() {
        viewModelScope.launch {
            try {
                val response = api.getAdminArtists()
                _artists.value = response.data ?: emptyList()
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    fun loadServices() {
        viewModelScope.launch {
            try {
                val response = api.getAdminServices()
                _services.value = response.data ?: emptyList()
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    fun deactivateArtist(id: String) {
        viewModelScope.launch {
            try {
                api.deactivateArtist(id)
                loadArtists()
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    fun deactivateService(id: String) {
        viewModelScope.launch {
            try {
                api.deactivateService(id)
                loadServices()
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    fun loadRevenueReport(days: Int = 30) {
        viewModelScope.launch {
            try {
                val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                val end = fmt.format(Date())
                val cal = Calendar.getInstance()
                cal.add(Calendar.DAY_OF_YEAR, -days)
                val start = fmt.format(cal.time)
                val response = api.getRevenueReport(startDate = start, endDate = end)
                _revenueReport.value = response.data
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }
}
