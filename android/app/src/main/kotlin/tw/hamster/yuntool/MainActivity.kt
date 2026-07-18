package tw.hamster.yuntool

import android.app.LocaleManager
import android.os.Build
import android.os.LocaleList
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Android 13+ per-app locale bridge: keeps the in-app language picker and
    // the system "App languages" setting in sync (the system stores the value).
    private val CHANNEL = "tw.hamster.yuntool/locale"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                when (call.method) {
                    "isSupported" -> result.success(false)
                    "get" -> result.success(null)
                    "set" -> result.success(false)
                    else -> result.notImplemented()
                }
                return@setMethodCallHandler
            }
            val localeManager = getSystemService(LocaleManager::class.java)
            when (call.method) {
                "isSupported" -> result.success(true)
                "get" -> {
                    val locales = localeManager.applicationLocales
                    result.success(if (locales.isEmpty) null else locales.get(0).toLanguageTag())
                }
                "set" -> {
                    val tag = call.arguments as String?
                    localeManager.applicationLocales =
                        if (tag.isNullOrEmpty()) LocaleList.getEmptyLocaleList()
                        else LocaleList.forLanguageTags(tag)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
