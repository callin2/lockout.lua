# Lockout

Lockout is a [Knockout](http://knockoutjs.com/) clone in [Lua](http://www.lua.org/)

## Features

### Observables
* observable
* observableArray is not implemented
* subscribable
* computed
* extenders

### Bindings
* Lockout is not for DOM operation. It does not offer binding feature.

## An Example
	local lo = require("lockout")
	
    local underlyingObservable = lo.observable(1);
    local dependent1 = lo.computed(function ()
		return underlyingObservable() + 1;
	end);
	
    local dependent2 = lo.computed(function ()
		return dependent1() + 1;
	end);

    assert(3 == dependent2());

    underlyingObservable(11);

    assert(13 == dependent2());

## Getting it

The source code can be found at:

	https://github.com/callin2/lockout.lua.git
	
This project uses [Underscore.lua](http://mirven.github.com/underscore.lua/) for table operation. you will have to install Underscore.lua first

## Running your tests
This project uses [telescope](https://github.com/norman/telescope) for its specs. If you want to run the specs, you will have to install telescope first.

    tsc -f lockout_test.lua

### Observable Examples
	local lo = require("lockout")
	
	local instance = lo.observable();
    local notifiedValues = {};
    instance:subscribe(function (value)
        notifiedValues[#notifiedValues+1]=value;
    end);

    instance('A');
    instance('B');

    assert_equal(2,#notifiedValues)
    assert_equal('A',notifiedValues[1])
    assert_equal('B',notifiedValues[2])

### Subscribable Examples
	local lo = require("lockout")

	local instance = lo.subscribable();
    local notifiedValue = nil;
    instance:subscribe(function (value)  notifiedValue = value; end, "myEvent");

    instance:notifySubscribers(123, "unrelatedEvent");
    assert_equal(nil, notifiedValue);

    instance:notifySubscribers(456, "myEvent");
    assert_equal(456,notifiedValue)


## Author

[callin 임창진](mailto:callin2@gmail.com)

Please feel free to email me bug reports or feature requests.

## Acknowledgements


## License ##

The MIT License

Copyright (c) 2009-2011 [임창진](mailto:callin2@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.