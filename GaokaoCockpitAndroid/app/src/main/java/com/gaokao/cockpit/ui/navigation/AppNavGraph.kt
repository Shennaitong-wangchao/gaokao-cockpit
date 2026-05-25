package com.gaokao.cockpit.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Message
import androidx.compose.material.icons.filled.AutoGraph
import androidx.compose.material.icons.filled.BrightnessHigh
import androidx.compose.material.icons.filled.Checklist
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavController
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import com.gaokao.cockpit.ui.backup.BackupImportScreen
import com.gaokao.cockpit.ui.focus.FocusSessionScreen
import com.gaokao.cockpit.ui.mistakes.MistakeSurgeryScreen
import com.gaokao.cockpit.ui.prompts.PromptLibraryScreen
import com.gaokao.cockpit.ui.prompts.PromptTemplateDetailScreen
import com.gaokao.cockpit.ui.resources.ResourceLibraryScreen
import com.gaokao.cockpit.ui.reviews.ReviewScreen
import com.gaokao.cockpit.ui.tasks.TaskListScreen
import com.gaokao.cockpit.ui.today.TodayCockpitScreen

sealed class Screen(val route: String, val title: String, val icon: ImageVector) {
    data object Today : Screen("today", "今日", Icons.Default.BrightnessHigh)
    data object Tasks : Screen("tasks", "任务", Icons.Default.Checklist)
    data object Mistakes : Screen("mistakes", "错题", Icons.Default.ErrorOutline)
    data object Prompts : Screen("prompts", "提示词", Icons.AutoMirrored.Filled.Message)
    data object Reviews : Screen("reviews", "复盘", Icons.Default.AutoGraph)
}

val bottomNavItems = listOf(Screen.Today, Screen.Tasks, Screen.Mistakes, Screen.Prompts, Screen.Reviews)

@Composable
fun AppNavGraph(
    navController: NavHostController,
    modifier: Modifier = Modifier
) {
    Scaffold(
        bottomBar = { BottomNavBar(navController) },
        modifier = modifier
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Today.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Today.route) {
                TodayCockpitScreen(
                    onViewTasks = {
                        navController.navigate(Screen.Tasks.route) {
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            launchSingleTop = true
                            restoreState = true
                        }
                    }
                )
            }
            composable(Screen.Tasks.route) {
                TaskListScreen(
                    onFocusTask = { taskId ->
                        navController.navigate("focus/$taskId")
                    }
                )
            }
            composable(Screen.Mistakes.route) {
                MistakeSurgeryScreen()
            }
            composable(Screen.Prompts.route) {
                PromptLibraryScreen(
                    onTemplateClick = { templateId ->
                        navController.navigate("prompt_detail/$templateId")
                    }
                )
            }
            composable(Screen.Reviews.route) {
                ReviewScreen(
                    onNavigateToImport = { navController.navigate("backup_import") }
                )
            }
            composable("backup_import") {
                BackupImportScreen(onBack = { navController.popBackStack() })
            }
            composable("focus/{taskId}") { backStackEntry ->
                val taskId = backStackEntry.arguments?.getString("taskId") ?: return@composable
                FocusSessionScreen(
                    taskId = taskId,
                    onBack = { navController.popBackStack() }
                )
            }
            composable("prompt_detail/{templateId}") { backStackEntry ->
                val templateId = backStackEntry.arguments?.getString("templateId") ?: return@composable
                PromptTemplateDetailScreen(
                    templateId = templateId,
                    onBack = { navController.popBackStack() }
                )
            }
            composable("resources") {
                ResourceLibraryScreen()
            }
        }
    }
}

@Composable
fun BottomNavBar(navController: NavController) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    NavigationBar {
        bottomNavItems.forEach { screen ->
            NavigationBarItem(
                icon = { Icon(screen.icon, contentDescription = screen.title) },
                label = { Text(screen.title) },
                selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true,
                onClick = {
                    navController.navigate(screen.route) {
                        popUpTo(navController.graph.findStartDestination().id) {
                            saveState = true
                        }
                        launchSingleTop = true
                        restoreState = true
                    }
                }
            )
        }
    }
}
