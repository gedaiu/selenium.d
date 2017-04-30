module amazontests;

import std.conv;
import std.string;
import std.algorithm;

import selenium.session;
import selenium.workflow;
import selenium.api;

import trial.step;

class Steps {
	void search(immutable SeleniumSession session, string value)
	{
		auto step = Step("Search " ~ value);
		session.findOne(ElementLocator(LocatorStrategy.Id,
				"twotabsearchtextbox")).click.sendKeys(value);

		session.findOne(ElementLocator(LocatorStrategy.CssSelector,
				".nav-search-submit input")).click;
	}

	void selectResultNumber(immutable SeleniumSession session, int index)
	{
		auto step = Step("Select result number " ~ index.to!string);
		session.findMany(ElementLocator(LocatorStrategy.CssSelector,
				"li.s-result-item"))[index].findOne(ElementLocator(LocatorStrategy.CssSelector,
				"a.s-access-detail-page")).click;
	}

	void selectFirstResult(immutable SeleniumSession session) {
		auto step = Step("Select the first result");
		selectResultNumber(session, 0);
	}

	auto eachResult(immutable SeleniumSession session) {
		return session.historyCue(&this.getResult);
	}

	auto getResult(immutable SeleniumSession session, ulong index) {
		auto step = Step("Get result " ~ index.to!string);

		auto list = session.findMany("li.s-result-item a.s-access-detail-page".cssLocator);

		if(index >= list.length) {
			return null;
		}

		auto element = list[index];
		auto position = element.position;

		session.currentWindow.execute("window.scrollTo(" ~ position.x.to!string ~ "," ~ position.y.to!string ~ ")");
		element.click;

		class ResultPage {
			private immutable SeleniumSession session;

			this(immutable SeleniumSession session) {
				this.session = session;
			}

			string getTitle() {
				auto step = Step("get title: " ~ session.findOne("productTitle".idLocator).text);
				return session.findOne("productTitle".idLocator).text;
			}
		}

		return new ResultPage(session);
	}
}

class ProductPage : SeleniumPage {
	this(immutable SeleniumSession session) {
		super(session);
	}

	override bool isPresent() {
		return session.findOne("#title".cssLocator).text.indexOf("Maggy London Women's") != -1;
	}
}

auto getWorkflow(immutable SeleniumSession session) {
	SeleniumPage productPage = new ProductPage(session);

	return define(session)
										.define!"productPage"(productPage)
										.define(new Steps)
										.define(new WebNavigation);
}



@("Check the second result on amazon.com")
unittest {
	auto session = new immutable SeleniumSession("http://127.0.0.1:4444/wd/hub",
			Capabilities.chrome);
	scope(exit) session.close;

	getWorkflow(session)
		.goTo("https://www.amazon.com")
		.search("Maggy London Womens")
		.selectResultNumber(2)
		.productPage
			.check
				.isPresent;
}

@("Check the first result on amazon.com")
unittest {
	auto session = new immutable SeleniumSession("http://127.0.0.1:4444/wd/hub",
			Capabilities.chrome);
	scope(exit) session.close;

	getWorkflow(session)
		.goTo("https://www.amazon.com")
		.search("Maggy London Womens")
		.selectFirstResult
		.check
			.productPage.isPresent;
}

@("Check all the results from amazon.com")
unittest {
	auto session = new immutable SeleniumSession("http://127.0.0.1:4444/wd/hub",
			Capabilities.chrome);
	scope(exit) session.close;

	getWorkflow(session)
			.goTo("https://www.amazon.com")
			.search("Maggy London Womens")
			.eachResult
				.map!(a => a.getTitle.canFind("Maggy London Women's"))
				.reduce!((a, b) => a && b);
}
