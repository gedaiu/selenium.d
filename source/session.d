module selenium.session;

import selenium.api;
import std.stdio;
import vibe.data.json;

immutable class SeleniumSession
{
	SeleniumApi api;

	this(string serverUrl, Capabilities desiredCapabilities,
			Capabilities requiredCapabilities = Capabilities(), Capabilities session = Capabilities())
	{
		auto connector = new SeleniumApiConnector(serverUrl,
				desiredCapabilities, requiredCapabilities, session);
		api = connector.api;
	}

	@property
	{
		immutable(SeleniumWindow) currentWindow()
		{
			return new immutable SeleniumWindow(api, this);
		}

		immutable(SeleniumNavigation) navigation()
		{
			return new immutable SeleniumNavigation(api, this);
		}

		immutable(SeleniumCookie) cookie()
		{
			return new immutable SeleniumCookie(api, this);
		}

		auto windowHandles()
		{
			return api.windowHandles;
		}
	}

	immutable(Element) findOne(immutable ElementLocator locator)
	{
		return Element.findOne(api, locator);
	}

	immutable(Element)[] findMany(immutable ElementLocator locator)
	{
		return Element.findMany(api, locator);
	}

	immutable(Element) getActiveElement()
	{
		return Element.getActive(api);
	}

	auto frame(string id)
	{
		api.frame(id);
		return this;
	}

	auto frame(long id)
	{
		api.frame(id);
		return this;
	}

	auto frame(WebElement element)
	{
		api.frame(element);
		return this;
	}

	auto frameParent()
	{
		api.frameParent;
		return this;
	}

	void close()
	{
		api.connection.disconnect;
	}
}

class SeleniumCookie
{
	immutable
	{
		SeleniumApi api;
		SeleniumSession parent;
	}

	this(immutable SeleniumApi api, immutable SeleniumSession parent) immutable
	{
		this.api = api;
		this.parent = parent;
	}

	@property immutable
	{
		auto all() {
			return api.cookie;
		}

		auto set(string name, string value) {
			api.setCookie(Cookie(name, value));
			return parent;
		}

		auto set(Cookie cookie) {
			api.setCookie(cookie);
			return parent;
		}

		auto deleteAll() {
			api.deleteAllCookies();
			return parent;
		}

		auto deleteByName(string name) {
			api.deleteCookie(name);
			return parent;
		}
	}
}

immutable class SeleniumNavigation
{
	immutable
	{
		SeleniumApi api;
		SeleniumSession parent;
	}

	this(immutable SeleniumApi api, immutable SeleniumSession parent)
	{
		this.api = api;
		this.parent = parent;
	}

	@property
	{
		auto url(string url)
		{
			api.url(url);
			return parent;
		}

		auto url()
		{
			return api.url;
		}

		auto forward()
		{
			api.forward;
			return parent;
		}

		auto back()
		{
			api.back;
			return parent;
		}

		auto refresh()
		{
			api.refresh;
			return parent;
		}
	}
}

immutable class SeleniumWindow
{
	SeleniumApi api;
	SeleniumSession parent;

	this(immutable SeleniumApi api, immutable SeleniumSession parent)
	{
		this.api = api;
		this.parent = parent;
	}

	immutable
	{
		auto select(string name)
		{
			api.selectWindow(name);
			return parent;
		}

		auto handle()
		{
			return api.windowHandle;
		}

		auto size()
		{
			return api.windowSize;
		}

		auto size(Size value)
		{
			api.windowSize(value);
			return parent;
		}

		auto maximize()
		{
			api.windowMaximize;
			return parent;
		}

		auto screenshot()
		{
			return api.screenshot;
		}

		auto close()
		{
			api.windowClose;
			return parent;
		}

		auto source()
		{
			return api.source;
		}

		auto title()
		{
			return api.title;
		}

		auto execute(T = string)(string script, Json args = Json.emptyArray)
		{
			return api.execute!T(script, args);
		}

		auto executeAsync(T = string)(string script, Json args = Json.emptyArray)
		{
			return api.executeAsync!T(script, args);
		}
	}
}

@("Session currentWindow")
unittest
{
	auto session = new immutable SeleniumSession("http://127.0.0.1:4444/wd/hub", Capabilities.chrome);

	session.currentWindow.size = Size(400, 500);
	assert(session.currentWindow.size == Size(400, 500));

	session.currentWindow.maximize;

	session.currentWindow.screenshot;
	session.currentWindow.source;
	session.currentWindow.title;

	session.currentWindow.close;

	session.close;
}

class Element
{
	alias opEquals = Object.opEquals;

	private immutable
	{
		SeleniumApi api;
		WebElement element;
	}

	this(immutable SeleniumApi api, immutable WebElement element) immutable
	{
		this.api = api;
		this.element = element;
	}

	static
	{
		immutable(Element) findOne(immutable SeleniumApi api, immutable ElementLocator locator)
		{
			return new immutable Element(api, api.element(locator));
		}

		immutable(Element)[] findMany(immutable SeleniumApi api, immutable ElementLocator locator)
		{
			immutable(Element)[] elements;

			foreach (webElement; api.elements(locator))
			{
				elements ~= new immutable Element(api, webElement);
			}

			return elements;
		}

		immutable(Element) getActive(immutable SeleniumApi api)
		{
			return new immutable Element(api, api.activeElement);
		}

		void sendKeysToActive(immutable SeleniumApi api, const string[] value)
		{
			api.sendKeysToActiveElement(value);
		}
	}

	inout
	{
		immutable(Element) findOne(ElementLocator locator)
		{
			return new immutable Element(api, api.elementFromElement(element.ELEMENT, locator));
		}

		immutable(Element)[] findMany(ElementLocator locator)
		{
			immutable(Element)[] elements;

			foreach (webElement; api.elementsFromElement(element.ELEMENT, locator))
			{
				elements ~= new immutable Element(api, webElement);
			}

			return elements;
		}

		inout(Element) click()
		{
			api.clickElement(element.ELEMENT);

			return this;
		}

		inout(Element) submit()
		{
			api.submitElement(element.ELEMENT);
			return this;
		}

		inout(Element) sendKeys(string[] value)
		{
			api.sendKeys(element.ELEMENT, value);
			return this;
		}

		inout(Element) sendKeys(string value)
		{
			return sendKeys([value]);
		}

		inout(Element) clear()
		{
			api.clearElementValue(element.ELEMENT);
			return this;
		}

		@property
		{
			string text()
			{
				return api.elementText(element.ELEMENT);
			}

			string name()
			{
				return api.elementName(element.ELEMENT);
			}

			bool isSelected()
			{
				return api.elementSelected(element.ELEMENT);
			}

			bool isEnabled()
			{
				return api.elementSelected(element.ELEMENT);
			}

			bool isDisplayed()
			{
				return api.elementDisplayed(element.ELEMENT);
			}

			Position position()
			{
				return api.elementLocation(element.ELEMENT);
			}

			Position positionInView()
			{
				return api.elementLocationInView(element.ELEMENT);
			}

			Size size()
			{
				return api.elementSize(element.ELEMENT);
			}

			string seleniumId() inout
			{
				return element.ELEMENT;
			}
		}

		string attribute(string name)
		{
			return api.elementValue(element.ELEMENT, name);
		}

		string elementCssPropertyName(string name)
		{
			return api.elementValue(element.ELEMENT, name);
		}

		bool opEquals(ref Element other) const
		{
			return api.elementEqualsOther(element.ELEMENT, other.seleniumId);
		}

		bool opEquals(Element other) const
		{
			return api.elementEqualsOther(element.ELEMENT, other.seleniumId);
		}
	}
}
/+
@("Session find one element")
unittest
{
	auto session = new immutable SeleniumSession("http://127.0.0.1:4444/wd/hub", Capabilities.chrome);
	session.navigation.url("https://www.amazon.com/All-Light-We-Cannot-See/dp/1476746583/");

	session.findOne(ElementLocator(LocatorStrategy.ClassName, "contributorNameID")).click;

	assert(session.navigation.url
			== "https://www.amazon.com/Anthony-Doerr/e/B000APOX62/ref=dp_byline_cont_book_1");

	session.close;
}

@("Session find many elements")
unittest
{
	auto session = new immutable SeleniumSession("http://127.0.0.1:4444/wd/hub", Capabilities.chrome);
	session.navigation.url("https://www.amazon.com/All-Light-We-Cannot-See/dp/1476746583/");

	assert(session.findMany(ElementLocator(LocatorStrategy.TagName, "img")).length > 0);

	session.close;
}
+/
