module selenium.session;

import selenium.api;
import std.stdio;

class SeleniumSession
{
	SeleniumApi api;

	this(string serverUrl, Capabilities desiredCapabilities,
			Capabilities requiredCapabilities = Capabilities(), Capabilities session = Capabilities())
	{

		api = new SeleniumApi(serverUrl, desiredCapabilities, requiredCapabilities, session);
	}

	SeleniumWindow currentWindow()
	{
		return new SeleniumWindow(api);
	}
}

class SeleniumWindow
{
	protected
	{
		SeleniumApi api;
	}

	this(SeleniumApi api)
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

	private const {
		SeleniumApi api;
		WebElement element;
	}

	this(SeleniumApi api, WebElement element)
	{
		this.api = api;
		this.element = element;
	}

	static
	{
		Element findOne(SeleniumApi api, ElementLocator locator)
		{
			return new Element(api, api.element(locator));
		}

		Element[] findMany(SeleniumApi api, ElementLocator locator)
		{
			Element[] elements;

			foreach (webElement; api.elements(locator))
			{
				elements ~= new Element(api, webElement);
			}

			return elements;
		}

		Element getActive(SeleniumApi api)
		{
			return new Element(api, api.activeElement);
		}

		void sendKeysToActive(SeleniumApi api, string[] value)
		{
			api.sendKeysToActiveElement(value);
		}
	}

	Element findOne(ElementLocator locator)
	{
		return new Element(api, api.elementFromElement(element.ELEMENT, locator));
	}

	Element[] findMany(ElementLocator locator)
	{
		Element[] elements;

		foreach (webElement; api.elementsFromElement(element.ELEMENT, locator))
		{
			elements ~= new Element(api, webElement);
		}

		return elements;
	}

	Element click()
	{
		api.clickElement(element.ELEMENT);

		return this;
	}

	Element submit()
	{
		api.submitElement(element.ELEMENT);
		return this;
	}

	Element sendKeys(string[] value)
	{
		api.sendKeys(element.ELEMENT, value);
		return this;
	}

	Element clear()
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
