#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Names the one instance of the app a user may have running. It lives in the
// Local namespace, so it is per login session rather than machine-wide: the
// store it protects is in the user's own data directory, and another user on
// the same machine has a store of their own.
constexpr const wchar_t kSingleInstanceMutexName[] =
    L"Local\\app.wvl.score.single-instance";

// The class every Flutter runner window registers (see win32_window.cpp) and
// the title this one is created with below. Both together, so that another
// Flutter app that happens to be open is never the one brought forward.
constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
constexpr const wchar_t kWindowTitle[] = L"score";

// Brings the window of the instance that is already running to the front.
// It may not have one yet, if it was started a moment ago; then there is
// nothing to show, and this instance still leaves.
void ShowRunningInstance() {
  HWND existing = ::FindWindow(kWindowClassName, kWindowTitle);
  if (existing == nullptr) {
    return;
  }
  if (::IsIconic(existing)) {
    ::ShowWindow(existing, SW_RESTORE);
  }
  ::SetForegroundWindow(existing);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // One instance at a time. Two would open the same store file, and each
  // rewrites that file from what it holds in memory when it compacts, so
  // whatever the other one had written since (queued edits, a fresh token)
  // would be lost; both would also want the same port for the sign-in
  // callback. A second launch shows the first one's window and exits instead.
  // The handle is held until the process ends, which is what releases it.
  HANDLE single_instance =
      ::CreateMutex(nullptr, FALSE, kSingleInstanceMutexName);
  if (single_instance != nullptr &&
      ::GetLastError() == ERROR_ALREADY_EXISTS) {
    ShowRunningInstance();
    ::CloseHandle(single_instance);
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(kWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (single_instance != nullptr) {
    ::CloseHandle(single_instance);
  }
  return EXIT_SUCCESS;
}
