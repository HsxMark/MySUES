package com.hsxmark.mysues

import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the platform fold hardware to Dart.
 *
 * [Sensor.TYPE_HINGE_ANGLE] is streamed over an event channel; the capability
 * probe the debug screen shows comes from the method channel. Both are public
 * APIs - the fold posture itself is left to Dart, which reads it from the
 * window's display features.
 */
class FoldSensorPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var angleChannel: EventChannel

    private val handler = Handler(Looper.getMainLooper())

    private var hingeSensor: Sensor? = null
    private var angleSink: EventChannel.EventSink? = null
    private var lastAngle: Float? = null

    private val sensorManager: SensorManager?
        get() = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager

    private val angleListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent) {
            val angle = event.values.firstOrNull() ?: return
            lastAngle = angle
            angleSink?.success(angle.toDouble())
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        hingeSensor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            sensorManager?.getDefaultSensor(Sensor.TYPE_HINGE_ANGLE)
        } else {
            null
        }

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        angleChannel = EventChannel(binding.binaryMessenger, ANGLE_CHANNEL)
        angleChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                angleSink = events
                startAngleUpdates()
            }

            override fun onCancel(arguments: Any?) {
                angleSink = null
                stopAngleUpdates()
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopAngleUpdates()
        methodChannel.setMethodCallHandler(null)
        angleChannel.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isFoldable" -> result.success(isFoldable())
            "getHingeAngle" -> result.success(lastAngle?.toDouble())
            "getDiagnostics" -> result.success(buildDiagnostics())
            else -> result.notImplemented()
        }
    }

    private fun startAngleUpdates() {
        val manager = sensorManager ?: return
        val sensor = hingeSensor ?: return
        manager.registerListener(angleListener, sensor, SensorManager.SENSOR_DELAY_GAME, handler)
        // The sensor only reports on change, so seed the stream with the last
        // reading to keep a fresh listener from waiting for the next fold.
        lastAngle?.let { angleSink?.success(it.toDouble()) }
    }

    private fun stopAngleUpdates() {
        sensorManager?.unregisterListener(angleListener)
    }

    private fun hingeFeatureFlag(): Boolean? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
        return context.packageManager.hasSystemFeature(
            PackageManager.FEATURE_SENSOR_HINGE_ANGLE,
        )
    }

    /**
     * The device folds when the platform advertises the hinge-angle feature or
     * hands out a hinge-angle sensor. The window's crease, checked on the Dart
     * side, is folded into the same verdict there.
     */
    private fun isFoldable(): Boolean =
        hingeSensor != null || hingeFeatureFlag() == true

    private fun buildDiagnostics(): Map<String, Any?> {
        val manager = sensorManager
        val allSensors = manager?.getSensorList(Sensor.TYPE_ALL).orEmpty()

        return linkedMapOf(
            "isFoldable" to isFoldable(),
            "androidSdk" to Build.VERSION.SDK_INT,
            "deviceModel" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "hingeSensorPresent" to (hingeSensor != null),
            "hingeFeatureFlag" to hingeFeatureFlag(),
            "hingeSensor" to hingeSensor?.let { describe(it) },
            "hingeSensors" to allSensors.filter { it.isHingeAngle() }.map { describe(it) },
            "foldSensors" to allSensors.filter { it.isFoldRelated() }.map { describe(it) },
        )
    }

    private fun Sensor.isHingeAngle(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && type == Sensor.TYPE_HINGE_ANGLE

    private fun Sensor.isFoldRelated(): Boolean {
        if (isHingeAngle()) return true
        val lower = name.lowercase()
        return lower.contains("hinge") || lower.contains("fold")
    }

    private fun describe(sensor: Sensor): Map<String, Any?> = linkedMapOf(
        "name" to sensor.name,
        "vendor" to sensor.vendor,
        "type" to sensor.type,
        "stringType" to sensor.stringType,
        "maxRange" to sensor.maximumRange.toDouble(),
        "resolution" to sensor.resolution.toDouble(),
        "minDelayUs" to sensor.minDelay,
        "isWakeUp" to sensor.isWakeUpSensor,
    )

    private companion object {
        const val METHOD_CHANNEL = "com.hsxmark.mysues/fold"
        const val ANGLE_CHANNEL = "com.hsxmark.mysues/fold/hinge_angle"
    }
}
