# Stock Flutter release keeps. The app has no reflection of its own;
# plugins register through GeneratedPluginRegistrant, kept below.
# If a tagged AAB misbehaves on first install, flip minify/shrink
# off in build.gradle.kts and rebuild (documented rollback).
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class com.spotnik.pontual.** { *; }
