import std.stdio;

import std.string;
import std.conv;
import std.algorithm;
import core.thread;

import selenium.workflow;
import selenium.session;
import selenium.api;

version(unittest) {
} else {
	void main()
	{
	}
}

class StackOverflowSearch {

	void search(immutable SeleniumSession session, string value)
	{
		"#search input[name=q]".cssLocator.findOneIn(session).click.sendKeys(value ~ "\n");
	}

	void selectResultNumber(immutable SeleniumSession session, long index) {
		getAllResults(session)[index].click;
	}

	void selectFirstResult(immutable SeleniumSession session) {
		selectResultNumber(session, 1);
	}

	auto getAllResults(immutable SeleniumSession session) {
		return ".search-result .result-link a".cssLocator.findMany(session);
	}

	auto eachResult(immutable SeleniumSession session) {
		return session.historyCue(&this.getResult);
	}

	auto getResult(immutable SeleniumSession session, ulong index) {
		auto list = getAllResults(session);

		if(index >= list.length) {
			return null;
		}

		auto position = list[index].position;

		session.currentWindow.execute("window.scrollTo(" ~ position.x.to!string ~ "," ~ position.y.to!string ~ ")");
		list[index].click;

		return new QuestionPage(session);
	}
}

class QuestionPage : SeleniumPage {

	this(immutable SeleniumSession session) {
		super(session);
	}

	string getTitle() {
		return "question-header".idLocator.findOneIn(session).text;
	}

	bool titleContains(string text) {
		return getTitle.toLower.indexOf(text) != -1;
	}

	override bool isPresent() {
		throw new Exception("not implemented");
	}
}

@("Check all search results")
unittest {
	auto session = new immutable SeleniumSession("http://127.0.0.1:4444/wd/hub", Capabilities.chrome);
	scope(exit) session.close;

	auto questionPage = new QuestionPage(session);

	auto workflow = define(session)
										.define!"questionPage"(questionPage)
										.define(new StackOverflowSearch)
										.define(new WebNavigation);

	workflow
		.goTo("http://stackoverflow.com/")
		.search("Selenium")
		.eachResult
			.all!(page => page.titleContains("selenium"))
				.isTrue;
}
