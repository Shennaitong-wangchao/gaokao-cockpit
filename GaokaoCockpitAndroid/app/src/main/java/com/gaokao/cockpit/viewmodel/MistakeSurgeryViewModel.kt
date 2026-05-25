package com.gaokao.cockpit.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gaokao.cockpit.data.model.LearningSubject
import com.gaokao.cockpit.data.model.MistakeRecord
import com.gaokao.cockpit.data.model.ReviewStatus
import com.gaokao.cockpit.data.repository.AppRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class MistakeSurgeryViewModel @Inject constructor(
    private val repository: AppRepository
) : ViewModel() {

    private val _mistakes = MutableStateFlow<List<MistakeRecord>>(emptyList())
    val mistakes: StateFlow<List<MistakeRecord>> = _mistakes.asStateFlow()

    private val _selectedSubjectFilter = MutableStateFlow("")
    val selectedSubjectFilter: StateFlow<String> = _selectedSubjectFilter.asStateFlow()

    private val _selectedReviewFilter = MutableStateFlow("")
    val selectedReviewFilter: StateFlow<String> = _selectedReviewFilter.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _statusMessage = MutableStateFlow<String?>(null)
    val statusMessage: StateFlow<String?> = _statusMessage.asStateFlow()

    private val _showEditor = MutableStateFlow(false)
    val showEditor: StateFlow<Boolean> = _showEditor.asStateFlow()

    private val _editingMistake = MutableStateFlow<MistakeRecord?>(null)
    val editingMistake: StateFlow<MistakeRecord?> = _editingMistake.asStateFlow()

    private val _totalMistakeCount = MutableStateFlow(0)
    val totalMistakeCount: StateFlow<Int> = _totalMistakeCount.asStateFlow()

    private val _scheduledCount = MutableStateFlow(0)
    val scheduledCount: StateFlow<Int> = _scheduledCount.asStateFlow()

    private val _reviewedCount = MutableStateFlow(0)
    val reviewedCount: StateFlow<Int> = _reviewedCount.asStateFlow()

    private val _masteredCount = MutableStateFlow(0)
    val masteredCount: StateFlow<Int> = _masteredCount.asStateFlow()

    init {
        loadMistakes()
    }

    fun loadMistakes() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                refreshMistakeData()
            } catch (e: Exception) {
                _statusMessage.value = "加载错题失败：${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun refreshMistakeData() {
        viewModelScope.launch {
            try {
                val flow = when {
                    _selectedSubjectFilter.value.isNotEmpty() && _selectedReviewFilter.value.isNotEmpty() ->
                        repository.getMistakesBySubjectAndStatus(_selectedSubjectFilter.value, _selectedReviewFilter.value)
                    _selectedSubjectFilter.value.isNotEmpty() ->
                        repository.getMistakesBySubject(_selectedSubjectFilter.value)
                    _selectedReviewFilter.value.isNotEmpty() ->
                        repository.getMistakesByStatus(_selectedReviewFilter.value)
                    else -> repository.getAllMistakes()
                }
                _mistakes.value = flow.first()
                _totalMistakeCount.value = repository.countAllMistakes()
                _scheduledCount.value = repository.countMistakesByStatus(ReviewStatus.SCHEDULED.storageValue)
                _reviewedCount.value = repository.countMistakesByStatus(ReviewStatus.REVIEWED.storageValue)
                _masteredCount.value = repository.countMistakesByStatus(ReviewStatus.MASTERED.storageValue)
            } catch (e: Exception) {
                _statusMessage.value = "刷新错题失败：${e.message}"
            }
        }
    }

    fun setSubjectFilter(subject: String) {
        _selectedSubjectFilter.value = subject
        refreshMistakeData()
    }

    fun setReviewFilter(status: String) {
        _selectedReviewFilter.value = status
        refreshMistakeData()
    }

    fun updateReviewStatus(mistake: MistakeRecord, status: ReviewStatus) {
        viewModelScope.launch {
            try {
                val updated = mistake.copy(reviewStatus = status.storageValue, updatedAt = System.currentTimeMillis())
                repository.updateMistake(updated)
                refreshMistakeData()
                _statusMessage.value = "已更新状态：${status.displayName}。"
            } catch (e: Exception) {
                _statusMessage.value = "更新状态失败：${e.message}"
            }
        }
    }

    fun saveMistake(mistake: MistakeRecord) {
        viewModelScope.launch {
            try {
                if (repository.getAllMistakes().first().any { it.id == mistake.id }) {
                    repository.updateMistake(mistake)
                    _statusMessage.value = "错题已更新。"
                } else {
                    repository.insertMistake(mistake)
                    _statusMessage.value = "错题已添加。"
                }
                refreshMistakeData()
            } catch (e: Exception) {
                _statusMessage.value = "保存错题失败：${e.message}"
            }
        }
    }

    fun deleteMistake(id: String) {
        viewModelScope.launch {
            try {
                repository.deleteMistakeById(id)
                refreshMistakeData()
                _statusMessage.value = "错题已删除。"
            } catch (e: Exception) {
                _statusMessage.value = "删除错题失败：${e.message}"
            }
        }
    }

    fun showAddEditor() {
        _editingMistake.value = null
        _showEditor.value = true
    }

    fun showEditEditor(mistake: MistakeRecord) {
        _editingMistake.value = mistake
        _showEditor.value = true
    }

    fun dismissEditor() {
        _showEditor.value = false
        _editingMistake.value = null
    }
}
