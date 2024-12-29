package com.rdbt.eb3at;

import io.flutter.embedding.android.FlutterActivity;

import io.flutter.embedding.engine.FlutterEngine;


import android.view.View;
import android.os.Build;
import android.os.Bundle;
import android.content.Intent;
import io.flutter.plugin.common.MethodCall;

import androidx.core.view.WindowCompat;
import android.view.WindowManager;

import android.Manifest;
import android.content.pm.PackageManager;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
//import io.flutter.plugins.GeneratedPluginRegistrant;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends FlutterActivity {

    private static final int PERMISSION_REQUEST_CODE = 10001;
    private Result methodResult;
    private static final String CHANNEL = "com.example.app/directories";


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
//        GeneratedPluginRegistrant.registerWith(this);



        MethodChannel channel = new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), "no_snaps_allowed");
        channel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("preventScreenshots")) {
//                Boolean prevent = call.argument("prevent") != null && call.argument("prevent");
                Boolean prevent = call.argument("prevent");

                if (call.argument("prevent") != null && prevent) {
                    getWindow().setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE);
                } else {
                    getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
                }
            }
        });

        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), "com.pyramids/permissions")
                .setMethodCallHandler(new MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall call, Result result) {
                        methodResult = result;
                        if (call.method.equals("checkPermissions")) {
                            checkPermissions();
                        } else {
                            result.notImplemented();
                        }
                    }
                });

        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("getAppDirectory")) {
                                getAppDirectory(result);
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }



    private void checkPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermission(android.Manifest.permission.READ_MEDIA_IMAGES);
        } else {
            requestPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE, android.Manifest.permission.WRITE_EXTERNAL_STORAGE);
        }
    }

    private void requestPermission(String... permissions) {
        if (!hasPermissions(permissions)) {
            ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE);
        } else {
            methodResult.success(true);
        }
    }

    private boolean hasPermissions(String... permissions) {
        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                methodResult.success(true);
            } else {
                methodResult.success(false);
            }
        }
    }

    //get app directory
    private void getAppDirectory(MethodChannel.Result result) {
        String path = getApplicationContext().getExternalFilesDir(null).getAbsolutePath();
        if (path != null) {
            result.success(path);
        } else {
            result.error("UNAVAILABLE", "Directory not available", null);
        }
    }
}

