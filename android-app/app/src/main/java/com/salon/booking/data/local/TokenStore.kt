package com.salon.booking.data.local

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore by preferencesDataStore(name = "auth_prefs")

@Singleton
class TokenStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private val ACCESS_TOKEN_KEY = stringPreferencesKey("access_token")
        private val REFRESH_TOKEN_KEY = stringPreferencesKey("refresh_token")
    }

    // In-memory cache to avoid blocking the main thread
    @Volatile
    private var cachedAccessToken: String? = null

    @Volatile
    private var cachedRefreshToken: String? = null

    @Volatile
    private var cacheLoaded = false

    val accessToken: String?
        get() {
            if (!cacheLoaded) loadCacheSync()
            return cachedAccessToken
        }

    val refreshToken: String?
        get() {
            if (!cacheLoaded) loadCacheSync()
            return cachedRefreshToken
        }

    private fun loadCacheSync() {
        // Only blocks once at app startup, then uses cache
        runBlocking {
            cachedAccessToken = context.dataStore.data.map { it[ACCESS_TOKEN_KEY] }.first()
            cachedRefreshToken = context.dataStore.data.map { it[REFRESH_TOKEN_KEY] }.first()
            cacheLoaded = true
        }
    }

    suspend fun saveTokens(accessToken: String, refreshToken: String) {
        context.dataStore.edit { prefs ->
            prefs[ACCESS_TOKEN_KEY] = accessToken
            prefs[REFRESH_TOKEN_KEY] = refreshToken
        }
        cachedAccessToken = accessToken
        cachedRefreshToken = refreshToken
        cacheLoaded = true
    }

    suspend fun clearTokens() {
        context.dataStore.edit { it.clear() }
        cachedAccessToken = null
        cachedRefreshToken = null
        cacheLoaded = true
    }

    fun hasToken(): Boolean = accessToken != null
}
