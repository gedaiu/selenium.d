module selenium;

import core.vararg;
import std.stdio;

import vibe.d;

import vibe.http.client;
import vibe.data.json;
import std.typecons;

//hack for development dub
alias Nint = Nullable!int;
Nint a;

/// https://code.google.com/p/selenium/wiki/JsonWireProtocol#/session/:sessionId/url

/**
 * Aggregates all information about a model error status.
 */
class SeleniumException : Exception {
	/**
	 * Create the exception
	 */
	this(string msg, string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null) {
		super(msg);
	}

	this(Json data, string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null) {
		super("Selenium server error: " ~ data.value.message.to!string);
	}
}

enum string[int] StatusDescription = [
	0  : "The command executed successfully.",
	6  : "A session is either terminated or not started",
	7  : "An element could not be located on the page using the given search parameters.",
	8  : "A request to switch to a frame could not be satisfied because the frame could not be found.",
	9  : "The requested resource could not be found, or a request was received using an HTTP method that is not supported by the mapped resource.",
	10 : "An element command failed because the referenced element is no longer attached to the DOM.",
	11 : "An element command could not be completed because the element is not visible on the page.",
	12 : "An element command could not be completed because the element is in an invalid state (e.g. attempting to click a disabled element).",
	13 : "An unknown server-side error occurred while processing the command.",
	15 : "An attempt was made to select an element that cannot be selected.",
	17 : "An error occurred while executing user supplied JavaScript.",
	19 : "An error occurred while searching for an element by XPath.",
	21 : "An operation did not complete before its timeout expired.",
	23 : "A request to switch to a different window could not be satisfied because the window could not be found.",
	24 : "An illegal attempt was made to set a cookie under a different domain than the current page.",
	25 : "A request to set a cookie's value could not be satisfied.",
	26 : "A modal dialog was open, blocking this operation",
	27 : "An attempt was made to operate on a modal dialog when one was not open.",
	28 : "A script did not complete before its timeout expired.",
	29 : "The coordinates provided to an interactions operation are invalid.",
	30 : "IME was not available.",
	31 : "An IME engine could not be started.",
	32 : "Argument was an invalid selector (e.g. XPath/CSS).",
	33 : "A new session could not be created.",
	34 : "Target provided for a move action is out of bounds."
];

enum LocatorStrategy : string {
	ClassName = "class name",
	CssSelector = "css selector",
	Id = "id",
	Name = "name",
	LinkText = "link text",
	PartialLinkText = "partial link text",
	TagName = "tag name",
	XPath = "xpath"
}

enum Browser: string {
	android = "android",
	chrome = "chrome",
	firefox = "firefox",
	htmlunit = "htmlunit",
	internetExplorer = "internet explorer",
	iPhone = "iPhone",
	iPad = "iPad",
	opera = "opera",
	safari = "safari"
}

enum Platform: string {
	windows = "WINDOWS",
	xp = "XP",
	vista = "VISTA",
	mac = "MAC",
	linux = "LINUX",
	unix = "UNIX",
	android = "ANDROID"
}

enum AlertBehaviour: string {
	accept = "accept",
	dismiss = "dismiss",
	ignore = "ignore"
}

enum LogType: string {
	client = "client",
	driver = "driver",
	browser = "browser",
	server = "server"
}

enum TimeoutType: string {
	script = "script",
	implicit = "implicit",
	pageLoad = "page load"
}

enum Orientation: string {
	landscape = "LANDSCAPE",
	portrait = "PORTRAIT"
}

enum MouseButton: int {
	left = 0,
	middle = 1,
	right = 2
}

enum LogLevel: string {
	ALL = "ALL",
	DEBUG = "DEBUG",
	INFO = "INFO",
	WARNING = "WARNING",
	SEVERE = "SEVERE",
	OFF = "OFF"
}

enum CacheStatus {
	uncached = 0,
	idle = 1,
	checking = 2,
	downloading = 3,
	update_ready = 4,
	obsolete = 5
}

struct Capabilities {
	@optional {
		Browser browserName;
		string browserVersion;
		Platform platform;

		bool takesScreenshot;
		bool handlesAlerts;
		bool cssSelectorsEnabled;

		bool javascriptEnabled;
		bool databaseEnabled;
		bool locationContextEnabled;
		bool applicationCacheEnabled;
		bool browserConnectionEnabled;
		bool webStorageEnabled;
		bool acceptSslCerts;
		bool rotatable;
		bool nativeEvents;
		//ProxyObject proxy;
		AlertBehaviour unexpectedAlertBehaviour;
		int elementScrollBehavior;

		@name("webdriver.remote.sessionid")
		string webdriver_remote_sessionid;

		@name("webdriver.remote.quietExceptions")
		bool webdriver_remote_quietExceptions;
	}

	static Capabilities chrome() {
		auto capabilities = Capabilities();
		capabilities.browserName = Browser.chrome;

		return capabilities;
	}
}

struct SessionResponse(T) {

	@optional {
		string sessionId;
		long hCode;
		long status;

		string state;

		T value;
	}
}

struct Size {
	long width;
	long height;
}

struct Position {
	long x;
	long y;
}

struct Cookie {
	string name;
	string value;

	@optional {
		string path;
		string domain;
		bool secure;
		bool httpOnly;
		long expiry;
	}
}

struct ElementLocator {
	LocatorStrategy using;
	string value;
}

struct WebElement {
	string ELEMENT;
}

struct GeoLocation(T) {
	T latitude;
	T longitude;
	T altitude;
}

struct LogEntry {
	long timestamp;
	LogLevel level;
	string message;
}

struct SeleniumSession {
	string serverUrl;

	Capabilities desiredCapabilities;
	Capabilities requiredCapabilities;
	Capabilities session;

	auto timeouts(TimeoutType type, long ms) {
		POST("/timeouts", ["type": Json(type), "ms": Json(ms)]);
		return this;
	}

	auto timeoutsAsyncScript(long ms) {
		POST("/timeouts/async_script", ["ms": Json(ms)]);
		return this;
	}

	auto timeoutsImplicitWait(long ms) {
		POST("/timeouts/implicit_wait", ["ms": Json(ms)]);
		return this;
	}
	auto windowHandle() {
		return GET!string("/window_handle");
	}

	auto windowHandles() {
		return GET!(string[])("/window_handles");
	}

	auto url(string url) {
		POST("/url", ["url": Json(url)]);
		return this;
	}

	auto url() {
		return GET!string("/url");
	}

	auto forward() {
		POST("/forward");
		return this;
	}

	auto back() {
		POST("/back");
		return this;
	}

	auto refresh() {
		POST("/refresh");
		return this;
	}

	auto execute(T = string)(string script, Json args = Json.emptyArray) {
		return POST!T("/execute", [ "script": Json(script), "args": args ]);
	}

	auto executeAsync(T = string)(string script, Json args = Json.emptyArray) {
		return POST!T("/execute_async", [ "script": Json(script), "args": args ]);
	}

	auto screenshot() {
		return GET!string("/screenshot");
	}

	auto imeAvailableEngines() {
		return GET!string("/ime/available_engines");
	}

	auto imeActiveEngine() {
		return GET!string("/ime/active_engine");
	}

	auto imeActivated() {
		return GET!bool("/ime/activated");
	}

	auto imeDeactivate() {
		POST("/ime/deactivate");
		return this;
	}

	auto imeActivate(string engine) {
		POST("/ime/activate", ["engine": engine]);
		return this;
	}

	auto frame(string id) {
		POST("/frame", ["id": id]);
		return this;
	}

	auto frame(long id) {
		POST("/frame", ["id": id]);
		return this;
	}

	auto frame(WebElement element) {
		POST("/frame", element);
		return this;
	}

	auto frameParent() {
		POST("/frame/parent");
		return this;
	}

	auto selectWindow(string name) {
		POST("/window", ["name": name]);
		return this;
	}

	auto closeCurrentWindow() {
		DELETE("/window");
		return this;
	}

	auto windowSize(string handle, Size size) {
		POST("/window/" ~ handle ~ "/size", size);
		return this;
	}

	auto windowSize(string handle) {
		return GET!Size("/window/" ~ handle ~ "/size");
	}

	auto windowPosition(string handle, Position position) {
		POST("/window/" ~ handle ~ "/position", position);
		return this;
	}

	auto windowPosition(string handle) {
		return GET!Position("/window/" ~ handle ~ "/position");
	}

	auto windowMaximize(string handle) {
		POST("/window/" ~ handle ~ "/maximize");
		return this;
	}

	auto cookie() {
		return GET!(Cookie[])("/cookie");
	}

	auto setCookie(Cookie cookie) {
		struct Body {
			Cookie cookie;
		}

		POST("/cookie", Body(cookie));
		return this;
	}

	auto deleteAllCookies() {
		DELETE("/cookie");
		return this;
	}

  auto deleteCookie(string name) {
		DELETE("/cookie/" ~ name);
		return this;
	}

	auto source() {
		return GET!string("/source");
	}

	auto title() {
		return GET!string("/title");
	}

	auto element(ElementLocator locator) {
		return POST!WebElement("/element", locator);
	}

	auto elements(ElementLocator locator) {
		return POST!(WebElement[])("/elements", locator);
	}

	auto activeElement() {
		return POST!WebElement("/element/active");
	}

	auto elementFromElement(string initialElemId, ElementLocator locator) {
		return POST!WebElement("/element/" ~ initialElemId ~ "/element", locator);
	}

	auto elementsFromElement(string initialElemId, ElementLocator locator) {
		return POST!(WebElement[])("/element/" ~ initialElemId ~ "/elements", locator);
	}

	auto clickElement(string elementId) {
		POST("/element/" ~ elementId ~ "/click");
		return this;
	}

	auto submitElement(string elementId) {
		POST("/element/" ~ elementId ~ "/submit");
		return this;
	}

	auto elementText(string elementId) {
		return GET!string("/element/" ~ elementId ~ "/text");
	}

	auto sendKeys(string elementId, string[] value) {
		struct Body {
			string[] value;
		}

		POST("/element/" ~ elementId ~ "/value", Body(value));
		return this;
	}

	auto sendKeysToActiveElement(string[] value) {
		struct Body {
			string[] value;
		}

		POST("/keys", Body(value));
		return this;
	}

	auto elementName(string elementId) {
		return GET!string("/element/" ~ elementId ~ "/name");
	}

	auto clearElementValue(string elementId) {
		POST("/element/" ~ elementId ~ "/clear");
		return this;
	}

	auto elementSelected(string elementId) {
		return GET!bool("/element/" ~ elementId ~ "/selected");
	}

	auto elementEnabled(string elementId) {
		return GET!bool("/element/" ~ elementId ~ "/enabled");
	}

	auto elementValue(string elementId, string attribute) {
		return GET!string("/element/" ~ elementId ~ "/attribute/" ~ attribute);
	}

	auto elementEqualsOther(string firstElementId, string secondElementId) {
		return GET!bool("/element/" ~ firstElementId ~ "/equals/" ~ secondElementId);
	}

	auto elementDisplayed(string elementId) {
		return GET!bool("/element/" ~ elementId ~ "/displayed");
	}

	auto elementLocation(string elementId) {
		return GET!Position("/element/" ~ elementId ~ "/location");
	}

	auto elementLocationInView(string elementId) {
		return GET!Position("/element/" ~ elementId ~ "/location_in_view");
	}

	auto elementSize(string elementId) {
		return GET!Size("/element/" ~ elementId ~ "/size");
	}

	auto elementCssPropertyName(string elementId, string propertyName) {
		return GET!string("/element/" ~ elementId ~ "/css/" ~ propertyName);
	}

	auto orientation() {
		return GET!Orientation("/orientation");
	}

	auto setOrientation(Orientation orientation) {
		struct Body {
			Orientation orientation;
		}

		return POST("/orientation", Body(orientation));
	}

	auto alertText() {
		return GET!string("/alert_text");
	}

	auto setPromptText(string text) {
		POST("/alert_text", ["text": text]);
		return this;
	}

	auto acceptAlert() {
		POST("/accept_alert");
		return this;
	}

	auto dismissAlert() {
		POST("/dismiss_alert");
		return this;
	}

	auto moveTo(Position position) {
		POST("/moveto", ["xoffset": position.x, "yoffset": position.y]);
		return this;
	}

	auto moveTo(string elementId) {
		POST("/moveto", ["element": elementId]);
		return this;
	}

	auto moveTo(string elementId, Position position) {
		struct Body {
			string element;
			long xoffset;
			long yoffset;
		}

		POST("/moveto", Body(elementId, position.x, position.y));
		return this;
	}

	auto click(MouseButton button = MouseButton.left) {
		POST("/click", ["button": button]);
		return this;
	}

	auto buttonDown(MouseButton button = MouseButton.left) {
		POST("/buttondown", ["button": button]);
		return this;
	}

	auto buttonUp(MouseButton button = MouseButton.left) {
		POST("/buttonup", ["button": button]);
		return this;
	}

	auto doubleClick() {
		POST("/doubleclick");
		return this;
	}

	auto touchClick(string elementId) {
		POST("/touch/click", ["element": elementId]);
		return this;
	}

	auto touchDown(Position position) {
		POST("/touch/down", ["x": position.x, "y": position.y]);
		return this;
	}

	auto touchUp(Position position) {
		POST("/touch/up", ["x": position.x, "y": position.y]);
		return this;
	}

	auto touchMove(Position position) {
		POST("/touch/move", ["x": position.x, "y": position.y]);
		return this;
	}

	auto touchScroll(string elementId, Position position) {
		struct Body {
			string element;
			long xoffset;
			long yoffset;
		}

		POST("/touch/scroll", Body(elementId, position.x, position.y));
		return this;
	}

	auto touchScroll(Position position) {
		POST("/touch/scroll", ["xoffset": position.x, "yoffset": position.y]);
		return this;
	}

	auto touchDoubleClick(string elementId) {
		POST("/touch/doubleclick", ["element": elementId]);
		return this;
	}

	auto touchLongClick(string elementId) {
		POST("/touch/longclick", ["element": elementId]);
		return this;
	}

	auto touchFlick(string elementId, Position position, long speed) {
		struct Body {
			string element;
			long xoffset;
			long yoffset;
			long speed;
		}

		POST("/touch/flick", Body(elementId, position.x, position.y, speed));
		return this;
	}

	auto touchFlick(long xSpeed, long ySpeed) {
		POST("/touch/flick", [ "xspeed": xSpeed, "yspeed": ySpeed ]);
		return this;
	}

	auto geoLocation() {
		return GET!(GeoLocation!double)("/location");
	}

	auto setGeoLocation(T)(T location) {
		POST("/location", ["location": location]);
		return this;
	}

	auto localStorage() {
		return GET!(string[])("/local_storage");
	}

	auto setLocalStorage(string key, string value) {
		POST("/local_storage", ["key": key, "value": value]);
		return this;
	}

	auto deleteLocalStorage() {
		DELETE("/local_storage");
		return this;
	}

	auto localStorage(string key) {
		return GET!(string)("/local_storage/key/" ~ key);
	}

	auto deleteLocalStorage(string key) {
		DELETE("/local_storage/key/" ~ key);
		return this;
	}

	auto localStorageSize() {
		return GET!(long)("/local_storage/size");
	}

	auto sessionStorage() {
		return GET!(string[])("/session_storage");
	}

	auto setSessionStorage(string key, string value) {
		POST("/session_storage", ["key": key, "value": value]);
		return this;
	}

	auto deleteSessionStorage() {
		DELETE("/session_storage");
		return this;
	}

	auto sessionStorage(string key) {
		return GET!(string)("/session_storage/key/" ~ key);
	}

	auto deleteSessionStorage(string key) {
		DELETE("/session_storage/key/" ~ key);
		return this;
	}

	auto sessionStorageSize() {
		return GET!(long)("/session_storage/size");
	}

	auto log(LogType logType) {
		return POST!(LogEntry[])("/log", ["type": logType]);
	}

	auto logTypes() {
		return GET!(string[])("/log/types");
	}

	auto applicationCacheStatus() {
		return GET!CacheStatus("/application_cache/status");
	}

	/*
/session/:sessionId/element/:id - not yet implemented in Selenium

/session/:sessionId/log/types
/session/:sessionId/application_cache/status*/


	auto wait(long ms) {
		sleep(ms.msecs);
		return this;
	}

	void disconnect() {
		if(isConnected) {

			makeRequest(HTTPMethod.DELETE,
									serverUrl ~ "/session/" ~ session.webdriver_remote_sessionid);
		}
	}

	private {
		bool isConnected;

		void DELETE(T)(string path, T values = null) {
			if(!isConnected) connect;

			makeRequest(HTTPMethod.DELETE,
									serverUrl ~ "/session/" ~ session.webdriver_remote_sessionid ~ path,
									values);
		}

		void DELETE(string path) {
			if(!isConnected) connect;

			makeRequest(HTTPMethod.DELETE,
									serverUrl ~ "/session/" ~ session.webdriver_remote_sessionid ~ path);
		}

		void POST(T)(string path, T values) {
			if(!isConnected) connect;

			makeRequest(HTTPMethod.POST,
									serverUrl ~ "/session/" ~ session.webdriver_remote_sessionid ~ path,
									values);
		}

		void POST(string path) {
			if(!isConnected) connect;

			makeRequest(HTTPMethod.POST,
									serverUrl ~ "/session/" ~ session.webdriver_remote_sessionid ~ path);
		}

		auto POST(U, T)(string path, T values) {
			if(!isConnected) connect;

			return makeRequest(HTTPMethod.POST,
									serverUrl ~ "/session/" ~ session.webdriver_remote_sessionid ~ path,
									values).deserializeJson!(SessionResponse!U).value;
		}

		auto POST(U)(string path) {
			if(!isConnected) connect;

			return makeRequest(HTTPMethod.POST,
									serverUrl ~ "/session/" ~ session.webdriver_remote_sessionid ~ path)
									.deserializeJson!(SessionResponse!U).value;
		}

		T GET(T)(string path) {
			if(!isConnected) connect;

			return makeRequest(HTTPMethod.GET, serverUrl ~ "/session/" ~ session.webdriver_remote_sessionid ~ path)
									.deserializeJson!(SessionResponse!T).value;
		}

		void connect() {
			session = makeRequest(HTTPMethod.POST, serverUrl ~ "/session", ["desiredCapabilities": desiredCapabilities])
									.deserializeJson!(SessionResponse!Capabilities).value;

			isConnected = true;
		}
	}
}

private Json makeRequest(T)(HTTPMethod method, string path, T data) {
	import vibe.core.core : sleep;
	import core.time : msecs;
	import std.conv : to;

	Json result;
	bool done = false;

	logInfo("REQUEST: %s %s %s", method, path, data.serializeToJson.toPrettyString);

	requestHTTP(path,
		(scope req) {
			req.method = method;
			req.writeJsonBody(data);
		},
		(scope res) {
			result = res.readJson;

			if(res.statusCode == 500) {
				throw new SeleniumException(result);
			} else {
				logInfo("Response: %d %s", res.statusCode, result.toPrettyString);
			}
			done = true;
		}
	);

	return result;
}


private Json makeRequest(HTTPMethod method, string path) {
	import vibe.core.core : sleep;
	import core.time : msecs;
	import std.conv : to;

	Json result;
	bool done = false;

	logInfo("REQUEST: %s %s", method, path);

	requestHTTP(path,
		(scope req) {
			req.method = method;
		},
		(scope res) {
			result = res.readJson;

			if(res.statusCode == 500) {
				throw new SeleniumException(result);
			} else {
				logInfo("Response: %d %s", res.statusCode, result.toPrettyString);
			}
			done = true;
		}
	);

	return result;
}
