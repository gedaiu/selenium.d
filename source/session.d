module selenium.session;

import selenium.api;


class SeleniumSession {

  SeleniumApi api;

  this(string serverUrl,
      Capabilities desiredCapabilities,
      Capabilities requiredCapabilities = Capabilities(),
      Capabilities session = Capabilities()) {

    api = SeleniumApi(serverUrl, desiredCapabilities, requiredCapabilities, session);
  }

  SeleniumWindow currentWindow() {
    return new SeleniumWindow(api.windowHandle, api);
  }

}

class SeleniumWindow {
  string handle;
  SeleniumApi api;

  this(string handle, SeleniumApi api) {
    this.handle = handle;
    this.api = api;
  }

  Size size() {
    return api.windowSize(handle);
  }

  void size(Size value) {
    api.windowSize(handle, value);
  }

  Position position() {
    return api.windowPosition(handle);
  }

  void position(Position value) {
    api.windowPosition(handle, value);
  }

  void maximize() {
    api.windowMaximize(handle);
  }
}

unittest {
  auto session = new SeleniumSession("http://127.0.0.1:4444/wd/hub", Capabilities.chrome);

  session.currentWindow.size = Size(400, 500);
  assert(session.currentWindow.size == Size(400, 500));

  session.currentWindow.position = Position(100, 200);
  assert(session.currentWindow.position == Position(100, 200));

  session.currentWindow.maximize;
}
