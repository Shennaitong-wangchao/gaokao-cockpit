package com.gaokao.cockpit.viewmodel

import android.app.Application
import android.content.Context
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.gaokao.cockpit.data.model.DailyReview
import com.gaokao.cockpit.data.model.DayPlan
import com.gaokao.cockpit.data.model.FocusSession
import com.gaokao.cockpit.data.model.MistakeRecord
import com.gaokao.cockpit.data.model.ResourceItem
import com.gaokao.cockpit.data.model.StudyTask
import com.gaokao.cockpit.data.model.WeeklyReview
import com.gaokao.cockpit.data.repository.AppRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import org.json.JSONObject
import javax.inject.Inject

sealed class ImportPreviewState {
    data object Idle : ImportPreviewState()
    data object Parsing : ImportPreviewState()
    data class Preview(
        val tasks: List<StudyTask>,
        val dayPlans: List<DayPlan>,
        val focusSessions: List<FocusSession>,
        val mistakes: List<MistakeRecord>,
        val dailyReviews: List<DailyReview>,
        val weeklyReviews: List<WeeklyReview>,
        val resources: List<ResourceItem>,
        val totalCount: Int
    ) : ImportPreviewState()
    data class Error(val message: String) : ImportPreviewState()
}

@HiltViewModel
class BackupImportViewModel @Inject constructor(
    application: Application,
    private val repository: AppRepository
) : AndroidViewModel(application) {

    private val _previewState = MutableStateFlow<ImportPreviewState>(ImportPreviewState.Idle)
    val previewState: StateFlow<ImportPreviewState> = _previewState.asStateFlow()

    private val _isImporting = MutableStateFlow(false)
    val isImporting: StateFlow<Boolean> = _isImporting.asStateFlow()

    private val _importResult = MutableStateFlow<String?>(null)
    val importResult: StateFlow<String?> = _importResult.asStateFlow()

    private val context: Context get() = getApplication()

    fun parseBackupFile(uri: Uri) {
        viewModelScope.launch {
            _previewState.value = ImportPreviewState.Parsing
            _importResult.value = null
            try {
                val jsonString = context.contentResolver.openInputStream(uri)?.use { it.reader().readText() }
                    ?: throw IllegalArgumentException("无法读取文件")

                val json = JSONObject(jsonString)
                val exportVersion = json.optInt("exportVersion", 1)

                val tasks = mutableListOf<StudyTask>()
                val dayPlans = mutableListOf<DayPlan>()
                val focusSessions = mutableListOf<FocusSession>()
                val mistakes = mutableListOf<MistakeRecord>()
                val dailyReviews = mutableListOf<DailyReview>()
                val weeklyReviews = mutableListOf<WeeklyReview>()
                val resources = mutableListOf<ResourceItem>()

                // Parse StudyTasks
                if (json.has("studyTasks")) {
                    val arr = json.getJSONArray("studyTasks")
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        tasks.add(StudyTask(
                            id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                            dayKey = obj.optString("dayKey", ""),
                            title = obj.optString("title", ""),
                            subject = obj.optString("subject", ""),
                            category = obj.optString("category", ""),
                            status = obj.optString("status", "pending"),
                            estimatedMinutes = if (obj.has("estimatedMinutes") && !obj.isNull("estimatedMinutes")) obj.optInt("estimatedMinutes") else null,
                            actualMinutes = if (obj.has("actualMinutes") && !obj.isNull("actualMinutes")) obj.optInt("actualMinutes") else null,
                            outputNote = obj.optString("outputNote", "")
                        ))
                    }
                }

                // Parse DayPlans
                if (json.has("dayPlans")) {
                    val arr = json.getJSONArray("dayPlans")
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        dayPlans.add(DayPlan(
                            id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                            dayKey = obj.optString("dayKey", ""),
                            stateScore = if (obj.has("stateScore") && !obj.isNull("stateScore")) obj.optInt("stateScore") else null,
                            mainSubject = obj.optString("mainSubject", ""),
                            topTasksText = obj.optString("topTasksText", ""),
                            baselineTasksText = obj.optString("baselineTasksText", ""),
                            bonusTasksText = obj.optString("bonusTasksText", ""),
                            tomorrowFirstAction = obj.optString("tomorrowFirstAction", "")
                        ))
                    }
                }

                // Parse MistakeRecords
                if (json.has("mistakeRecords")) {
                    val arr = json.getJSONArray("mistakeRecords")
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        mistakes.add(MistakeRecord(
                            id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                            subject = obj.optString("subject", ""),
                            chapter = obj.optString("chapter", ""),
                            source = obj.optString("source", ""),
                            questionText = obj.optString("questionText", ""),
                            mistakeType = obj.optString("mistakeType", "concept"),
                            rootCause = obj.optString("rootCause", ""),
                            reviewStatus = obj.optString("reviewStatus", "new")
                        ))
                    }
                }

                // Parse FocusSessions
                if (json.has("focusSessions")) {
                    val arr = json.getJSONArray("focusSessions")
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        focusSessions.add(FocusSession(
                            id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                            subject = obj.optString("subject", ""),
                            plannedMinutes = obj.optInt("plannedMinutes", 25),
                            actualMinutes = if (obj.has("actualMinutes") && !obj.isNull("actualMinutes")) obj.optInt("actualMinutes") else null,
                            distractionCount = obj.optInt("distractionCount", 0),
                            sessionNote = obj.optString("sessionNote", "")
                        ))
                    }
                }

                // Parse DailyReviews
                if (json.has("dailyReviews")) {
                    val arr = json.getJSONArray("dailyReviews")
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        dailyReviews.add(DailyReview(
                            id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                            dayKey = obj.optString("dayKey", ""),
                            completedSummary = obj.optString("completedSummary", ""),
                            unfinishedSummary = obj.optString("unfinishedSummary", ""),
                            biggestProblem = obj.optString("biggestProblem", ""),
                            stateScoreEnd = if (obj.has("stateScoreEnd") && !obj.isNull("stateScoreEnd")) obj.optInt("stateScoreEnd") else null,
                            tomorrowFirstAction = obj.optString("tomorrowFirstAction", "")
                        ))
                    }
                }

                // Parse WeeklyReviews
                if (json.has("weeklyReviews")) {
                    val arr = json.getJSONArray("weeklyReviews")
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        weeklyReviews.add(WeeklyReview(
                            id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                            weekStartKey = obj.optString("weekStartKey", ""),
                            weekEndKey = obj.optString("weekEndKey", ""),
                            totalStudyMinutes = obj.optInt("totalStudyMinutes", 0),
                            completedTaskCount = obj.optInt("completedTaskCount", 0),
                            mistakeCount = obj.optInt("mistakeCount", 0),
                            keyProblemsText = obj.optString("keyProblemsText", ""),
                            nextWeekFocusText = obj.optString("nextWeekFocusText", "")
                        ))
                    }
                }

                // Parse Resources
                if (json.has("resourceItems")) {
                    val arr = json.getJSONArray("resourceItems")
                    for (i in 0 until arr.length()) {
                        val obj = arr.getJSONObject(i)
                        resources.add(ResourceItem(
                            id = obj.optString("id", java.util.UUID.randomUUID().toString()),
                            title = obj.optString("title", ""),
                            subject = obj.optString("subject", ""),
                            type = obj.optString("type", ""),
                            uri = obj.optString("uri", ""),
                            status = obj.optString("status", "unread"),
                            note = obj.optString("note", "")
                        ))
                    }
                }

                val totalCount = tasks.size + dayPlans.size + focusSessions.size + mistakes.size +
                        dailyReviews.size + weeklyReviews.size + resources.size

                _previewState.value = ImportPreviewState.Preview(
                    tasks, dayPlans, focusSessions, mistakes,
                    dailyReviews, weeklyReviews, resources, totalCount
                )
            } catch (e: Exception) {
                _previewState.value = ImportPreviewState.Error("解析备份文件失败：${e.message}")
            }
        }
    }

    fun executeImport(
        tasks: List<StudyTask>,
        dayPlans: List<DayPlan>,
        focusSessions: List<FocusSession>,
        mistakes: List<MistakeRecord>,
        dailyReviews: List<DailyReview>,
        weeklyReviews: List<WeeklyReview>,
        resources: List<ResourceItem>
    ) {
        viewModelScope.launch {
            _isImporting.value = true
            _importResult.value = null
            try {
                val result = repository.importData(
                    tasks = tasks,
                    dayPlans = dayPlans,
                    focusSessions = focusSessions,
                    mistakes = mistakes,
                    dailyReviews = dailyReviews,
                    weeklyReviews = weeklyReviews,
                    resources = resources
                )
                val msg = buildString {
                    append("导入完成：")
                    if (result.created > 0) append("新建 ${result.created} 条")
                    if (result.updated > 0) append("，更新 ${result.updated} 条")
                    if (result.failed > 0) append("，失败 ${result.failed} 条")
                    result.error?.let { append("\n$it") }
                }
                _importResult.value = msg
                _previewState.value = ImportPreviewState.Idle
            } catch (e: Exception) {
                _importResult.value = "导入失败：${e.message}"
            } finally {
                _isImporting.value = false
            }
        }
    }

    fun reset() {
        _previewState.value = ImportPreviewState.Idle
        _importResult.value = null
        _isImporting.value = false
    }
}
