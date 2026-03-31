package com.salon.booking.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.salon.booking.data.repository.AuthRepository
import com.salon.booking.domain.model.User
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _isAuthenticated = MutableStateFlow(authRepository.isLoggedIn())
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage

    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser

    fun login(emailOrPhone: String, password: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null

            authRepository.login(emailOrPhone, password).fold(
                onSuccess = { auth ->
                    _currentUser.value = auth.user
                    _isAuthenticated.value = true
                },
                onFailure = { e ->
                    _errorMessage.value = e.message
                }
            )

            _isLoading.value = false
        }
    }

    fun register(name: String, email: String?, phone: String?, password: String?) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null

            authRepository.register(name, email, phone, password).fold(
                onSuccess = { auth ->
                    _currentUser.value = auth.user
                    _isAuthenticated.value = true
                },
                onFailure = { e ->
                    _errorMessage.value = e.message
                }
            )

            _isLoading.value = false
        }
    }

    fun verifyOtp(phone: String, otp: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null

            authRepository.verifyOtp(phone, otp).fold(
                onSuccess = { auth ->
                    _currentUser.value = auth.user
                    _isAuthenticated.value = true
                },
                onFailure = { e ->
                    _errorMessage.value = e.message
                }
            )

            _isLoading.value = false
        }
    }

    fun loadProfile() {
        viewModelScope.launch {
            authRepository.getProfile().fold(
                onSuccess = { user -> _currentUser.value = user },
                onFailure = { /* profile load failed, default to customer */ }
            )
        }
    }

    fun logout() {
        viewModelScope.launch {
            authRepository.logout()
            _isAuthenticated.value = false
            _currentUser.value = null
        }
    }
}
