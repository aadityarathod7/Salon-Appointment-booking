package com.salon.booking.data.remote.interceptor

import com.salon.booking.data.local.TokenStore
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject

class AuthInterceptor @Inject constructor(
    private val tokenStore: TokenStore
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()

        // Skip auth header for public endpoints
        val path = request.url.encodedPath
        if (path.contains("/auth/") && !path.contains("/logout")) {
            return chain.proceed(request)
        }

        val token = tokenStore.accessToken ?: return chain.proceed(request)

        val authenticatedRequest = request.newBuilder()
            .header("Authorization", "Bearer $token")
            .build()

        return chain.proceed(authenticatedRequest)
    }
}
