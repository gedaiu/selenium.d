module test;

import selenium;
import std.stdio;
import vibe.data.json;

import std.datetime;

unittest {
  auto url1 = "http://www.amazon.com/All-Light-We-Cannot-See/dp/1476746583/";
  auto url2 = "http://www.amazon.com/The-Boys-Boat-Americans-Olympics/dp/0143125478/";

  auto session = SeleniumSession("http://127.0.0.1:4444/wd/hub", Capabilities.chrome);
/+
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
  session.deleteCookie("test");
  session.deleteAllCookies;
+/
  assert(session.source != "");
  session.url("http://wfmu.org/playlists/LM");
  assert(session.title == "WFMU: This Is The Modern World with Trouble: Playlists and Archives");
  auto elem = ElementLocator(LocatorStrategy.ClassName, "ui-dialog");
  session.element(elem);
  auto elem2 = ElementLocator(LocatorStrategy.CssSelector, ".showList ul");
  session.elements(elem2);
  session.element(elem2);

  auto elem3 = ElementLocator(LocatorStrategy.TagName, "li");
  session.elementsFromElement(session.element(elem2).ELEMENT, elem3);

  session.activeElement;

  auto elem4 = ElementLocator(LocatorStrategy.LinkText, "See the playlist");
  session.clickElement(session.element(elem4).ELEMENT);
  assert(session.url == "http://wfmu.org/playlists/shows/64336");

  session.url("http://szabobogdan.com/ro.php");
/+  auto elem5 = ElementLocator(LocatorStrategy.ClassName, "mailForm");
  session.submitElement(session.element(elem5).ELEMENT);
+/
  auto elem6 = ElementLocator(LocatorStrategy.CssSelector, "#contact h2");
  assert(session.elementText(session.element(elem6).ELEMENT) == "Contact");

  auto elem7 = ElementLocator(LocatorStrategy.Id, "formName");
  auto idElem7 = session.element(elem7).ELEMENT;
  session.sendKeys(idElem7, ["a", "l", "e"]);

  session.sendKeysToActiveElement(["2", "t"]);

  session.elementValue(idElem7, "value");

  assert(session.elementName(idElem7) == "input");

  session.clearElementValue(idElem7);
  assert(session.elementValue(idElem7, "value") == "");

  session.url(url1);
  auto elem8 = ElementLocator(LocatorStrategy.CssSelector, "#quantity option");
  auto idElem8 = session.element(elem8).ELEMENT;
  assert(session.elementSelected(idElem8));

  assert(session.elementEnabled(idElem8));

  auto elem9 = ElementLocator(LocatorStrategy.CssSelector, "#quantity");
  auto elem9bis = ElementLocator(LocatorStrategy.XPath, ".//*[@id='quantity']");
  auto idElem9 = session.element(elem9).ELEMENT;
  auto idElem9bis = session.element(elem9bis).ELEMENT;
  assert(session.elementEqualsOther(idElem9, idElem9bis));
  //session.disconnect;
}
