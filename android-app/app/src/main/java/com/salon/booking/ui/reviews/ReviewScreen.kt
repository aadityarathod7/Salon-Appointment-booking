package com.salon.booking.ui.reviews

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.salon.booking.data.repository.SalonRepository
import com.salon.booking.domain.model.Review
import com.salon.booking.ui.theme.Brand
import com.salon.booking.ui.theme.BrandLight
import com.salon.booking.ui.theme.Success
import com.salon.booking.ui.theme.Warning
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ReviewViewModel @Inject constructor(
    private val repository: SalonRepository
) : ViewModel() {

    private val _reviews = MutableStateFlow<List<Review>>(emptyList())
    val reviews: StateFlow<List<Review>> = _reviews

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val _submitSuccess = MutableStateFlow(false)
    val submitSuccess: StateFlow<Boolean> = _submitSuccess

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage

    fun loadReviews(artistId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            repository.getArtistReviews(artistId).fold(
                onSuccess = { _reviews.value = it.content },
                onFailure = { _errorMessage.value = it.message ?: "Failed to load reviews" }
            )
            _isLoading.value = false
        }
    }

    fun submitReview(appointmentId: String, rating: Int, comment: String?) {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            repository.createReview(appointmentId, rating, comment).fold(
                onSuccess = { _submitSuccess.value = true },
                onFailure = { _errorMessage.value = it.message ?: "Failed to submit review" }
            )
            _isLoading.value = false
        }
    }

    fun resetSubmitSuccess() {
        _submitSuccess.value = false
    }
}

@Composable
fun WriteReviewScreen(
    appointmentId: String,
    onDismiss: () -> Unit,
    viewModel: ReviewViewModel
) {
    var rating by remember { mutableIntStateOf(0) }
    var comment by remember { mutableStateOf("") }
    val isLoading by viewModel.isLoading.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()
    val submitSuccess by viewModel.submitSuccess.collectAsState()

    LaunchedEffect(submitSuccess) {
        if (submitSuccess) {
            viewModel.resetSubmitSuccess()
            onDismiss()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            "Write a Review",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(20.dp))

        // Star rating
        Text(
            "How was your experience?",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(12.dp))

        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            (1..5).forEach { star ->
                Icon(
                    imageVector = if (star <= rating) Icons.Filled.Star else Icons.Filled.StarBorder,
                    contentDescription = "Star $star",
                    modifier = Modifier
                        .size(40.dp)
                        .clickable { rating = star },
                    tint = if (star <= rating) Warning else MaterialTheme.colorScheme.outline
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // Comment
        OutlinedTextField(
            value = comment,
            onValueChange = { comment = it },
            label = { Text("Your comment (optional)") },
            modifier = Modifier.fillMaxWidth(),
            minLines = 3,
            maxLines = 5
        )

        errorMessage?.let {
            Spacer(modifier = Modifier.height(8.dp))
            Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
        }

        Spacer(modifier = Modifier.height(24.dp))

        Button(
            onClick = {
                viewModel.submitReview(
                    appointmentId = appointmentId,
                    rating = rating,
                    comment = comment.ifBlank { null }
                )
            },
            modifier = Modifier.fillMaxWidth().height(50.dp),
            enabled = rating > 0 && !isLoading
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(24.dp),
                    color = MaterialTheme.colorScheme.onPrimary
                )
            } else {
                Text("Submit Review")
            }
        }

        Spacer(modifier = Modifier.height(16.dp))
    }
}

@Composable
fun ReviewCard(review: Review) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Avatar with initial
                val initial = review.userName.firstOrNull()?.uppercase() ?: "?"
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(BrandLight),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        initial,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = Brand
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        review.userName,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )
                    Row {
                        (1..5).forEach { star ->
                            Icon(
                                imageVector = if (star <= review.rating) Icons.Filled.Star else Icons.Filled.StarBorder,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp),
                                tint = if (star <= review.rating) Warning else MaterialTheme.colorScheme.outline
                            )
                        }
                    }
                }

                review.createdAt?.let { date ->
                    Text(
                        date.take(10),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            review.comment?.let { comment ->
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    comment,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }

            // Service name
            if (review.serviceName.isNotBlank()) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    "Service: ${review.serviceName}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            // Admin reply
            review.adminReply?.let { reply ->
                Spacer(modifier = Modifier.height(8.dp))
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = MaterialTheme.shapes.small,
                    color = MaterialTheme.colorScheme.surfaceVariant
                ) {
                    Column(modifier = Modifier.padding(12.dp)) {
                        Text(
                            "Salon Reply",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = Brand
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            reply,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ReviewsSection(
    artistId: String,
    viewModel: ReviewViewModel
) {
    val reviews by viewModel.reviews.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    LaunchedEffect(artistId) { viewModel.loadReviews(artistId) }

    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            "Reviews",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )

        if (isLoading) {
            Box(
                modifier = Modifier.fillMaxWidth().padding(24.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else if (reviews.isEmpty()) {
            Text(
                "No reviews yet",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                textAlign = TextAlign.Center
            )
        } else {
            Column(
                modifier = Modifier.padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                reviews.forEach { review ->
                    ReviewCard(review)
                }
            }
        }
    }
}
