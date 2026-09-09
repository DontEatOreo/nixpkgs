{
  stdenv,
  wxwidgets_3_3,
}:
wxwidgets_3_3.override {
  withPrivateFonts = true;
  withWebKit = true;
  withEGL = true;
  # Disable wxWidgets' debug dialogs
  withDebug = false;
  # MacDarkMode.mm extends internal Objective-C classes via categories and
  # includes wx/private/jsscriptwrapper.h for WebView JavaScript execution
  withVisibility = !stdenv.hostPlatform.isDarwin;
  withPrivateHeaders = stdenv.hostPlatform.isDarwin;
}
