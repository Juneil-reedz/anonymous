package com.anonymous.anonymous

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.anonymous.app/share"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareToFacebookStory", "shareToInstagramStory" -> {
                        val bytes = call.argument<ByteArray>("imageBytes")
                        if (bytes == null) {
                            result.error("INVALID_ARGS", "imageBytes required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            // Save image to cache dir so FileProvider can serve it
                            val dir = File(cacheDir, "story_share")
                            dir.mkdirs()
                            val file = File(dir, "anon_card.png")
                            file.writeBytes(bytes)

                            val contentUri: Uri = FileProvider.getUriForFile(
                                this,
                                "${packageName}.provider",
                                file
                            )

                            val action = if (call.method == "shareToFacebookStory")
                                "com.facebook.stories.ADD_TO_STORY"
                            else
                                "com.instagram.share.ADD_TO_STORY"

                            val intent = Intent(action).apply {
                                setDataAndType(contentUri, "image/png")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }

                            if (packageManager.resolveActivity(intent, 0) != null) {
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(false) // app not installed
                            }
                        } catch (e: Exception) {
                            result.error("SHARE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
