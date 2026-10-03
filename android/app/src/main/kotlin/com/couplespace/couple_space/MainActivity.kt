package com.couplespace.couple_space

import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CompletableFuture

/**
 * Android 原生平台通道（docs/02 §3.2/§3.3、§6，ADR-031）：
 * - couple_space/wifi：WifiManager.MulticastLock（mDNS 组播接收需要）；
 * - couple_space/permissions：按 SDK 过滤并请求运行时权限；
 * - couple_space/bluetooth：BLE 平台通道预留，真机联调在 M3 后期接入。
 */
class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null
    private val pendingPermissions = mutableMapOf<Int, CompletableFuture<List<String>>>()
    private var nextRequestCode = 1000

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerWifiChannel(flutterEngine)
        registerPermissionsChannel(flutterEngine)
        registerBluetoothChannel(flutterEngine)
    }

    private fun registerWifiChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "couple_space/wifi")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquireMulticastLock" -> {
                        val wifi =
                            applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val lock = wifi.createMulticastLock("couple_space").apply {
                            setReferenceCounted(true)
                            acquire()
                        }
                        multicastLock = lock
                        result.success(null)
                    }
                    "releaseMulticastLock" -> {
                        multicastLock?.let { if (it.isHeld) it.release() }
                        multicastLock = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * 运行时权限：Dart 侧给出候选清单，这里只请求当前 SDK 实际需要的
     * 危险权限（NEARBY_WIFI_DEVICES / 位置 / BLUETOOTH_SCAN / CONNECT），
     * 返回本次被授予的权限名。
     */
    private fun registerPermissionsChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "couple_space/permissions")
            .setMethodCallHandler { call, result ->
                if (call.method != "request") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val names = call.argument<List<String>>("permissions") ?: emptyList()
                val needed = names.filter { name ->
                    ActivityCompat.checkSelfPermission(this, name) !=
                        PackageManager.PERMISSION_GRANTED
                }
                if (needed.isEmpty()) {
                    result.success(names)
                    return@setMethodCallHandler
                }
                val future = CompletableFuture<List<String>>()
                val requestCode = nextRequestCode++
                pendingPermissions[requestCode] = future
                ActivityCompat.requestPermissions(this, needed.toTypedArray(), requestCode)
                future.whenComplete { granted, _ -> result.success(granted) }
            }
    }

    /**
     * 蓝牙通道预留：原生 BLE 实现（扫描/连接/分块字节流）在真机联调阶段
     * 接入同一契约（见 lib/platform/bluetooth.dart）。
     */
    private fun registerBluetoothChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "couple_space/bluetooth")
            .setMethodCallHandler { _, result ->
                result.error("not_implemented", "蓝牙原生实现待真机联调接入", null)
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val future = pendingPermissions.remove(requestCode) ?: return
        val granted = permissions
            .zip(grantResults.toList())
            .filter { (_, result) -> result == PackageManager.PERMISSION_GRANTED }
            .map { (name, _) -> name }
        future.complete(granted)
    }
}
