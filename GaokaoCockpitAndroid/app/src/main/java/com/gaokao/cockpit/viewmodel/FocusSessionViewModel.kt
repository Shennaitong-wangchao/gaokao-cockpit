package com.gaokao.cockpit.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gaokao.cockpit.data.model.DateKey
import com.gaokao.cockpit.data.model.FocusSession
import com.gaokao.cockpit.data.model.StudyTask
import com.gaokao.cockpit.data.repository.AppRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FocusSessionViewModel @Inject constructor(
    private val savedStateHandle: androidx.lifecycle.SavedStateHandle,
    private val repository: AppRepository
) : ViewModel() {

    companion object {
        private const val KEY_ELAPSED_SECONDS = "focus_elapsed_seconds"
        private const val KEY_DISTRACTION_COUNT = "focus_distraction_count"
        private const val KEY_IS_RUNNING = "focus_is_running"
        private const val KEY_HAS_STARTED = "focus_has_started"
        private const val KEY_PLANNED_MINUTES = "focus_planned_minutes"
    }

    private val _task = MutableStateFlow<StudyTask?>(null)
    val task: StateFlow<StudyTask?> = _task.asStateFlow()

    private val _plannedMinutes = MutableStateFlow(savedStateHandle[KEY_PLANNED_MINUTES] ?: 25)
    val plannedMinutes: StateFlow<Int> = _plannedMinutes.asStateFlow()

    private val _elapsedSeconds = MutableStateFlow(savedStateHandle[KEY_ELAPSED_SECONDS] ?: 0)
    val elapsedSeconds: StateFlow<Int> = _elapsedSeconds.asStateFlow()

    private val _distractionCount = MutableStateFlow(savedStateHandle[KEY_DISTRACTION_COUNT] ?: 0)
    val distractionCount: StateFlow<Int> = _distractionCount.asStateFlow()

    private val _isRunning = MutableStateFlow(savedStateHandle[KEY_IS_RUNNING] ?: false)
    val isRunning: StateFlow<Boolean> = _isRunning.asStateFlow()

    private val _hasStarted = MutableStateFlow(savedStateHandle[KEY_HAS_STARTED] ?: false)
    val hasStarted: StateFlow<Boolean> = _hasStarted.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _showFinishSheet = MutableStateFlow(false)
    val showFinishSheet: StateFlow<Boolean> = _showFinishSheet.asStateFlow()

    private val _session = MutableStateFlow<FocusSession?>(null)
    val session: StateFlow<FocusSession?> = _session.asStateFlow()

    private var timerJob: Job? = null

    fun loadTask(taskId: String) {
        viewModelScope.launch {
            _task.value = repository.getTaskById(taskId)
            val t = _task.value
            if (t != null) {
                val estimate = t.estimatedMinutes
                if (estimate != null && estimate > 0) {
                    _plannedMinutes.value = estimate
                }
            }
        }
    }

    fun setPlannedMinutes(minutes: Int) {
        if (!_hasStarted.value) {
            _plannedMinutes.value = minutes
            savedStateHandle[KEY_PLANNED_MINUTES] = minutes
        }
    }

    fun startFocus() {
        val t = _task.value ?: run {
            _errorMessage.value = "开始专注失败：任务未加载。"
            return
        }
        viewModelScope.launch {
            try {
                val session = FocusSession(
                    taskId = t.id,
                    dayKey = DateKey.today(),
                    subject = t.subject,
                    plannedMinutes = _plannedMinutes.value
                )
                repository.insertSession(session)
                _session.value = session
                _elapsedSeconds.value = 0
                _distractionCount.value = 0
                _hasStarted.value = true
                _isRunning.value = true
                savedStateHandle[KEY_HAS_STARTED] = true
                savedStateHandle[KEY_IS_RUNNING] = true
                savedStateHandle[KEY_ELAPSED_SECONDS] = 0
                savedStateHandle[KEY_DISTRACTION_COUNT] = 0
                _errorMessage.value = null
                startTimer()
            } catch (e: Exception) {
                _errorMessage.value = "开始专注失败：${e.message}"
            }
        }
    }

    private fun startTimer() {
        timerJob?.cancel()
        timerJob = viewModelScope.launch {
            while (isActive) {
                delay(1000)
                if (_isRunning.value) {
                    _elapsedSeconds.value += 1
                    savedStateHandle[KEY_ELAPSED_SECONDS] = _elapsedSeconds.value
                }
            }
        }
    }

    fun togglePause() {
        _isRunning.value = !_isRunning.value
        savedStateHandle[KEY_IS_RUNNING] = _isRunning.value
    }

    fun addDistraction() {
        _distractionCount.value += 1
        savedStateHandle[KEY_DISTRACTION_COUNT] = _distractionCount.value
    }

    fun prepareFinish() {
        if (_session.value == null) {
            _errorMessage.value = "结束失败：没有正在进行的专注记录。"
            return
        }
        _isRunning.value = false
        savedStateHandle[KEY_IS_RUNNING] = false
        _showFinishSheet.value = true
    }

    fun cancelFinish() {
        _showFinishSheet.value = false
        _isRunning.value = true
        savedStateHandle[KEY_IS_RUNNING] = true
    }

    fun finishSession(sessionNote: String, nextAction: String, completionScore: Int?) {
        val s = _session.value ?: return
        viewModelScope.launch {
            try {
                val actualMinutes = _elapsedSeconds.value / 60
                val updated = s.copy(
                    endTime = System.currentTimeMillis(),
                    actualMinutes = if (actualMinutes > 0) actualMinutes else null,
                    distractionCount = _distractionCount.value,
                    completionScore = completionScore,
                    sessionNote = sessionNote,
                    nextAction = nextAction
                )
                repository.updateSession(updated)
                _session.value = updated
                _showFinishSheet.value = false
            } catch (e: Exception) {
                _errorMessage.value = "保存专注记录失败：${e.message}"
            }
        }
    }

    val formattedElapsedTime: String
        get() {
            val minutes = _elapsedSeconds.value / 60
            val seconds = _elapsedSeconds.value % 60
            return String.format("%02d:%02d", minutes, seconds)
        }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
    }
}
