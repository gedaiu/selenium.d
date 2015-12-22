module seleniumTests;

import selenium;
import std.stdio;


unittest {
  auto url = "http://www.amazon.com/All-Light-We-Cannot-See/dp/1476746583/ref=zg_bs_books_3";

	assert(SeleniumSession("http://127.0.0.1:4444/wd/hub", Capabilities.chrome).url(url).url == url);
}
