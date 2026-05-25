package com.gaokao.cockpit.viewmodel

import android.app.Application
import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.gaokao.cockpit.data.repository.AppRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.inject.Inject

@HiltViewModel
class BackupViewModel @Inject constructor(
    application: Application,
    private val repository: AppRepository
) : AndroidViewModel(application) {

    private val _exportStatus = MutableStateFlow<String?>(null)
    val exportStatus: StateFlow<String?> = _exportStatus.asStateFlow()

    private val _isExporting = MutableStateFlow(false)
    val isExporting: StateFlow<Boolean> = _isExporting.asStateFlow()

    private val context: Context get() = getApplication()

    fun exportAllData() {
        viewModelScope.launch {
            _isExporting.value = true
            _exportStatus.value = null
            try {
                val json = JSONObject()
                json.put("exportVersion", 1)
                json.put("exportTime", SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.CHINA).format(Date()))

                // Tasks
                val tasksArray = JSONArray()
                val allTasks = mutableListOf<com.gaokao.cockpit.data.model.StudyTask>()
                // Collect tasks for last 30 days
                val calendar = java.util.Calendar.getInstance()
                for (i in 0..30) {
                    val dayKey = com.gaokao.cockpit.data.model.DateKey.keyFor(calendar.time)
                    allTasks.addAll(repository.getTasksForDay(dayKey).first())
                    calendar.add(java.util.Calendar.DAY_OF_YEAR, -1)
                }
                allTasks.distinctBy { it.id }.forEach { task ->
                    tasksArray.put(JSONObject().apply {
                        put("id", task.id)
                        put("title", task.title)
                        put("subject", task.subject)
                        put("category", task.category)
                        put("status", task.status)
                        put("estimatedMinutes", task.estimatedMinutes)
                        put("actualMinutes", task.actualMinutes)
                        put("outputNote", task.outputNote)
                        put("dayKey", task.dayKey)
                    })
                }
                json.put("studyTasks", tasksArray)

                // DayPlans
                val plansArray = JSONArray()
                val allPlans = mutableListOf<com.gaokao.cockpit.data.model.DayPlan>()
                calendar.time = Date()
                for (i in 0..30) {
                    val dayKey = com.gaokao.cockpit.data.model.DateKey.keyFor(calendar.time)
                    repository.getDayPlan(dayKey)?.let { allPlans.add(it) }
                    calendar.add(java.util.Calendar.DAY_OF_YEAR, -1)
                }
                allPlans.distinctBy { it.id }.forEach { plan ->
                    plansArray.put(JSONObject().apply {
                        put("id", plan.id)
                        put("dayKey", plan.dayKey)
                        put("stateScore", plan.stateScore)
                        put("mainSubject", plan.mainSubject)
                        put("topTasksText", plan.topTasksText)
                        put("baselineTasksText", plan.baselineTasksText)
                        put("bonusTasksText", plan.bonusTasksText)
                        put("tomorrowFirstAction", plan.tomorrowFirstAction)
                    })
                }
                json.put("dayPlans", plansArray)

                // Mistakes
                val mistakesArray = JSONArray()
                repository.getAllMistakes().first().forEach { mistake ->
                    mistakesArray.put(JSONObject().apply {
                        put("id", mistake.id)
                        put("subject", mistake.subject)
                        put("chapter", mistake.chapter)
                        put("source", mistake.source)
                        put("questionText", mistake.questionText)
                        put("mistakeType", mistake.mistakeType)
                        put("rootCause", mistake.rootCause)
                        put("reviewStatus", mistake.reviewStatus)
                    })
                }
                json.put("mistakeRecords", mistakesArray)

                // Focus Sessions
                val sessionsArray = JSONArray()
                calendar.time = Date()
                val allSessions = mutableListOf<com.gaokao.cockpit.data.model.FocusSession>()
                for (i in 0..30) {
                    val dayKey = com.gaokao.cockpit.data.model.DateKey.keyFor(calendar.time)
                    allSessions.addAll(repository.getSessionsForDay(dayKey).first())
                    calendar.add(java.util.Calendar.DAY_OF_YEAR, -1)
                }
                allSessions.distinctBy { it.id }.forEach { session ->
                    sessionsArray.put(JSONObject().apply {
                        put("id", session.id)
                        put("subject", session.subject)
                        put("plannedMinutes", session.plannedMinutes)
                        put("actualMinutes", session.actualMinutes)
                        put("distractionCount", session.distractionCount)
                        put("sessionNote", session.sessionNote)
                    })
                }
                json.put("focusSessions", sessionsArray)

                // Daily Reviews
                val reviewsArray = JSONArray()
                calendar.time = Date()
                for (i in 0..30) {
                    val dayKey = com.gaokao.cockpit.data.model.DateKey.keyFor(calendar.time)
                    repository.getDailyReview(dayKey)?.let { review ->
                        reviewsArray.put(JSONObject().apply {
                            put("dayKey", review.dayKey)
                            put("completedSummary", review.completedSummary)
                            put("unfinishedSummary", review.unfinishedSummary)
                            put("biggestProblem", review.biggestProblem)
                            put("stateScoreEnd", review.stateScoreEnd)
                        })
                    }
                    calendar.add(java.util.Calendar.DAY_OF_YEAR, -1)
                }
                json.put("dailyReviews", reviewsArray)

                // Write to file
                val fileName = "gaokao_cockpit_backup_${SimpleDateFormat("yyyyMMdd_HHmmss", Locale.CHINA).format(Date())}.json"
                val file = File(context.cacheDir, fileName)
                file.writeText(json.toString(2))

                // Share via FileProvider
                val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
                val shareIntent = Intent(Intent.ACTION_SEND).apply {
                    type = "application/json"
                    putExtra(Intent.EXTRA_STREAM, uri)
                    putExtra(Intent.EXTRA_SUBJECT, "高考驾驶舱数据备份")
                    putExtra(Intent.EXTRA_TEXT, "高考驾驶舱数据备份文件")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                val chooser = Intent.createChooser(shareIntent, "分享备份文件")
                chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(chooser)

                _exportStatus.value = "备份已生成并分享"
            } catch (e: Exception) {
                _exportStatus.value = "备份失败：${e.message}"
            } finally {
                _isExporting.value = false
            }
        }
    }
}
