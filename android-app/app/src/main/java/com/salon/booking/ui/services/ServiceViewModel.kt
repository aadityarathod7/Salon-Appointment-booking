package com.salon.booking.ui.services

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.salon.booking.data.repository.SalonRepository
import com.salon.booking.domain.model.SalonService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ServiceViewModel @Inject constructor(
    private val repository: SalonRepository
) : ViewModel() {

    private val _services = MutableStateFlow<List<SalonService>>(emptyList())
    val services: StateFlow<List<SalonService>> = _services

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    fun loadServices(category: String? = null) {
        viewModelScope.launch {
            _isLoading.value = true
            repository.getServices(category).onSuccess { _services.value = it }
            _isLoading.value = false
        }
    }
}
