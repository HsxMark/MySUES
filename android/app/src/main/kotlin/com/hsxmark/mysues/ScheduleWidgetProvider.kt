package com.hsxmark.mysues

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class ScheduleWidgetProvider : HomeWidgetProvider() {
    private data class CourseEntry(
        val name: String,
        val time: String,
        val endTime: String,
        val loc: String,
        val color: String?
    )

    private data class ScheduleDay(
        val title: String,
        val week: String,
        val courses: List<CourseEntry>
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }

            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
            // 4x2 ≈ 110dp → max 4 courses; 4x4 ≈ 250dp → max 8 courses
            val maxCourses = if (minHeight >= 200) 8 else 4

            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                launchIntent?.let { intent ->
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        widgetId,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }

                val scheduleDay = loadScheduleDay(context, widgetData)
                val hasCache = hasScheduleCache(widgetData)
                val courses = when {
                    scheduleDay != null -> filterUpcomingCourses(scheduleDay.courses)
                    hasCache -> emptyList()
                    else -> filterUpcomingCourses(loadLegacyCourses(widgetData))
                }
                val title = when {
                    scheduleDay != null -> scheduleDay.title
                    hasCache -> localizedString(context, widgetData, R.string.widget_update_required)
                    else -> widgetData.getString(
                        "title",
                        localizedString(context, widgetData, R.string.widget_no_courses)
                    )
                }
                val week = when {
                    scheduleDay != null -> scheduleDay.week
                    hasCache -> ""
                    else -> widgetData.getString("week", "")
                }
                
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_week, week)

                var hasVisibleCourse = false

                for (i in 1..8) {
                    val rowId = context.resources.getIdentifier("course_row_$i", "id", context.packageName)
                    val nameId = context.resources.getIdentifier("course_${i}_name", "id", context.packageName)
                    val timeId = context.resources.getIdentifier("course_${i}_time", "id", context.packageName)
                    val endtimeId = context.resources.getIdentifier("course_${i}_endtime", "id", context.packageName)
                    val locId = context.resources.getIdentifier("course_${i}_loc", "id", context.packageName)
                    val barId = context.resources.getIdentifier("course_${i}_bar", "id", context.packageName)
                    val course = courses.getOrNull(i - 1)

                    if (course == null || i > maxCourses) {
                        setViewVisibility(rowId, View.GONE)
                    } else {
                        hasVisibleCourse = true
                        setViewVisibility(rowId, View.VISIBLE)
                        setTextViewText(nameId, course.name)
                        setTextViewText(timeId, course.time)
                        setTextViewText(endtimeId, course.endTime)
                        setTextViewText(locId, course.loc)

                        val resolvedColor = parseCourseColor(course.color) ?: fallbackColor(i)
                        setInt(barId, "setBackgroundColor", resolvedColor)
                    }
                }

                if (hasVisibleCourse) {
                    setViewVisibility(R.id.empty_message, View.GONE)
                } else {
                    setViewVisibility(R.id.empty_message, View.VISIBLE)
                    setTextViewText(
                        R.id.empty_message,
                        localizedString(context, widgetData, R.string.widget_empty_message)
                    )
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        // Re-render widget when size changes
        val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), widgetData)
    }

    private fun hasScheduleCache(widgetData: SharedPreferences): Boolean {
        val raw = widgetData.getString("schedule_days_v1", null)
        if (raw.isNullOrBlank()) return false

        return try {
            val days = JSONObject(raw).optJSONArray("days")
            days != null && days.length() > 0
        } catch (_: Exception) {
            false
        }
    }

    private fun loadScheduleDay(
        context: Context,
        widgetData: SharedPreferences
    ): ScheduleDay? {
        val raw = widgetData.getString("schedule_days_v1", null)
        if (raw.isNullOrBlank()) return null

        return try {
            val targetDate = SimpleDateFormat("yyyy-MM-dd", Locale.CHINA).format(Date())
            val days = JSONObject(raw).optJSONArray("days") ?: return null

            for (i in 0 until days.length()) {
                val day = days.optJSONObject(i) ?: continue
                if (day.optString("date") != targetDate) continue

                val courseList = mutableListOf<CourseEntry>()
                val courses = day.optJSONArray("courses")
                if (courses != null) {
                    for (j in 0 until courses.length()) {
                        val course = courses.optJSONObject(j) ?: continue
                        val name = course.optString("name")
                        if (name.isBlank()) continue

                        courseList.add(
                            CourseEntry(
                                name = name,
                                time = course.optString("time"),
                                endTime = course.optString("endTime"),
                                loc = course.optString("loc"),
                                color = course.optString("color").takeIf { it.isNotBlank() }
                            )
                        )
                    }
                }

                return ScheduleDay(
                    title = day.optString(
                        "title",
                        localizedString(context, widgetData, R.string.widget_no_courses)
                    ),
                    week = day.optString("week"),
                    courses = courseList
                )
            }
            null
        } catch (_: Exception) {
            null
        }
    }

    private fun loadLegacyCourses(widgetData: SharedPreferences): List<CourseEntry> {
        val courses = mutableListOf<CourseEntry>()
        for (i in 1..8) {
            val name = widgetData.getString("course_${i}_name", "") ?: ""
            if (name.isBlank()) continue

            courses.add(
                CourseEntry(
                    name = name,
                    time = widgetData.getString("course_${i}_time", "") ?: "",
                    endTime = widgetData.getString("course_${i}_endtime", "") ?: "",
                    loc = widgetData.getString("course_${i}_loc", "") ?: "",
                    color = widgetData.getString("course_${i}_color", "")
                )
            )
        }
        return courses
    }

    private fun filterUpcomingCourses(courses: List<CourseEntry>): List<CourseEntry> {
        val now = Calendar.getInstance()
        val currentMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        return courses.filter { course ->
            val endMinutes = parseMinutes(course.endTime)
            endMinutes == null || endMinutes > currentMinutes
        }
    }

    private fun parseMinutes(time: String): Int? {
        val parts = time.split(":")
        if (parts.size != 2) return null

        val hour = parts[0].toIntOrNull() ?: return null
        val minute = parts[1].toIntOrNull() ?: return null
        return hour * 60 + minute
    }

    private fun parseCourseColor(rawColor: String?): Int? {
        if (rawColor.isNullOrBlank()) return null
        val trimmed = rawColor.trim()
        val normalized = if (trimmed.startsWith("#")) trimmed else "#$trimmed"
        if (normalized.length != 7 && normalized.length != 9) return null

        return try {
            Color.parseColor(normalized)
        } catch (_: IllegalArgumentException) {
            null
        }
    }

    private fun fallbackColor(index: Int): Int {
        return if (index % 2 == 1) {
            Color.parseColor("#2ECC71")
        } else {
            Color.parseColor("#F39C12")
        }
    }

    private fun localizedString(
        context: Context,
        widgetData: SharedPreferences,
        resourceId: Int
    ): String {
        val language = widgetData.getString("effective_locale", null)
            ?: Locale.getDefault().language
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(Locale(if (language == "zh") "zh" else "en"))
        return context.createConfigurationContext(configuration).getString(resourceId)
    }
}
