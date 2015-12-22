module selenium;

import std.stdio;
import vibe.d;

import vibe.http.client;
import vibe.data.json;

/// https://code.google.com/p/selenium/wiki/JsonWireProtocol#/session/:sessionId/url

/**
 * Aggregates all information about a model error status.
 */
class SeleniumException : Exception {
	/**
	 * Create the exception
	 */
	this(string msg, string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null) {
		super(msg, file, line, next);
	}

	this(Json data, string file = __FILE__, ulong line = cast(ulong)__LINE__, Throwable next = null) {
		super("Selenium server error: " ~ data.value.message.to!string, file, line, next);
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

struct SessionResponse(T) {

	@optional {
		string sessionId;
		long hCode;
		long status;

		string state;

		T value;
	}
}

struct SeleniumSession {
	string serverUrl;

	Capabilities desiredCapabilities;
	Capabilities requiredCapabilities;

	auto url(string target) {
		POST!"/url"(["url": target]);

		return this;
	}

	string url() {
		return GET!("/url", string);
	}

	private {
		bool isConnected;
		Capabilities session;

		void POST(string path, T)(T values) {
			if(!isConnected) connect;

			makeRequest(HTTPMethod.POST,
									serverUrl ~ "/session/" ~ session.webdriver_remote_sessionid ~ path,
									values);
		}

		T GET(string path, T)() {
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

private Json makeRequest(T)(HTTPMethod method, string path, T data = null) {
	import vibe.core.core : sleep;
	import core.time : msecs;
	import std.conv : to;

	Json result;
	bool done = false;

	logInfo("REQUEST: %s %s %s", method, path, data.to!string);

	requestHTTP(path,
		(scope req) {
			req.method = method;

			if(data !is null) {
				req.writeJsonBody(data);
			}
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
