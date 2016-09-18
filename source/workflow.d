module selenium.workflow;

import std.stdio;

import std.conv;
import std.exception;
import std.traits;
import std.meta;
import std.algorithm.searching;
import std.algorithm.iteration;
import std.range;

import selenium.session;
import selenium.api;


import std.string;
import std.conv;

import vibe.core.log;

class SeleniumPage {
	protected {
		immutable SeleniumSession session;
	}

	this(immutable SeleniumSession session) {
		this.session = session;
	}

	bool isPresent() {
		return true;
	}
}

class WorkflowCheck(T, U) : Workflow!(T, U) {

	this(T child, U cls) {
		super(child, cls);
	}

	auto opDispatch(string name, T...)(T props) if(name != "define") {
		alias member = child.opDispatch!name;

		static if(is(ReturnType!member == bool)) {
			assert(child.opDispatch!name(props), "Check `" ~ name ~ "`` faield.");
			return this;
		} else {
			auto val = child.opDispatch!name(props);

			return new WorkflowCheck!(typeof(val), void*)(val, null);
		}
	}
}

class WorkflowNamed(string workflowName, T ,U) : Workflow!(T, U) {

	this(T child, U cls) {
		super(child, cls);
	}

	auto opDispatch(string name, T...)(T props) if(name != "define" && name != "hasStep") {
		static if(workflowName == name) {
			return new Workflow!(typeof(this), U)(this, cls);
		} else {
			return super.opDispatch!name(props);
		}
	}

	bool hasStep(string name)() {
		static if(workflowName == name) {
			return true;
		} else {
			return child.hasStep!name;
		}
	}
}

class Workflow(T, U) {
	immutable SeleniumSession session;
	T child;
	U cls;

	this(immutable SeleniumSession session) {
		this.session = session;
	}

	static if(!is(T == void*)) {
		this(T child, U cls) {
			this(child.session);

			this.child = child;
			this.cls = cls;
		}
	}

	bool hasStep(string name)() {
		static if(!is(U == void*) && __traits(hasMember, cls, name)) {
			return true;
		} else static if(!is(T == void*)) {
			return child.hasStep!name;
		} else {
			return false;
		}
	}

	auto check()() {
		logInfo("=> check");

		static if(is(T == void*)) {
			assert(false, "Can not check void workflows.");
		} else static if(!__traits(isSame, TemplateOf!(T), WorkflowCheck)) {
			return new WorkflowCheck!(typeof(this), void*)(this, null);
		} else {
			assert(false, "Can not check this workflow.");
		}
	}

	private void logDispatch(string name, T...)(T props) {
		string stringParams = "";

		static if(T.length == 0) {
			logInfo("=> " ~ name);
		} else {
			foreach(prop; props) {
				stringParams ~= " " ~ prop.to!string;
			}

			logInfo("=> " ~ name ~ ":" ~ stringParams);
		}
	}

	private auto callClassMember(string name, T...)(T props) {
		alias expectedParam = Parameters!(__traits(getMember, cls, name));

		enum diffParameters = expectedParam.length - props.length;

		static assert(diffParameters <= 2, "Can not call `" ~ name ~ "` due invalid number of parameters");

		static if(diffParameters) {
			assert(is(expectedParam[0] == typeof(session)) || is(expectedParam[0] == typeof(this)),
				"First parameter expected of type `immutable SeleniumSession` or `Workflow`");

			static if(is(expectedParam[0] == typeof(session))) {
				alias prepend = AliasSeq!(session);
			} else {
				alias prepend = AliasSeq!(this);
			}
		} else {
			alias prepend = AliasSeq!();
		}

		alias finalProps = AliasSeq!(prepend, props);

		static if(is(ReturnType!(__traits(getMember, cls, name)) == void)) {
			__traits(getMember, cls, name)(finalProps);
			return this;
		} else {
			return __traits(getMember, cls, name)(finalProps);
		}
	}

	auto opDispatch(string name, T...)(T props) if(name != "define" && name != "hasStep") {
		enforce(hasStep!name, "The step `" ~ name ~ "` is undefined.");
		logDispatch!name(props);

		static assert(!is(U == void*) && !is(T == void*), "Can not call method `" ~ name ~ "` on `void` child and class.");

		enum classHasMember = __traits(hasMember, cls, name);

		static if(classHasMember) {
			return callClassMember!name(props);
		} else static if(!is(T == void*)) {
			return child.opDispatch!name(props);
		}
	}
}

auto define(immutable SeleniumSession session) {
	return new Workflow!(void*, void*)(session);
}

auto define(string name, T, U)(T workflow, U obj) {
	return new WorkflowNamed!(name, T, U)(workflow, obj);
}

auto define(T, U)(T workflow, U obj) {
	return new Workflow!(T, U)(workflow, obj);
}

class WebNavigation {
	void goTo(immutable SeleniumSession session, string url) {
		session.navigation.url = url;
	}
}

struct HistoryCue(T) {
	alias E = ReturnType!T;

	private {
		immutable SeleniumSession session;
		T callback;
		E result;

		ulong index = 0;

		string expectedUrl;
	}

	this(immutable SeleniumSession session, T callback) {
		this.session = session;
		this.callback = callback;

		this.expectedUrl = session.navigation.url;
		this.result = callback(session, index);
	}

	E front() {
		return result;
	}

	E moveFront() {
		return result;
	}

	void popFront() {
		index++;

		while(this.expectedUrl != session.navigation.url) {
			session.navigation.back;
		}

		writeln("pop front ", session.navigation.url);

		result = callback(session, index);
	}

	bool empty() {
		return result is null;
	}
}

auto historyCue(T)(immutable SeleniumSession session, T callback) {
	return HistoryCue!T(session, callback);
}

@("some workflow examples")
unittest
{
	auto session = new immutable SeleniumSession("http://127.0.0.1:4444/wd/hub",
			Capabilities.chrome);

	class Steps {
		void search(immutable SeleniumSession session, string value)
		{
			session.findOne(ElementLocator(LocatorStrategy.Id,
					"twotabsearchtextbox")).click.sendKeys(value);

			session.findOne(ElementLocator(LocatorStrategy.CssSelector,
					".nav-search-submit input")).click;
		}

		void selectResultNumber(immutable SeleniumSession session, int index)
		{
			session.findMany(ElementLocator(LocatorStrategy.CssSelector,
					"li.s-result-item"))[index].findOne(ElementLocator(LocatorStrategy.CssSelector,
					"a.s-access-detail-page")).click;
		}

		void selectFirstResult(immutable SeleniumSession session) {
			selectResultNumber(session, 0);
		}

		auto eachResult(immutable SeleniumSession session) {
			return session.historyCue(&this.getResult);
		}

		auto getResult(immutable SeleniumSession session, ulong index) {
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

					writeln("Result Page " , session.navigation.url);
				}

				string getTitle() {
					writeln("get title ", session.findOne("productTitle".idLocator).text);
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

	SeleniumPage productPage = new ProductPage(session);

	auto workflow = define(session)
										.define!"productPage"(productPage)
										.define(new Steps)
										.define(new WebNavigation);
/*
	workflow
		.opDispatch!"goTo"("https://www.amazon.com")
		.opDispatch!"search"("Maggy London Womens")
		.selectResultNumber(2)
		.productPage
			.check
				.isPresent;

	workflow
		.goTo("https://www.amazon.com")
		.search("Maggy London Womens")
		.selectFirstResult
		.check
			.productPage.isPresent;*/

		workflow
			.goTo("https://www.amazon.com")
			.search("Maggy London Womens")
			.eachResult
				.map!(a => a.getTitle.canFind("Maggy London Women's"))
				.reduce!((a, b) => a && b);
}
