module selenium.workflow;

import std.stdio;

import std.conv;
import std.exception;
import std.traits;
import std.meta;
import std.algorithm.searching;
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

	auto goTo(string url) {
		session.navigation.url = url;
		return this;
	}

	public bool hasStep(string name)() {
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

	auto opDispatch(string name, T...)(T props) if(name != "define" && name != "hasStep") {
		enforce(hasStep!name, "The step `" ~ name ~ "` is undefined.");

		string stringParams = "";

		static if(T.length == 0) {
			logInfo("=> " ~ name);
		} else {
			foreach(prop; props) {
				stringParams ~= " " ~ prop.to!string;
			}

			logInfo("=> " ~ name ~ ":" ~ stringParams);
		}

		static if(!is(U == void*)) {
			static if(__traits(hasMember, cls, name)) {
				alias expectedParam = Parameters!(__traits(getMember, cls, name));

				static if(expectedParam.length == props.length + 1 && is(expectedParam[0] == typeof(session))) {
					alias finalProps = AliasSeq!(session, props);
				} else {
					alias finalProps = props;
				}

				static if(is(ReturnType!(__traits(getMember, cls, name)) == void)) {
					__traits(getMember, cls, name)(finalProps);
					return this;
				} else {
					return __traits(getMember, cls, name)(finalProps);
				}
			} else static if(!is(T == void*)) {
				return child.opDispatch!name(props);
			}
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

	auto workflow = define(session).define!"productPage"(productPage).define(new Steps);

	workflow
		.goTo("https://www.amazon.com")
		.opDispatch!"search"("Maggy London Womens")
		.selectResultNumber(2)
		.opDispatch!"productPage".check.isPresent;

	auto chk = workflow
		.goTo("https://www.amazon.com")
		.search("Maggy London Womens")
		.selectFirstResult
		.check.productPage.isPresent;
}
