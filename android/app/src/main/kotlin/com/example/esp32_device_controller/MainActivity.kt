package com.example.esp32_device_controller

import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "esp32_controller/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "saveToDownloads" -> {

                    try {
                        val fileName =
                            call.argument<String>("fileName")

                        val data =
                            call.argument<ByteArray>("data")

                        if (fileName == null || data == null) {
                            result.error(
                                "INVALID_DATA",
                                "File name or data is missing.",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        saveToDownloads(
                            fileName,
                            data
                        )

                        result.success(
                            "File saved to Downloads."
                        )

                    } catch (e: Exception) {

                        result.error(
                            "SAVE_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun saveToDownloads(
        fileName: String,
        data: ByteArray
    ) {

        val resolver = contentResolver

        val contentValues = ContentValues().apply {

            put(
                MediaStore.Downloads.DISPLAY_NAME,
                fileName
            )

            put(
                MediaStore.Downloads.MIME_TYPE,
                "text/csv"
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(
                    MediaStore.Downloads.IS_PENDING,
                    1
                )
            }
        }

        val uri = resolver.insert(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            contentValues
        )

        if (uri == null) {
            throw Exception(
                "Unable to create file in Downloads."
            )
        }

        try {

            resolver.openOutputStream(uri).use { outputStream ->

                if (outputStream == null) {
                    throw Exception(
                        "Unable to open file."
                    )
                }

                outputStream.write(data)
                outputStream.flush()
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {

                val updateValues = ContentValues().apply {

                    put(
                        MediaStore.Downloads.IS_PENDING,
                        0
                    )
                }

                resolver.update(
                    uri,
                    updateValues,
                    null,
                    null
                )
            }

        } catch (e: Exception) {

            // Remove incomplete file if saving fails.
            resolver.delete(
                uri,
                null,
                null
            )

            throw e
        }
    }
}