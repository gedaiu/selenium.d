module selenium.session;

import selenium.api;
import std.stdio;

class SeleniumSession
{
	immutable SeleniumApi api;

	this(string serverUrl, Capabilities desiredCapabilities,
			Capabilities requiredCapabilities = Capabilities(), Capabilities session = Capabilities())
	{

		auto connector = new SeleniumApiConnector(serverUrl, desiredCapabilities, requiredCapabilities, session);
		api = connector.api;
	}

	SeleniumWindow currentWindow()
	{
		return new SeleniumWindow(api);
	}
}

class SeleniumWindow
{
	protected const
	{
		SeleniumApi api;
	}

	this(const SeleniumApi api)
	{
		this.api = api;
	}

	auto size()
	{
		return api.windowSize;
	}

	void size(Size value)
	{
		api.windowSize(value);
	}

	void maximize()
	{
		api.windowMaximize;
	}

	auto screenshot()
	{
		api.screenshot;
	}

	void close()
	{
		api.windowClose;
	}

	auto source()
	{
		api.source;
	}

	auto title()
	{
		api.title;
	}
}

unittest
{
	auto session = new SeleniumSession("http://127.0.0.1:4444/wd/hub", Capabilities.chrome);

	session.currentWindow.size = Size(400, 500);
	assert(session.currentWindow.size == Size(400, 500));

	session.currentWindow.maximize;

	session.currentWindow.screenshot;
	session.currentWindow.source;
	session.currentWindow.title;

	session.currentWindow.close;
}

class Element
{
	alias opEquals = Object.opEquals;

	private immutable {
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

	inout {
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
