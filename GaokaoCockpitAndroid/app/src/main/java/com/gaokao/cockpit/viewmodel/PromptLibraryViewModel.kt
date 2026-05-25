package com.gaokao.cockpit.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gaokao.cockpit.data.model.PromptTemplate
import com.gaokao.cockpit.data.repository.AppRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PromptLibraryViewModel @Inject constructor(
    private val repository: AppRepository
) : ViewModel() {

    private val _templates = MutableStateFlow<List<PromptTemplate>>(emptyList())
    val templates: StateFlow<List<PromptTemplate>> = _templates.asStateFlow()

    private val _selectedCategory = MutableStateFlow("")
    val selectedCategory: StateFlow<String> = _selectedCategory.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _statusMessage = MutableStateFlow<String?>(null)
    val statusMessage: StateFlow<String?> = _statusMessage.asStateFlow()

    init {
        loadTemplates()
    }

    fun loadTemplates() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                repository.seedBuiltInTemplatesIfNeeded()
                refreshTemplates()
            } catch (e: Exception) {
                _statusMessage.value = "加载模板失败：${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun refreshTemplates() {
        viewModelScope.launch {
            try {
                val flow = if (_selectedCategory.value.isNotEmpty())
                    repository.getTemplatesByCategory(_selectedCategory.value)
                else
                    repository.getAllTemplates()
                _templates.value = flow.first()
            } catch (e: Exception) {
                _statusMessage.value = "刷新模板失败：${e.message}"
            }
        }
    }

    fun setCategory(category: String) {
        _selectedCategory.value = category
        refreshTemplates()
    }

    fun incrementUsage(template: PromptTemplate) {
        viewModelScope.launch {
            try {
                val updated = template.copy(usageCount = template.usageCount + 1)
                repository.updateTemplate(updated)
                refreshTemplates()
            } catch (_: Exception) { }
        }
    }
}
