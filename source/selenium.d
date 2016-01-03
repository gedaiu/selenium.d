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

enum TimeoutType: string {
	script = "script",
	implicit = "implicit",
	pageLoad = "page load"
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

	auto frame(Json id = null) {
		POST("/frame", ["id": id]);
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

	auto element(ElementLocator elem) {
		return POST!WebElement("/element", elem);
	}

	auto elements(ElementLocator elem) {
		return POST!(WebElement[])("/elements", elem);
	}

	auto activeElement() {
		return POST!WebElement("/element/active");
	}

	auto elementFromElement(string initialElem, ElementLocator elem) {
		return POST!WebElement("/element/" ~ initialElem ~ "/element", elem);
	}
	/*
/session/:sessionId/element/:id
/session/:sessionId/element/:id/element
/session/:sessionId/element/:id/elements
/session/:sessionId/element/:id/click
/session/:sessionId/element/:id/submit
/session/:sessionId/element/:id/text
/session/:sessionId/element/:id/value
/session/:sessionId/keys
/session/:sessionId/element/:id/name
/session/:sessionId/element/:id/clear
/session/:sessionId/element/:id/selected
/session/:sessionId/element/:id/enabled
/session/:sessionId/element/:id/attribute/:name
/session/:sessionId/element/:id/equals/:other
/session/:sessionId/element/:id/displayed
/session/:sessionId/element/:id/location
/session/:sessionId/element/:id/location_in_view
/session/:sessionId/element/:id/size
/session/:sessionId/element/:id/css/:propertyName
/session/:sessionId/orientation
/session/:sessionId/alert_text
/session/:sessionId/accept_alert
/session/:sessionId/dismiss_alert
/session/:sessionId/moveto
/session/:sessionId/click
/session/:sessionId/buttondown
/session/:sessionId/buttonup
/session/:sessionId/doubleclick
/session/:sessionId/touch/click
/session/:sessionId/touch/down
/session/:sessionId/touch/up
session/:sessionId/touch/move
session/:sessionId/touch/scroll
session/:sessionId/touch/scroll
session/:sessionId/touch/doubleclick
session/:sessionId/touch/longclick
session/:sessionId/touch/flick
session/:sessionId/touch/flick
/session/:sessionId/location
/session/:sessionId/local_storage
/session/:sessionId/local_storage/key/:key
/session/:sessionId/local_storage/size
/session/:sessionId/session_storage
/session/:sessionId/session_storage/key/:key
/session/:sessionId/session_storage/size
/session/:sessionId/log
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
