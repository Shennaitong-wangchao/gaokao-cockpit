package com.gaokao.cockpit.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gaokao.cockpit.data.model.DateKey
import com.gaokao.cockpit.data.model.DayPlan
import com.gaokao.cockpit.data.model.LearningSubject
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

sealed class LoadState {
    data object Loading : LoadState()
    data object Loaded : LoadState()
    data class Failed(val message: String) : LoadState()
}

@HiltViewModel
class TodayCockpitViewModel @Inject constructor(
    private val repository: AppRepository
) : ViewModel() {

    private val _loadState = MutableStateFlow<LoadState>(LoadState.Loading)
    val loadState: StateFlow<LoadState> = _loadState.asStateFlow()

    private val _dayPlan = MutableStateFlow<DayPlan?>(null)
    val dayPlan: StateFlow<DayPlan?> = _dayPlan.asStateFlow()

    private val _todayKey = MutableStateFlow(DateKey.today())
    val todayKey: StateFlow<String> = _todayKey.asStateFlow()

    private val _todayDate = MutableStateFlow(Date())
    val todayDate: StateFlow<Date> = _todayDate.asStateFlow()

    private val _stateScore = MutableStateFlow(7)
    val stateScore: StateFlow<Int> = _stateScore.asStateFlow()

    private val _mainSubject = MutableStateFlow("")
    val mainSubject: StateFlow<String> = _mainSubject.asStateFlow()

    private val _topTasksText = MutableStateFlow("")
    val topTasksText: StateFlow<String> = _topTasksText.asStateFlow()

    private val _baselineTasksText = MutableStateFlow("")
    val baselineTasksText: StateFlow<String> = _baselineTasksText.asStateFlow()

    private val _bonusTasksText = MutableStateFlow("")
    val bonusTasksText: StateFlow<String> = _bonusTasksText.asStateFlow()

    private val _tomorrowFirstAction = MutableStateFlow("")
    val tomorrowFirstAction: StateFlow<String> = _tomorrowFirstAction.asStateFlow()

    private val _tasks = MutableStateFlow<List<StudyTask>>(emptyList())
    val tasks: StateFlow<List<StudyTask>> = _tasks.asStateFlow()

    private val _totalTaskCount = MutableStateFlow(0)
    val totalTaskCount: StateFlow<Int> = _totalTaskCount.asStateFlow()

    private val _completedTaskCount = MutableStateFlow(0)
    val completedTaskCount: StateFlow<Int> = _completedTaskCount.asStateFlow()

    private val _builtInPromptTemplateCount = MutableStateFlow(0)
    val builtInPromptTemplateCount: StateFlow<Int> = _builtInPromptTemplateCount.asStateFlow()

    private val _saveMessage = MutableStateFlow<String?>(null)
    val saveMessage: StateFlow<String?> = _saveMessage.asStateFlow()

    private val _taskMessage = MutableStateFlow<String?>(null)
    val taskMessage: StateFlow<String?> = _taskMessage.asStateFlow()

    private val _planTaskMessage = MutableStateFlow<String?>(null)
    val planTaskMessage: StateFlow<String?> = _planTaskMessage.asStateFlow()

    private val _showQuickAdd = MutableStateFlow(false)
    val showQuickAdd: StateFlow<Boolean> = _showQuickAdd.asStateFlow()

    private val _showPlanTaskDialog = MutableStateFlow(false)
    val showPlanTaskDialog: StateFlow<Boolean> = _showPlanTaskDialog.asStateFlow()

    private val _parsedPlanTasks = MutableStateFlow<List<com.gaokao.cockpit.data.model.PlanTaskParser.ParsedPlanTask>>(emptyList())
    val parsedPlanTasks: StateFlow<List<com.gaokao.cockpit.data.model.PlanTaskParser.ParsedPlanTask>> = _parsedPlanTasks.asStateFlow()

    val pendingTaskCount: Int
        get() = maxOf(totalTaskCount.value - completedTaskCount.value, 0)

    val isLowEnergyMode: Boolean
        get() = stateScore.value <= 4

    init {
        loadToday()
    }

    fun loadToday() {
        viewModelScope.launch {
            _loadState.value = LoadState.Loading
            _saveMessage.value = null
            _taskMessage.value = null
            try {
                repository.seedBuiltInTemplatesIfNeeded()
                val plan = repository.fetchOrCreateToday()
                _dayPlan.value = plan
                _todayKey.value = plan.dayKey
                _todayDate.value = Date(plan.date)
                _stateScore.value = plan.stateScore ?: 7
                _mainSubject.value = plan.mainSubject
                _topTasksText.value = plan.topTasksText
                _baselineTasksText.value = plan.baselineTasksText
                _bonusTasksText.value = plan.bonusTasksText
                _tomorrowFirstAction.value = plan.tomorrowFirstAction

                refreshTaskData(plan.dayKey)
                _loadState.value = LoadState.Loaded
            } catch (e: Exception) {
                _loadState.value = LoadState.Failed("无法读取或创建今日计划：${e.message}")
            }
        }
    }

    fun refreshTaskData(dayKey: String) {
        viewModelScope.launch {
            try {
                _tasks.value = repository.getTasksForDay(dayKey).first()
                _totalTaskCount.value = repository.countTasks(dayKey)
                _completedTaskCount.value = repository.countCompletedTasks(dayKey)
                _builtInPromptTemplateCount.value = repository.countBuiltInTemplates()
            } catch (e: Exception) {
                _taskMessage.value = "刷新任务失败：${e.message}"
            }
        }
    }

    fun saveTodayPlan() {
        val plan = _dayPlan.value ?: run {
            _saveMessage.value = "保存失败：今日计划尚未加载。"
            return
        }
        viewModelScope.launch {
            try {
                val updated = plan.copy(
                    stateScore = _stateScore.value,
                    mainSubject = _mainSubject.value.trim(),
                    topTasksText = _topTasksText.value,
                    baselineTasksText = _baselineTasksText.value,
                    bonusTasksText = _bonusTasksText.value,
                    tomorrowFirstAction = _tomorrowFirstAction.value.trim(),
                    updatedAt = System.currentTimeMillis()
                )
                repository.updateDayPlan(updated)
                _dayPlan.value = updated
                _saveMessage.value = "今日计划已保存。"
            } catch (e: Exception) {
                _saveMessage.value = "保存失败：${e.message}"
            }
        }
    }

    fun toggleTaskStatus(task: StudyTask) {
        val currentStatus = StudyTaskStatus.from(task.status)
        if (currentStatus != StudyTaskStatus.PENDING && currentStatus != StudyTaskStatus.DONE) {
            _taskMessage.value = "今日只支持快速切换待做/完成；更多状态请到任务页处理。"
            return
        }
        viewModelScope.launch {
            try {
                val newStatus = if (currentStatus == StudyTaskStatus.DONE) StudyTaskStatus.PENDING else StudyTaskStatus.DONE
                val updated = task.copy(
                    status = newStatus.storageValue,
                    updatedAt = System.currentTimeMillis()
                )
                repository.updateTask(updated)
                refreshTaskData(task.dayKey)
                _taskMessage.value = if (newStatus == StudyTaskStatus.DONE) "已标记完成。" else "已撤回待做。"
            } catch (e: Exception) {
                _taskMessage.value = "更新任务失败：${e.message}"
            }
        }
    }

    fun setStateScore(score: Int) {
        _stateScore.value = score.coerceIn(1, 10)
    }

    fun setMainSubject(subject: String) {
        _mainSubject.value = subject
    }

    fun setTopTasksText(text: String) { _topTasksText.value = text }
    fun setBaselineTasksText(text: String) { _baselineTasksText.value = text }
    fun setBonusTasksText(text: String) { _bonusTasksText.value = text }
    fun setTomorrowFirstAction(text: String) { _tomorrowFirstAction.value = text }
    fun showQuickAdd() { _showQuickAdd.value = true }
    fun dismissQuickAdd() { _showQuickAdd.value = false }

    fun preparePlanTaskGeneration() {
        _taskMessage.value = null
        _planTaskMessage.value = null
        val parsed = com.gaokao.cockpit.data.model.PlanTaskParser.parsePlanSections(
            top = _topTasksText.value,
            baseline = _baselineTasksText.value,
            bonus = _bonusTasksText.value
        )
        if (parsed.isEmpty()) {
            _planTaskMessage.value = "先在重点 / 保底 / 加分任务里写至少一行计划。"
            return
        }
        _parsedPlanTasks.value = parsed
        _showPlanTaskDialog.value = true
    }

    fun dismissPlanTaskDialog() {
        _showPlanTaskDialog.value = false
        _parsedPlanTasks.value = emptyList()
    }

    fun createTasksFromPlan(selectedTasks: List<com.gaokao.cockpit.data.model.PlanTaskParser.ParsedPlanTask>) {
        val plan = _dayPlan.value ?: run {
            _taskMessage.value = "生成失败：今日计划尚未加载。"
            return
        }
        viewModelScope.launch {
            try {
                val updated = plan.copy(
                    stateScore = _stateScore.value,
                    mainSubject = _mainSubject.value.trim(),
                    topTasksText = _topTasksText.value,
                    baselineTasksText = _baselineTasksText.value,
                    bonusTasksText = _bonusTasksText.value,
                    tomorrowFirstAction = _tomorrowFirstAction.value.trim(),
                    updatedAt = System.currentTimeMillis()
                )
                repository.updateDayPlan(updated)

                val existingTitles = repository.getTasksForDay(_todayKey.value).first()
                    .map { com.gaokao.cockpit.data.model.PlanTaskParser.normalizedTitleKey(it.title) }
                    .toSet()

                var created = 0
                var skipped = 0
                selectedTasks.forEach { parsed ->
                    if (existingTitles.contains(com.gaokao.cockpit.data.model.PlanTaskParser.normalizedTitleKey(parsed.title))) {
                        skipped++
                    } else {
                        val task = com.gaokao.cockpit.data.model.StudyTask(
                            dayPlanId = plan.id,
                            dayKey = plan.dayKey,
                            title = parsed.title,
                            subject = parsed.subject,
                            category = parsed.category,
                            estimatedMinutes = parsed.estimatedMinutes
                        )
                        repository.insertTask(task)
                        created++
                    }
                }
                refreshTaskData(_todayKey.value)
                _saveMessage.value = "已保存今日计划。"
                _planTaskMessage.value = "已生成 $created 个任务，跳过 $skipped 个重复任务。"
                _showPlanTaskDialog.value = false
            } catch (e: Exception) {
                _taskMessage.value = "生成今日任务失败：${e.message}"
            }
        }
    }
}
