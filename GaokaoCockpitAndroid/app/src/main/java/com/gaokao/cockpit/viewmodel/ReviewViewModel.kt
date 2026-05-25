package com.gaokao.cockpit.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gaokao.cockpit.data.model.DailyReview
import com.gaokao.cockpit.data.model.DateKey
import com.gaokao.cockpit.data.model.MistakeRecord
import com.gaokao.cockpit.data.model.WeeklyReview
import com.gaokao.cockpit.data.repository.AppRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.util.Date
import javax.inject.Inject

enum class ReviewMode { DAILY, WEEKLY }

@HiltViewModel
class ReviewViewModel @Inject constructor(
    private val repository: AppRepository
) : ViewModel() {

    private val _loadState = MutableStateFlow<com.gaokao.cockpit.viewmodel.LoadState>(com.gaokao.cockpit.viewmodel.LoadState.Loading)
    val loadState: StateFlow<com.gaokao.cockpit.viewmodel.LoadState> = _loadState.asStateFlow()

    private val _selectedMode = MutableStateFlow(ReviewMode.DAILY)
    val selectedMode: StateFlow<ReviewMode> = _selectedMode.asStateFlow()

    private val _todayKey = MutableStateFlow(DateKey.today())
    val todayKey: StateFlow<String> = _todayKey.asStateFlow()

    private val _todayDate = MutableStateFlow(Date())
    val todayDate: StateFlow<Date> = _todayDate.asStateFlow()

    private val _dailyReview = MutableStateFlow<DailyReview?>(null)
    val dailyReview: StateFlow<DailyReview?> = _dailyReview.asStateFlow()

    private val _weeklyReview = MutableStateFlow<WeeklyReview?>(null)
    val weeklyReview: StateFlow<WeeklyReview?> = _weeklyReview.asStateFlow()

    private val _todayMistakes = MutableStateFlow<List<MistakeRecord>>(emptyList())
    val todayMistakes: StateFlow<List<MistakeRecord>> = _todayMistakes.asStateFlow()

    private val _completedSummary = MutableStateFlow("")
    val completedSummary: StateFlow<String> = _completedSummary.asStateFlow()

    private val _unfinishedSummary = MutableStateFlow("")
    val unfinishedSummary: StateFlow<String> = _unfinishedSummary.asStateFlow()

    private val _biggestProblem = MutableStateFlow("")
    val biggestProblem: StateFlow<String> = _biggestProblem.asStateFlow()

    private val _stateScoreEnd = MutableStateFlow<Int?>(null)
    val stateScoreEnd: StateFlow<Int?> = _stateScoreEnd.asStateFlow()

    private val _tomorrowFirstAction = MutableStateFlow("")
    val tomorrowFirstAction: StateFlow<String> = _tomorrowFirstAction.asStateFlow()

    private val _keyProblemsText = MutableStateFlow("")
    val keyProblemsText: StateFlow<String> = _keyProblemsText.asStateFlow()

    private val _nextWeekFocusText = MutableStateFlow("")
    val nextWeekFocusText: StateFlow<String> = _nextWeekFocusText.asStateFlow()

    private val _statusMessage = MutableStateFlow<String?>(null)
    val statusMessage: StateFlow<String?> = _statusMessage.asStateFlow()

    init {
        loadReviews()
    }

    fun loadReviews() {
        viewModelScope.launch {
            _loadState.value = com.gaokao.cockpit.viewmodel.LoadState.Loading
            try {
                val todayKey = DateKey.today()
                _todayKey.value = todayKey
                _todayDate.value = Date()

                val daily = repository.getDailyReview(todayKey)
                _dailyReview.value = daily
                _completedSummary.value = daily?.completedSummary ?: ""
                _unfinishedSummary.value = daily?.unfinishedSummary ?: ""
                _biggestProblem.value = daily?.biggestProblem ?: ""
                _stateScoreEnd.value = daily?.stateScoreEnd
                _tomorrowFirstAction.value = daily?.tomorrowFirstAction ?: ""

                val weekStart = DateKey.weekStart()
                val weekStartKey = DateKey.keyFor(weekStart)
                val weekly = repository.getWeeklyReview(weekStartKey)
                _weeklyReview.value = weekly
                _keyProblemsText.value = weekly?.keyProblemsText ?: ""
                _nextWeekFocusText.value = weekly?.nextWeekFocusText ?: ""

                _todayMistakes.value = repository.getAllMistakes().first().filter {
                    DateKey.keyFor(Date(it.createdAt)) == todayKey
                }

                _loadState.value = com.gaokao.cockpit.viewmodel.LoadState.Loaded
            } catch (e: Exception) {
                _loadState.value = com.gaokao.cockpit.viewmodel.LoadState.Failed("加载复盘失败：${e.message}")
            }
        }
    }

    fun setMode(mode: ReviewMode) {
        _selectedMode.value = mode
    }

    fun saveDailyReview() {
        viewModelScope.launch {
            try {
                val review = DailyReview(
                    id = _dailyReview.value?.id ?: java.util.UUID.randomUUID().toString(),
                    dayKey = _todayKey.value,
                    date = System.currentTimeMillis(),
                    completedSummary = _completedSummary.value,
                    unfinishedSummary = _unfinishedSummary.value,
                    biggestProblem = _biggestProblem.value,
                    stateScoreEnd = _stateScoreEnd.value,
                    tomorrowFirstAction = _tomorrowFirstAction.value,
                    createdAt = _dailyReview.value?.createdAt ?: System.currentTimeMillis(),
                    updatedAt = System.currentTimeMillis()
                )
                repository.insertDailyReview(review)
                _dailyReview.value = review
                _statusMessage.value = "每日复盘已保存。"
            } catch (e: Exception) {
                _statusMessage.value = "保存失败：${e.message}"
            }
        }
    }

    fun saveWeeklyReview() {
        viewModelScope.launch {
            try {
                val weekStart = DateKey.weekStart()
                val weekEnd = DateKey.weekEnd()
                val review = WeeklyReview(
                    id = _weeklyReview.value?.id ?: java.util.UUID.randomUUID().toString(),
                    weekStartKey = DateKey.keyFor(weekStart),
                    weekEndKey = DateKey.keyFor(weekEnd),
                    weekStartDate = weekStart.time,
                    weekEndDate = weekEnd.time,
                    keyProblemsText = _keyProblemsText.value,
                    nextWeekFocusText = _nextWeekFocusText.value,
                    createdAt = _weeklyReview.value?.createdAt ?: System.currentTimeMillis(),
                    updatedAt = System.currentTimeMillis()
                )
                repository.insertWeeklyReview(review)
                _weeklyReview.value = review
                _statusMessage.value = "周复盘已保存。"
            } catch (e: Exception) {
                _statusMessage.value = "保存失败：${e.message}"
            }
        }
    }

    fun applyDailyQuickTemplate() {
        viewModelScope.launch {
            val tasks = repository.getTasksForDay(_todayKey.value).first()
            val completed = tasks.filter { com.gaokao.cockpit.data.model.StudyTaskStatus.from(it.status) == com.gaokao.cockpit.data.model.StudyTaskStatus.DONE }
            val unfinished = tasks.filter { com.gaokao.cockpit.data.model.StudyTaskStatus.from(it.status) != com.gaokao.cockpit.data.model.StudyTaskStatus.DONE }

            _completedSummary.value = completed.joinToString("\n") { "- ${it.title}" }
            _unfinishedSummary.value = unfinished.joinToString("\n") { "- ${it.title}" }
            if (_biggestProblem.value.isBlank()) {
                _biggestProblem.value = "（待填写）"
            }
        }
    }

    fun generateWeeklySummary() {
        viewModelScope.launch {
            try {
                val weekStart = com.gaokao.cockpit.data.model.DateKey.weekStart()
                val weekStartKey = com.gaokao.cockpit.data.model.DateKey.keyFor(weekStart)
                val weekEndKey = com.gaokao.cockpit.data.model.DateKey.keyFor(com.gaokao.cockpit.data.model.DateKey.weekEnd())

                // Collect all tasks in the week
                var totalMinutes = 0
                var completedCount = 0
                val subjectMinutes = mutableMapOf<String, Int>()

                val calendar = java.util.Calendar.getInstance()
                calendar.time = weekStart
                for (i in 0..6) {
                    val dayKey = com.gaokao.cockpit.data.model.DateKey.keyFor(calendar.time)
                    val dayTasks = repository.getTasksForDay(dayKey).first()
                    dayTasks.forEach { task ->
                        if (com.gaokao.cockpit.data.model.StudyTaskStatus.from(task.status) == com.gaokao.cockpit.data.model.StudyTaskStatus.DONE) {
                            completedCount++
                            val mins = task.actualMinutes ?: task.estimatedMinutes ?: 0
                            totalMinutes += mins
                            val subject = task.subject.ifBlank { "其他" }
                            subjectMinutes[subject] = subjectMinutes.getOrDefault(subject, 0) + mins
                        }
                    }
                    calendar.add(java.util.Calendar.DAY_OF_YEAR, 1)
                }

                // Collect mistakes in the week
                val allMistakes = repository.getAllMistakes().first()
                val weekMistakes = allMistakes.filter {
                    val mistakeKey = com.gaokao.cockpit.data.model.DateKey.keyFor(java.util.Date(it.createdAt))
                    mistakeKey in weekStartKey..weekEndKey
                }
                val mistakeCount = weekMistakes.size
                val mistakeTypeMap = weekMistakes.groupingBy { com.gaokao.cockpit.data.model.MistakeType.from(it.mistakeType).displayName }.eachCount()

                val subjectBreakdown = subjectMinutes.entries.sortedByDescending { it.value }
                    .joinToString("\n") { "${it.key}: ${it.value}分钟" }

                val mistakeBreakdown = mistakeTypeMap.entries.sortedByDescending { it.value }
                    .joinToString("\n") { "${it.key}: ${it.value}道" }

                // Build summary text
                val summaryLines = mutableListOf<String>()
                summaryLines.add("本周学习总时长: ${totalMinutes}分钟 (${totalMinutes / 60}小时${totalMinutes % 60}分钟)")
                summaryLines.add("完成任务数: $completedCount")
                summaryLines.add("")
                summaryLines.add("学科分布:")
                summaryLines.add(subjectBreakdown.ifBlank { "暂无数据" })
                summaryLines.add("")
                summaryLines.add("本周错题: $mistakeCount 道")
                summaryLines.add(mistakeBreakdown.ifBlank { "暂无数据" })

                val summaryText = summaryLines.joinToString("\n")

                // Update weekly review with auto-generated data
                _keyProblemsText.value = summaryText + "\n\n（在此补充关键问题分析）"
                _statusMessage.value = "已自动生成周统计。"
            } catch (e: Exception) {
                _statusMessage.value = "自动生成统计失败：${e.message}"
            }
        }
    }

    fun setCompletedSummary(text: String) { _completedSummary.value = text }
    fun setUnfinishedSummary(text: String) { _unfinishedSummary.value = text }
    fun setBiggestProblem(text: String) { _biggestProblem.value = text }
    fun setStateScoreEnd(score: Int?) { _stateScoreEnd.value = score }
    fun setTomorrowFirstAction(text: String) { _tomorrowFirstAction.value = text }
    fun setKeyProblemsText(text: String) { _keyProblemsText.value = text }
    fun setNextWeekFocusText(text: String) { _nextWeekFocusText.value = text }
}
