package com.example.offline_assist

import android.content.ComponentName
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "offline_assist/app_launcher"
	private val systemChannelName = "offline_assist/system_controls"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"showMatchingAppsChooser" -> {
						val query = call.argument<String>("query") ?: ""
						val title = call.argument<String>("title") ?: "Open with"
						val opened = showMatchingAppsChooser(query, title)
						result.success(opened)
					}
					else -> result.notImplemented()
				}
			}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, systemChannelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"adjustVolume" -> {
						val action = call.argument<String>("action") ?: "increase"
						result.success(adjustVolume(action))
					}
					"adjustBrightness" -> {
						val action = call.argument<String>("action") ?: "increase"
						result.success(adjustBrightness(action))
					}
					"openSystemPanel" -> {
						val panel = call.argument<String>("panel") ?: "settings"
						result.success(openSystemPanel(panel))
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun showMatchingAppsChooser(query: String, title: String): Boolean {
		return try {
			val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
				addCategory(Intent.CATEGORY_LAUNCHER)
			}

			val normalizedQuery = query.trim().lowercase()
			val activities = packageManager.queryIntentActivities(launcherIntent, 0)

			val matchingActivities = if (normalizedQuery.isBlank()) {
				activities
			} else {
				val terms = normalizedQuery.split(" ").filter { it.isNotBlank() }
				activities.filter { info ->
					val label = info.loadLabel(packageManager).toString().lowercase()
					val pkg = info.activityInfo.packageName.lowercase()
					terms.all { term -> label.contains(term) || pkg.contains(term) }
				}
			}

			val targetActivities = if (matchingActivities.isNotEmpty()) {
				matchingActivities
			} else {
				activities
			}

			if (targetActivities.isEmpty()) return false

			val explicitIntents = targetActivities.map { info ->
				Intent(Intent.ACTION_MAIN).apply {
					addCategory(Intent.CATEGORY_LAUNCHER)
					component = ComponentName(
						info.activityInfo.packageName,
						info.activityInfo.name
					)
					addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
				}
			}

			val primary = explicitIntents.first()
			val chooserIntent = Intent.createChooser(primary, title).apply {
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
				if (explicitIntents.size > 1) {
					putExtra(
						Intent.EXTRA_INITIAL_INTENTS,
						explicitIntents.drop(1).toTypedArray()
					)
				}
			}

			startActivity(chooserIntent)
			true
		} catch (_: Exception) {
			false
		}
	}

	private fun adjustVolume(action: String): Boolean {
		return try {
			val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
			when (action) {
				"increase" -> audioManager.adjustStreamVolume(
					AudioManager.STREAM_MUSIC,
					AudioManager.ADJUST_RAISE,
					AudioManager.FLAG_SHOW_UI
				)
				"decrease" -> audioManager.adjustStreamVolume(
					AudioManager.STREAM_MUSIC,
					AudioManager.ADJUST_LOWER,
					AudioManager.FLAG_SHOW_UI
				)
				"mute" -> audioManager.adjustStreamVolume(
					AudioManager.STREAM_MUSIC,
					AudioManager.ADJUST_MUTE,
					AudioManager.FLAG_SHOW_UI
				)
				"max" -> audioManager.setStreamVolume(
					AudioManager.STREAM_MUSIC,
					audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC),
					AudioManager.FLAG_SHOW_UI
				)
				else -> return false
			}
			true
		} catch (_: Exception) {
			false
		}
	}

	private fun adjustBrightness(action: String): String {
		return try {
			if (!Settings.System.canWrite(this)) {
				val intent = Intent(
					Settings.ACTION_MANAGE_WRITE_SETTINGS,
					Uri.parse("package:$packageName")
				).apply {
					addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
				}
				startActivity(intent)
				return "permission_required"
			}

			val current = Settings.System.getInt(
				contentResolver,
				Settings.System.SCREEN_BRIGHTNESS,
				125
			)

			val step = 25
			val next = when (action) {
				"increase" -> (current + step).coerceAtMost(255)
				"decrease" -> (current - step).coerceAtLeast(1)
				else -> current
			}

			val changed = Settings.System.putInt(
				contentResolver,
				Settings.System.SCREEN_BRIGHTNESS,
				next
			)

			if (!changed) return "failed"

			val layoutParams = window.attributes
			layoutParams.screenBrightness = next / 255f
			window.attributes = layoutParams

			"changed"
		} catch (_: Exception) {
			"failed"
		}
	}

	private fun openSystemPanel(panel: String): Boolean {
		return try {
			val intent = when (panel) {
				"wifi" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
						Intent(Settings.Panel.ACTION_WIFI)
					} else {
						Intent(Settings.ACTION_WIFI_SETTINGS)
					}
				}
				"mobile_data" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
						Intent(Settings.Panel.ACTION_INTERNET_CONNECTIVITY)
					} else {
						Intent(Settings.ACTION_DATA_ROAMING_SETTINGS)
					}
				}
				"airplane_mode" -> Intent(Settings.ACTION_AIRPLANE_MODE_SETTINGS)
				"bluetooth" -> Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
				"brightness" -> Intent(Settings.ACTION_DISPLAY_SETTINGS)
				else -> Intent(Settings.ACTION_SETTINGS)
			}.apply {
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			}

			startActivity(intent)
			true
		} catch (_: Exception) {
			false
		}
	}
}
