module test;

import selenium;
import std.stdio;
import vibe.data.json;

import std.datetime;

unittest {
  auto url1 = "http://www.amazon.com/All-Light-We-Cannot-See/dp/1476746583/";
  auto url2 = "http://www.amazon.com/The-Boys-Boat-Americans-Olympics/dp/0143125478/";

  auto session = SeleniumSession("http://127.0.0.1:4444/wd/hub", Capabilities.chrome);

  session.timeouts(TimeoutType.script, 10_000);
  session.timeouts(TimeoutType.implicit, 10_000);
  session.timeouts(TimeoutType.pageLoad, 10_000);

  string handle = session.windowHandle;
  writeln("windowHandle: ",  handle);
  writeln("windowHandles: ", session.windowHandles);

  assert(session.url(url1).url == url1);
  assert(session.url(url1).wait(1000).url(url2).back.wait(1000).url == url1);
  assert(session.forward.wait(1000).url == url2);
  assert(session.refresh.wait(1000).url == url2);

  assert(session.execute!int("return 1+1") == 2);

  Json params = Json.emptyArray;
  params ~= 1;
  params ~= 2;
  assert(session.execute!int("return arguments[0] + arguments[1]", params) == 3);

  assert(session.executeAsync!int("arguments[0](1+1)") == 2);
  assert(session.executeAsync!int("arguments[2](arguments[0] + arguments[1])", params) == 3);

  session.screenshot;

  /* not suported by chrome
  writeln("available_engines: ", session.imeAvailableEngines);
  writeln("active_engine: ", session.imeActiveEngine);
  writeln("active_engine: ", session.imeActivated);
  writeln("active_engine: ", session.imeDeactivate);
  writeln("active_engine: ", session.imeActivate);
  */

  session.frame;
  //session.frameParent;
  //session.selectWindow("testOpen");
  //session.closeCurrentWindow();

  assert(session.windowSize(handle, Size(400, 500)).windowSize(handle) == Size(400, 500));
  assert(session.windowPosition(handle, Position(100, 200)).windowPosition(handle) == Position(100, 200));

  session.windowMaximize(handle);
  assert(session.windowSize(handle) != Size(400, 500));
  assert(session.windowPosition(handle) != Position(100, 200));

  assert(session.cookie.length > 0);

  auto cookie = Cookie("test", "value");
  session.setCookie(cookie);
  session.deleteAllCookies;

  session.disconnect;
}
