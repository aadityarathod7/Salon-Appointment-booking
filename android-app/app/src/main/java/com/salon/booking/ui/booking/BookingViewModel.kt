package com.salon.booking.ui.booking

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.salon.booking.data.remote.dto.BookingRequest
import com.salon.booking.data.repository.SalonRepository
import com.salon.booking.domain.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import javax.inject.Inject

enum class BookingStep { SELECT_SERVICE, SELECT_ARTIST, SELECT_DATE, SELECT_SLOT, SUMMARY }

@HiltViewModel
class BookingViewModel @Inject constructor(
    private val repository: SalonRepository
) : ViewModel() {

    private val _currentStep = MutableStateFlow(BookingStep.SELECT_SERVICE)
    val currentStep: StateFlow<BookingStep> = _currentStep

    private val _services = MutableStateFlow<List<SalonService>>(emptyList())
    val services: StateFlow<List<SalonService>> = _services

    private val _artists = MutableStateFlow<List<Artist>>(emptyList())
    val artists: StateFlow<List<Artist>> = _artists

    private val _slots = MutableStateFlow<List<TimeSlot>>(emptyList())
    val slots: StateFlow<List<TimeSlot>> = _slots

    private val _selectedService = MutableStateFlow<SalonService?>(null)
    val selectedService: StateFlow<SalonService?> = _selectedService

    private val _selectedArtist = MutableStateFlow<Artist?>(null)
    val selectedArtist: StateFlow<Artist?> = _selectedArtist

    private val _selectedDate = MutableStateFlow(LocalDate.now().plusDays(1))
    val selectedDate: StateFlow<LocalDate> = _selectedDate

    private val _selectedSlot = MutableStateFlow<TimeSlot?>(null)
    val selectedSlot: StateFlow<TimeSlot?> = _selectedSlot

    private val _paymentMethod = MutableStateFlow("PAY_AT_SALON")
    val paymentMethod: StateFlow<String> = _paymentMethod

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage

    private val _bookedAppointment = MutableStateFlow<Appointment?>(null)
    val bookedAppointment: StateFlow<Appointment?> = _bookedAppointment

    fun clearBookedAppointment() {
        _bookedAppointment.value = null
    }

    fun loadServices() {
        viewModelScope.launch {
            repository.getServices().onSuccess { _services.value = it }
        }
    }

    fun selectService(service: SalonService) {
        _selectedService.value = service
        _currentStep.value = BookingStep.SELECT_ARTIST
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            repository.getArtistsForService(service.id).fold(
                onSuccess = { _artists.value = it },
                onFailure = { _errorMessage.value = it.message ?: "Failed to load artists" }
            )
            _isLoading.value = false
        }
    }

    fun selectArtist(artist: Artist) {
        _selectedArtist.value = artist
        _currentStep.value = BookingStep.SELECT_DATE
    }

    fun selectDate(date: LocalDate) {
        _selectedDate.value = date
        _currentStep.value = BookingStep.SELECT_SLOT
        loadSlots()
    }

    fun selectSlot(slot: TimeSlot) {
        _selectedSlot.value = slot
    }

    fun setPaymentMethod(method: String) {
        _paymentMethod.value = method
    }

    fun goToSummary() {
        _currentStep.value = BookingStep.SUMMARY
    }

    fun goBack() {
        _errorMessage.value = null
        val prev = when (_currentStep.value) {
            BookingStep.SELECT_ARTIST -> BookingStep.SELECT_SERVICE
            BookingStep.SELECT_DATE -> BookingStep.SELECT_ARTIST
            BookingStep.SELECT_SLOT -> BookingStep.SELECT_DATE
            BookingStep.SUMMARY -> BookingStep.SELECT_SLOT
            else -> return
        }
        _currentStep.value = prev
    }

    private fun loadSlots() {
        val service = _selectedService.value ?: return
        val artist = _selectedArtist.value ?: return
        val dateStr = _selectedDate.value.format(DateTimeFormatter.ISO_LOCAL_DATE)

        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            repository.getAvailableSlots(artist.id, service.id, dateStr).fold(
                onSuccess = { _slots.value = it.slots },
                onFailure = { _errorMessage.value = it.message ?: "Failed to load slots" }
            )
            _isLoading.value = false
        }
    }

    fun confirmBooking() {
        val service = _selectedService.value ?: return
        val artist = _selectedArtist.value ?: return
        val slot = _selectedSlot.value ?: return
        val dateStr = _selectedDate.value.format(DateTimeFormatter.ISO_LOCAL_DATE)

        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null

            val request = BookingRequest(
                serviceId = service.id,
                artistId = artist.id,
                date = dateStr,
                startTime = slot.startTime,
                paymentMethod = _paymentMethod.value
            )

            repository.createBooking(request).fold(
                onSuccess = { _bookedAppointment.value = it },
                onFailure = { _errorMessage.value = it.message }
            )

            _isLoading.value = false
        }
    }
}
