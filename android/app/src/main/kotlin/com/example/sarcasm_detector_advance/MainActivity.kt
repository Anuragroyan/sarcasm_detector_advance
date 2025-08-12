package com.example.sarcasm_detector_advance

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import ai.onnxruntime.*
import ai.onnxruntime.OrtSession.SessionOptions
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "sarcasm.detector.channel"
    private lateinit var env: OrtEnvironment
    private lateinit var session: OrtSession

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        try {
            env = OrtEnvironment.getEnvironment()
            val sessionOptions = SessionOptions()

            // Copy ONNX model from assets to cache dir
            val modelInputStream = assets.open("sarcasm_model.onnx")
            val modelFile = File(cacheDir, "sarcasm_model.onnx")
            FileOutputStream(modelFile).use { output ->
                modelInputStream.copyTo(output)
            }

            // Load model from file path
            session = env.createSession(modelFile.absolutePath, sessionOptions)

        } catch (e: Exception) {
            e.printStackTrace()
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "predictSarcasm") {
                val text = call.argument<String>("text") ?: ""
                val prediction = runOnnxModel(text)
                result.success(prediction)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun runOnnxModel(text: String): String {
        return try {
            // Dummy input for now
            val inputIds = longArrayOf(0, 314, 1929, 328, 2)
            val attentionMask = longArrayOf(1, 1, 1, 1, 1)

            val inputIdTensor = OnnxTensor.createTensor(env, arrayOf(inputIds))
            val attentionMaskTensor = OnnxTensor.createTensor(env, arrayOf(attentionMask))

            val inputs = mapOf(
                "input_ids" to inputIdTensor,
                "attention_mask" to attentionMaskTensor
            )

            val output = session.run(inputs)
            val result = output[0].value as Array<FloatArray>

            val sarcasmScore = result[0][1]
            if (sarcasmScore > 0.5f) "Sarcastic" else "Not Sarcastic"

        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }
}
