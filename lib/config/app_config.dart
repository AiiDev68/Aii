// ============================================================
//  ArchiverZ — Application Configuration
//  Single source of truth for branding, base URL, colors,
//  channels, mascot assets, and feature flags.
// ============================================================
import 'package:flutter/material.dart';
import 'api.dart';

class AppConfig {
  AppConfig._();

  // ---------- BRANDING ----------
  static const String appName       = 'ArchiverZ';
  static const String appTagline    = 'Vanguard Archive System';
  static const String appVersion    = '4.0.0';
  static const String appBuild      = '2026.07.02';
  static const String copyrightLine = '© 2026 ArchiverZ · @ArchiveXTeam';

  static const String androidApplicationId = 'com.archiverz.app';
  static const String androidNamespace     = 'com.archiverz.app';
  static const String iosBundleId          = 'com.archiverz.app';

  // ---------- CHANNELS ----------
  static const String telegramChannel = 'https://t.me/ArchiveXTeam';
  static const String telegramDev     = 'https://t.me/pixzarchive';
  static const String telegramSupport = 'https://t.me/ArchiveXTeam';
  static const String buyAccessUrl    = 'https://t.me/pixzarchive';

  // ---------- API / BACKEND ----------
  /// Fallback base URL — PPL API default port is 2000.
  /// Override via remote config (remoteConfigUrl).
  static const String fallbackBaseUrl = 'http://206.189.159.247:2000';

  /// Remote JSON that returns { "x": "<baseUrl>" }.
  static const String remoteConfigUrl =
      'https://raw.githubusercontent.com/pixzdev/ArchiverZ/main/x.json';

  // ---------- MASCOT / ASSETS ----------
  static const String mascotAsset      = 'assets/images/pfp.jpg';
  static const String bannerAsset      = 'assets/images/banner.jpg';
  static const String splashVideoAsset = 'assets/videos/splash.mp4';
  static const String newsVideoAsset   = 'assets/videos/banner.mp4';

  // ---------- TYPOGRAPHY ----------
  static const String fontDisplay = 'Orbitron';
  static const String fontMono    = 'ShareTechMono';

  // ---------- COLOR PALETTE (Deep Space Glass) ----------
  static const Color colorBg        = Color(0xFF070B1A);
  static const Color colorBgSurface = Color(0xFF0E1530);
  static const Color colorPrimary   = Color(0xFF6DD5ED);
  static const Color colorSecondary = Color(0xFFA78BFA);
  static const Color colorAccent    = Color(0xFF60A5FA);
  static const Color colorText      = Color(0xFFE6EBFF);
  static const Color colorTextDim   = Color(0xFF8B95B8);
  static const Color colorDanger    = Color(0xFFFF5C7A);
  static const Color colorSuccess   = Color(0xFF4ADE80);

  // ---------- GLASS CONSTANTS ----------
  static const double glassBlurSigma    = 18.0;
  static const double glassCardRadius   = 22.0;
  static const double glassButtonRadius = 16.0;
  static const double glassBorderWidth  = 0.6;

  // ---------- FEATURE FLAGS ----------
  static const bool featureLocalBanner = true;
  static const bool featureLocalPfp = true;
  static const bool featureSkippableSplash = true;
  static const bool featureChannelButton = true;

  // ---------- RE-EXPORTS for legacy call-sites ----------
  static String get api => Api.api;
  static Future<void> loadGh() => Api.loadGh();
}
