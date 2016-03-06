module selenium.session;

import selenium.api;
import std.stdio;


class SeleniumSession {
  SeleniumApi api;

  this(string serverUrl,
      Capabilities desiredCapabilities,
      Capabilities requiredCapabilities = Capabilities(),
      Capabilities session = Capabilities()) {

    api = new SeleniumApi(serverUrl, desiredCapabilities, requiredCapabilities, session);
  }

  SeleniumWindow currentWindow() {
    return new SeleniumWindow(api);
  }
}

class SeleniumWindow {
  protected {
    SeleniumApi api;
  }

  this(SeleniumApi api) {
    this.api = api;
  }

  auto size() {
    return api.windowSize;
  }

  void size(Size value) {
    api.windowSize(value);
  }

  void maximize() {
    api.windowMaximize;
  }

  auto screenshot() {
    api.screenshot;
  }

  void close() {
    api.windowClose;
  }

  auto source() {
    api.source;
  }

  auto title() {
    api.title;
  }
}

unittest {
  auto session = new SeleniumSession("http://127.0.0.1:4444/wd/hub", Capabilities.chrome);

  session.currentWindow.size = Size(400, 500);
  assert(session.currentWindow.size == Size(400, 500));

  session.currentWindow.maximize;

  session.currentWindow.screenshot;
  session.currentWindow.source;
  session.currentWindow.title;

  session.currentWindow.close;
}
