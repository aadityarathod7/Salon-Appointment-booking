package com.salon.booking.ui.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.Alignment
import androidx.compose.ui.graphics.Color
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.salon.booking.ui.admin.*
import com.salon.booking.ui.appointments.AppointmentListScreen
import com.salon.booking.ui.auth.AuthViewModel
import com.salon.booking.ui.auth.LoginScreen
import com.salon.booking.ui.booking.BookingFlowScreen
import com.salon.booking.ui.home.HomeScreen
import com.salon.booking.ui.notifications.NotificationScreen
import com.salon.booking.ui.profile.ProfileScreen
import com.salon.booking.ui.services.ServiceListScreen

sealed class Screen(val route: String, val title: String, val icon: @Composable () -> Unit) {
    data object Home : Screen("home", "Home", { Icon(Icons.Filled.Home, contentDescription = "Home") })
    data object Services : Screen("services", "Services", { Icon(Icons.Filled.ContentCut, contentDescription = "Services") })
    data object Bookings : Screen("bookings", "Bookings", { Icon(Icons.Filled.CalendarMonth, contentDescription = "Bookings") })
    data object Notifications : Screen("notifications", "Alerts", { Icon(Icons.Filled.Notifications, contentDescription = "Alerts") })
    data object Profile : Screen("profile", "Profile", { Icon(Icons.Filled.Person, contentDescription = "Profile") })
    data object Login : Screen("login", "Login", {})
    data object BookingFlow : Screen("booking_flow", "Book", {})

    // Admin screens
    data object AdminDashboard : Screen("admin_dashboard", "Dashboard", { Icon(Icons.Filled.Dashboard, contentDescription = "Dashboard") })
    data object AdminAppointments : Screen("admin_appointments", "Bookings", { Icon(Icons.Filled.CalendarMonth, contentDescription = "Bookings") })
    data object AdminArtists : Screen("admin_artists", "Artists", { Icon(Icons.Filled.People, contentDescription = "Artists") })
    data object AdminServices : Screen("admin_services", "Services", { Icon(Icons.Filled.ContentCut, contentDescription = "Services") })
    data object AdminReports : Screen("admin_reports", "Reports", { Icon(Icons.Filled.BarChart, contentDescription = "Reports") })
}

val bottomNavItems = listOf(Screen.Home, Screen.Services, Screen.Bookings, Screen.Notifications, Screen.Profile)

val adminNavItems = listOf(
    Screen.AdminDashboard,
    Screen.AdminAppointments,
    Screen.AdminArtists,
    Screen.AdminServices,
    Screen.AdminReports
)

@Composable
fun SalonNavGraph() {
    val authViewModel: AuthViewModel = hiltViewModel()
    val isAuthenticated by authViewModel.isAuthenticated.collectAsState()
    val currentUser by authViewModel.currentUser.collectAsState()
    val navController = rememberNavController()

    val isAdmin = currentUser?.role == "ADMIN"
    val isProfileLoading = isAuthenticated && currentUser == null

    // Fetch profile on login so we know the role
    LaunchedEffect(isAuthenticated) {
        if (isAuthenticated && currentUser == null) {
            authViewModel.loadProfile()
        }
    }

    if (!isAuthenticated) {
        LoginScreen(authViewModel = authViewModel)
    } else if (isProfileLoading) {
        // Show loading while determining user role
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator(color = Color(0xFF8B5E3C))
        }
    } else if (isAdmin) {
        // Admin layout
        val adminViewModel: AdminViewModel = hiltViewModel()

        Scaffold(
            bottomBar = {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentRoute = navBackStackEntry?.destination?.route

                NavigationBar {
                    adminNavItems.forEach { screen ->
                        NavigationBarItem(
                            icon = screen.icon,
                            label = { Text(screen.title) },
                            selected = currentRoute == screen.route,
                            onClick = {
                                navController.navigate(screen.route) {
                                    popUpTo(navController.graph.startDestinationId) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        ) { padding ->
            NavHost(
                navController = navController,
                startDestination = Screen.AdminDashboard.route,
                modifier = Modifier.padding(padding)
            ) {
                composable(Screen.AdminDashboard.route) {
                    AdminDashboardScreen(viewModel = adminViewModel)
                }
                composable(Screen.AdminAppointments.route) {
                    AdminAppointmentsScreen(viewModel = adminViewModel)
                }
                composable(Screen.AdminArtists.route) {
                    AdminArtistsScreen(viewModel = adminViewModel)
                }
                composable(Screen.AdminServices.route) {
                    AdminServicesScreen(viewModel = adminViewModel)
                }
                composable(Screen.AdminReports.route) {
                    AdminReportsScreen(viewModel = adminViewModel)
                }
            }
        }
    } else {
        // Customer layout
        Scaffold(
            bottomBar = {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentRoute = navBackStackEntry?.destination?.route

                if (currentRoute != Screen.BookingFlow.route) {
                    NavigationBar {
                        bottomNavItems.forEach { screen ->
                            NavigationBarItem(
                                icon = screen.icon,
                                label = { Text(screen.title) },
                                selected = currentRoute == screen.route,
                                onClick = {
                                    navController.navigate(screen.route) {
                                        popUpTo(navController.graph.startDestinationId) { saveState = true }
                                        launchSingleTop = true
                                        restoreState = true
                                    }
                                }
                            )
                        }
                    }
                }
            }
        ) { padding ->
            NavHost(
                navController = navController,
                startDestination = Screen.Home.route,
                modifier = Modifier.padding(padding)
            ) {
                composable(Screen.Home.route) {
                    HomeScreen(onBookClick = { navController.navigate(Screen.BookingFlow.route) })
                }
                composable(Screen.Services.route) {
                    ServiceListScreen(onBookClick = { navController.navigate(Screen.BookingFlow.route) })
                }
                composable(Screen.Bookings.route) {
                    AppointmentListScreen()
                }
                composable(Screen.Notifications.route) {
                    NotificationScreen()
                }
                composable(Screen.Profile.route) {
                    ProfileScreen(
                        onLogout = { authViewModel.logout() },
                        onNavigateToBookings = {
                            navController.navigate(Screen.Bookings.route) {
                                popUpTo(navController.graph.startDestinationId) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        onNavigateToNotifications = {
                            navController.navigate(Screen.Notifications.route) {
                                popUpTo(navController.graph.startDestinationId) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
                composable(Screen.BookingFlow.route) {
                    BookingFlowScreen(onDone = { navController.popBackStack() })
                }
            }
        }
    }
}
