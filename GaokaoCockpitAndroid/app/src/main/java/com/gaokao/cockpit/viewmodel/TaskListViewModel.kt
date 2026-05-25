package com.gaokao.cockpit.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gaokao.cockpit.data.model.DateKey
import com.gaokao.cockpit.data.model.DayPlan
import com.gaokao.cockpit.data.model.StudyTask
import com.gaokao.cockpit.data.model.StudyTaskStatus
import com.gaokao.cockpit.data.repository.AppRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.util.Date
import javax.inject.Inject

enum class TaskFilter(val title: String) {
    ALL("全部"),
    PENDING("未开始"),
    IN_PROGRESS("进行中"),
    DONE("已完成"),
    UNFINISHED("未完成");
}

@HiltViewModel
class TaskListViewModel @Inject constructor(
    private val repository: AppRepository
) : ViewModel() {

    private val _todayKey = MutableStateFlow(DateKey.today())
    val todayKey: StateFlow<String> = _todayKey.asStateFlow()

    private val _todayDate = MutableStateFlow(Date())
    val todayDate: StateFlow<Date> = _todayDate.asStateFlow()

    private val _dayPlan = MutableStateFlow<DayPlan?>(null)
    val dayPlan: StateFlow<DayPlan?> = _dayPlan.asStateFlow()

    private val _tasks = MutableStateFlow<List<StudyTask>>(emptyList())
    val tasks: StateFlow<List<StudyTask>> = _tasks.asStateFlow()

    private val _selectedFilter = MutableStateFlow(TaskFilter.ALL)
    val selectedFilter: StateFlow<TaskFilter> = _selectedFilter.asStateFlow()

    private val _totalTaskCount = MutableStateFlow(0)
    val totalTaskCount: StateFlow<Int> = _totalTaskCount.asStateFlow()

    private val _completedTaskCount = MutableStateFlow(0)
    val completedTaskCount: StateFlow<Int> = _completedTaskCount.asStateFlow()

    private val _skippedTaskCount = MutableStateFlow(0)
    val skippedTaskCount: StateFlow<Int> = _skippedTaskCount.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _statusMessage = MutableStateFlow<String?>(null)
    val statusMessage: StateFlow<String?> = _statusMessage.asStateFlow()

    private val _showEditor = MutableStateFlow(false)
    val showEditor: StateFlow<Boolean> = _showEditor.asStateFlow()

    private val _editingTask = MutableStateFlow<StudyTask?>(null)
    val editingTask: StateFlow<StudyTask?> = _editingTask.asStateFlow()

    val unfinishedTaskCount: Int
        get() = maxOf(totalTaskCount.value - completedTaskCount.value - skippedTaskCount.value, 0)

    init {
        loadTodayTasks()
    }

    fun loadTodayTasks() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val plan = repository.fetchOrCreateToday()
                _dayPlan.value = plan
                _todayKey.value = plan.dayKey
                _todayDate.value = Date(plan.date)
                refreshTaskData()
            } catch (e: Exception) {
                _statusMessage.value = "加载任务失败：${e.message}"
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun refreshTaskData() {
        viewModelScope.launch {
            try {
                val flow = when (_selectedFilter.value) {
                    TaskFilter.PENDING -> repository.getTasksForDayWithStatus(_todayKey.value, StudyTaskStatus.PENDING.storageValue)
                    TaskFilter.IN_PROGRESS -> repository.getTasksForDayWithStatus(_todayKey.value, StudyTaskStatus.IN_PROGRESS.storageValue)
                    TaskFilter.DONE -> repository.getTasksForDayWithStatus(_todayKey.value, StudyTaskStatus.DONE.storageValue)
                    else -> repository.getTasksForDay(_todayKey.value)
                }
                var fetched = flow.first()
                if (_selectedFilter.value == TaskFilter.UNFINISHED) {
                    fetched = fetched.filter { StudyTaskStatus.from(it.status) != StudyTaskStatus.DONE }
                }
                _tasks.value = fetched
                _totalTaskCount.value = repository.countTasks(_todayKey.value)
                _completedTaskCount.value = repository.countCompletedTasks(_todayKey.value)
                _skippedTaskCount.value = repository.countSkippedTasks(_todayKey.value)
            } catch (e: Exception) {
                _statusMessage.value = "刷新任务失败：${e.message}"
            }
        }
    }

    fun setFilter(filter: TaskFilter) {
        _selectedFilter.value = filter
        refreshTaskData()
    }

    fun updateTaskStatus(task: StudyTask, status: StudyTaskStatus) {
        if (StudyTaskStatus.from(task.status) == status) return
        viewModelScope.launch {
            try {
                val updated = task.copy(status = status.storageValue, updatedAt = System.currentTimeMillis())
                repository.updateTask(updated)
                refreshTaskData()
                _statusMessage.value = "已更新状态：${status.displayName}。"
            } catch (e: Exception) {
                _statusMessage.value = "更新状态失败：${e.message}"
            }
        }
    }

    fun addTask(task: StudyTask) {
        viewModelScope.launch {
            try {
                repository.insertTask(task)
                refreshTaskData()
                _statusMessage.value = "任务已添加。"
            } catch (e: Exception) {
                _statusMessage.value = "添加任务失败：${e.message}"
            }
        }
    }

    fun updateTask(task: StudyTask) {
        viewModelScope.launch {
            try {
                repository.updateTask(task)
                refreshTaskData()
                _statusMessage.value = "任务已更新。"
            } catch (e: Exception) {
                _statusMessage.value = "更新任务失败：${e.message}"
            }
        }
    }

    fun deleteTask(task: StudyTask) {
        viewModelScope.launch {
            try {
                repository.deleteTask(task)
                refreshTaskData()
                _statusMessage.value = "任务已删除。"
            } catch (e: Exception) {
                _statusMessage.value = "删除任务失败：${e.message}"
            }
        }
    }

    fun showAddEditor() {
        _editingTask.value = null
        _showEditor.value = true
    }

    fun showEditEditor(task: StudyTask) {
        _editingTask.value = task
        _showEditor.value = true
    }

    fun dismissEditor() {
        _showEditor.value = false
        _editingTask.value = null
    }
}
