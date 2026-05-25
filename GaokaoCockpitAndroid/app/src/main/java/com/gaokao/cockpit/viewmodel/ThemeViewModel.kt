package com.gaokao.cockpit.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gaokao.cockpit.ui.theme.ThemeContext
import com.gaokao.cockpit.ui.theme.ThemeManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject

@HiltViewModel
class ThemeViewModel @Inject constructor(
    themeManager: ThemeManager
) : ViewModel() {

    val currentTheme: StateFlow<ThemeContext> = themeManager.currentTheme
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = ThemeContext.Afternoon
        )

    val isDynamicEnabled: StateFlow<Boolean> = themeManager.isDynamicThemeEnabled
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = true
        )
}
