package com.debojyoti.animated_icon_picker

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(true)
                    "getCurrent" -> result.success(currentIconId())
                    "setIcon" -> {
                        val id = call.arguments as? String
                            ?: call.argument<String>("id")
                        if (id == null || id !in ALIASES) {
                            result.error("unknown_icon", "Unknown icon id: $id", null)
                            return@setMethodCallHandler
                        }
                        try {
                            setIcon(id)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("set_icon_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun aliasComponent(id: String) =
        ComponentName(packageName, "$packageName.${ALIASES.getValue(id)}")

    /** The id whose activity-alias is currently enabled. */
    private fun currentIconId(): String {
        for (id in ALIASES.keys) {
            val state = packageManager.getComponentEnabledSetting(aliasComponent(id))
            val enabled = state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                // DEFAULT means "as declared in the manifest", where only the
                // default alias is enabled.
                (state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && id == DEFAULT_ID)
            if (enabled) return id
        }
        return DEFAULT_ID
    }

    /**
     * Enables the chosen alias, then disables the rest, so there is never a
     * moment without a launcher entry. DONT_KILL_APP keeps this process alive.
     *
     * The launcher picks the change up on its own schedule: some launchers
     * refresh the icon immediately, others only after a short delay (often a
     * few seconds) or the next time the home screen reloads.
     */
    private fun setIcon(id: String) {
        val pm = packageManager
        pm.setComponentEnabledSetting(
            aliasComponent(id),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        for (other in ALIASES.keys) {
            if (other == id) continue
            pm.setComponentEnabledSetting(
                aliasComponent(other),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    companion object {
        private const val CHANNEL = "animated_icon_picker/app_icon"
        private const val DEFAULT_ID = "default"

        /** Dart icon id -> <activity-alias> name in AndroidManifest.xml. */
        private val ALIASES = linkedMapOf(
            "default" to "MainActivityDefault",
            "blush" to "MainActivityBlush",
            "grape" to "MainActivityGrape",
            "midnight" to "MainActivityMidnight",
            "mono" to "MainActivityMono",
            "ocean" to "MainActivityOcean",
        )
    }
}
