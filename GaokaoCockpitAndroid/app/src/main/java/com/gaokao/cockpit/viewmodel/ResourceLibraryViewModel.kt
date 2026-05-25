package com.gaokao.cockpit.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gaokao.cockpit.data.model.ResourceItem
import com.gaokao.cockpit.data.model.ResourceStatus
import com.gaokao.cockpit.data.repository.AppRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ResourceLibraryViewModel @Inject constructor(
    private val repository: AppRepository
) : ViewModel() {

    private val _resources = MutableStateFlow<List<ResourceItem>>(emptyList())
    val resources: StateFlow<List<ResourceItem>> = _resources.asStateFlow()

    private val _selectedStatusFilter = MutableStateFlow("")
    val selectedStatusFilter: StateFlow<String> = _selectedStatusFilter.asStateFlow()

    private val _selectedSubjectFilter = MutableStateFlow("")
    val selectedSubjectFilter: StateFlow<String> = _selectedSubjectFilter.asStateFlow()

    private val _showEditor = MutableStateFlow(false)
    val showEditor: StateFlow<Boolean> = _showEditor.asStateFlow()

    private val _editingResource = MutableStateFlow<ResourceItem?>(null)
    val editingResource: StateFlow<ResourceItem?> = _editingResource.asStateFlow()

    private val _statusMessage = MutableStateFlow<String?>(null)
    val statusMessage: StateFlow<String?> = _statusMessage.asStateFlow()

    fun loadResources() {
        viewModelScope.launch {
            refreshResources()
        }
    }

    fun refreshResources() {
        viewModelScope.launch {
            try {
                val all = repository.getAllResources().first()
                _resources.value = all.filter {
                    (_selectedStatusFilter.value.isEmpty() || it.status == _selectedStatusFilter.value) &&
                    (_selectedSubjectFilter.value.isEmpty() || it.subject == _selectedSubjectFilter.value)
                }
            } catch (e: Exception) {
                _statusMessage.value = "刷新资源失败：${e.message}"
            }
        }
    }

    fun setStatusFilter(status: String) {
        _selectedStatusFilter.value = status
        refreshResources()
    }

    fun setSubjectFilter(subject: String) {
        _selectedSubjectFilter.value = subject
        refreshResources()
    }

    fun updateResourceStatus(resource: ResourceItem, status: ResourceStatus) {
        viewModelScope.launch {
            try {
                val updated = resource.copy(status = status.storageValue, updatedAt = System.currentTimeMillis())
                repository.updateResource(updated)
                refreshResources()
                _statusMessage.value = "已更新状态：${status.displayName}"
            } catch (e: Exception) {
                _statusMessage.value = "更新状态失败：${e.message}"
            }
        }
    }

    fun saveResource(resource: ResourceItem) {
        viewModelScope.launch {
            try {
                val exists = repository.getAllResources().first().any { it.id == resource.id }
                if (exists) {
                    repository.updateResource(resource)
                    _statusMessage.value = "资源已更新"
                } else {
                    repository.insertResource(resource)
                    _statusMessage.value = "资源已添加"
                }
                refreshResources()
            } catch (e: Exception) {
                _statusMessage.value = "保存资源失败：${e.message}"
            }
        }
    }

    fun deleteResource(id: String) {
        viewModelScope.launch {
            try {
                repository.deleteResourceById(id)
                refreshResources()
                _statusMessage.value = "资源已删除"
            } catch (e: Exception) {
                _statusMessage.value = "删除资源失败：${e.message}"
            }
        }
    }

    fun showAddEditor() {
        _editingResource.value = null
        _showEditor.value = true
    }

    fun showEditEditor(resource: ResourceItem) {
        _editingResource.value = resource
        _showEditor.value = true
    }

    fun dismissEditor() {
        _showEditor.value = false
        _editingResource.value = null
    }
}
