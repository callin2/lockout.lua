local ko = require"lockout"

context('Subscribable', function()
    test('Should declare that it is subscribable', function ()
        local instance = ko.subscribable();
		assert_equal(true, ko.isSubscribable(instance))

    end)

    test('Should be able to notify subscribers', function ()
        local instance = ko.subscribable();
        local notifiedValue;
        instance:subscribe(function (value)  notifiedValue = value; end);
        instance:notifySubscribers(123);
        assert_equal(123, notifiedValue);
    end)

    test('Should be able to unsubscribe', function ()
        local instance = ko.subscribable();
        local notifiedValue;
        local subscription = instance:subscribe(function (value)  notifiedValue = value; end);
        subscription:dispose();
        instance:notifySubscribers(123);
        assert_equal(nil,notifiedValue);
    end)

    test([[Should be able to specify a 'self' pointer for the callback]], function ()
        local model = {
            someProperty= 123,
            change= function(self, arg)
				assert_equal('notifiedValue', arg)
				assert_equal(123, self.someProperty)
			end
        };
        local instance = ko.subscribable();
        instance:subscribe(model,'change');
        instance:notifySubscribers('notifiedValue');
    end)

    test('Should not notify subscribers after unsubscription, even if the unsubscription occurs midway through a notification cycle', function()
--~         -- This spec represents the unusual case where during notification, subscription1's callback causes subscription2 to be disposed.
--~         -- Since subscription2 was still active at the start of the cycle, it is scheduled to be notified. This spec verifies that
--~         -- even though it is scheduled to be notified, it does not get notified, because the unsubscription just happened.
        local instance = ko.subscribable();
		local subscription2

		local subscription1 = instance:subscribe(function()
            subscription2:dispose();
        end);
        local subscription2wasNotified = false;
        subscription2 = instance:subscribe(function()
            subscription2wasNotified = true;
        end);

        instance:notifySubscribers('ignored');
        assert_equal(false,subscription2wasNotified);
    end)

    test([[Should be able to notify subscribers for a specific 'event']], function ()
        local instance = ko.subscribable();
        local notifiedValue = nil;
        instance:subscribe(function (value)  notifiedValue = value; end, "myEvent");

        instance:notifySubscribers(123, "unrelatedEvent");
        assert_equal(nil, notifiedValue);

        instance:notifySubscribers(456, "myEvent");
        assert_equal(456,notifiedValue)
    end)

    test([[Should be able to unsubscribe for a specific 'event']], function ()
        local instance = ko.subscribable();
        local notifiedValue;
        local subscription = instance:subscribe(function (value)  notifiedValue = value; end, "myEvent");
        subscription:dispose();
        instance:notifySubscribers(123, "myEvent");
        assert_equal(nil, notifiedValue)
    end)

    test([[Should be able to subscribe for a specific 'event' without being notified for the default event]], function ()
        local instance = ko.subscribable();
        local notifiedValue;
        local subscription = instance:subscribe(function (value)  notifiedValue = value; end, "myEvent");
        instance:notifySubscribers(123);
        assert_equal(nil,notifiedValue);
    end)

    test('Should be able to retrieve the number of active subscribers', function()
        local instance = ko.subscribable();
        instance:subscribe(function() end);
        instance:subscribe(function() end, "someSpecificEvent");
        assert_equal(2, instance:getSubscriptionsCount());
    end)

    test('Should be possible to replace notifySubscribers with a custom handler', function()
        local instance =  ko.subscribable();
        local interceptedNotifications = {};
        instance:subscribe(function() error("Should not notify subscribers by default once notifySubscribers is overridden") end);
        instance.notifySubscribers = function(self, newValue, eventName)
            interceptedNotifications[#interceptedNotifications+1]= { eventName= eventName, value= newValue };
        end
        instance:notifySubscribers(123, "myEvent");

        assert_equal(1,#interceptedNotifications)
        assert_equal('myEvent', interceptedNotifications[1].eventName)
        assert_equal(123,interceptedNotifications[1].value)
    end)
end)



----------------


context('Observable', function()
    test('Should be subscribable', function ()
        local instance = ko.observable();
        assert_equal(true, ko.isSubscribable(instance))
    end)

    test('Should advertise that instances are observable', function ()
        local instance = ko.observable();
        assert_equal(true, ko.isObservable(instance));
    end)

    test('Should be able to write values to it', function ()
        local instance = ko.observable();
        instance(123);
    end)

--~     test('Should be able to write to multiple observable properties on a model object using chaining syntax', function()
--~         local model = {
--~             prop1= ko.observable(),
--~             prop2= ko.observable()
--~         };
--~         model.prop1('A').prop2('B');

--~         assert_equal(model.prop1()).should_be('A');
--~         assert_equal(model.prop2()).should_be('B');
--~     end)

    test('Should advertise that instances can have values written to them', function ()
        local instance = ko.observable(function () end);
        assert_equal(true, ko.isWriteableObservable(instance))
    end)

    test('Should be able to read back most recent value', function ()
        local instance = ko.observable();
        instance(123);
        instance(234);
        assert_equal(234,instance())
    end)

    test('Should initially have undefined value', function ()
        local instance = ko.observable();
        assert_equal(nil,instance())
    end)

    test('Should be able to set initial value as constructor param', function ()
        local instance = ko.observable('Hi!');
        assert_equal('Hi!', instance())
    end)

    test('Should notify subscribers about each new value', function ()
        local instance = ko.observable();
        local notifiedValues = {};
        instance:subscribe(function (value)
            notifiedValues[#notifiedValues+1]=value;
        end);

        instance('A');
        instance('B');

        assert_equal(2,#notifiedValues)
        assert_equal('A',notifiedValues[1])
        assert_equal('B',notifiedValues[2])
    end)

    test('Should be able to tell it that its value has mutated, at which point it notifies subscribers', function ()
        local instance = ko.observable();
        local notifiedValues = {};
        instance:subscribe(function (value)
            notifiedValues[#notifiedValues+1] = value.childProperty;
        end);

        local someUnderlyingObject = { childProperty = "A" };
        instance(someUnderlyingObject);
        assert_equal(1,#notifiedValues);
        assert_equal('A', notifiedValues[1])

        someUnderlyingObject.childProperty = "B";
        instance:valueHasMutated();
        assert_equal(2,#notifiedValues);
        assert_equal('B',notifiedValues[2]);
    end)

    test('Should notify "beforeChange" subscribers before each new value', function ()
        local instance = ko.observable('A');
        local notifiedValues = {};
        instance:subscribe(function (value)
            u_.push(notifiedValues, value);
        end,"beforeChange");

        instance('B');
        instance('C');

        assert_equal(2,#notifiedValues)
        assert_equal('A',notifiedValues[1])
        assert_equal('B',notifiedValues[2])
    end)

    test('Should be able to tell it that its value will mutate, at which point it notifies "beforeChange" subscribers', function ()
        local instance = ko.observable();
        local notifiedValues = {};
        instance:subscribe(function (value)
            u_.push(notifiedValues, (value and value.childProperty or value));
        end, "beforeChange");

        local someUnderlyingObject = { childProperty = "A" };
        instance(someUnderlyingObject);
		-- nil can not be stored in lua table
        assert_equal(0,#notifiedValues)
--~         assert_equal(notifiedValues[0]).should_be(undefined);

        instance:valueWillMutate();
        assert_equal(1,#notifiedValues)
        assert_equal("A",notifiedValues[1])

        someUnderlyingObject.childProperty = "B";
        instance:valueHasMutated();
        assert_equal(1,#notifiedValues)
        assert_equal("A",notifiedValues[1])
    end)

    test('Should ignore writes when the new value is primitive and strictly equals the old value', function()
        local instance = ko.observable();
        local notifiedValues = {};
        instance:subscribe( function(...)
			u_.push(notifiedValues, ...)
		end);

        for i = 0,3 do
            instance("A");
            assert_equal("A", instance())
			assert_equal(1, #notifiedValues)
            assert_equal("A", notifiedValues[1])
        end

        instance("B");
        assert_equal("B",instance())
        assert_equal(2, #notifiedValues)
		assert_equal("A", notifiedValues[1])
		assert_equal("B", notifiedValues[2])
    end)

    test('Should ignore writes when both the old and new values are strictly null', function()
        local instance = ko.observable(nil);
        local notifiedValues = {};
        instance:subscribe(function(...)
			u_.push(notifiedValues, ...)
		end);

        instance(nil);
        assert_equal(0,#notifiedValues)
    end)

--~     test('Should ignore writes when both the old and new values are strictly undefined', function()
--~         local instance = ko.observable(undefined);
--~         local notifiedValues = [];
--~         instance.subscribe(notifiedValues.push, notifiedValues);
--~         instance(undefined);
--~         assert_equal(notifiedValues).should_be([]);
--~     end)

    test('Should notify subscribers of a change when an object value is written, even if it is identical to the old value', function()
        -- Because we can't tell whether something further down the object graph has changed, we regard
        -- all objects as new values. To override this, set an "equalityComparer" callback
        local constantObject = {};
        local instance = ko.observable(constantObject);
        local notifiedValues = {};

        instance:subscribe(function(...)
			u_.push(notifiedValues, ...)
		end);

        instance(constantObject);
        assert_equal(constantObject, notifiedValues[1])
    end)


    test('Should notify subscribers of a change even when an identical primitive is written if you\'ve set the equality comparer to null', function()
        local instance = ko.observable("A");
        local notifiedValues = {};
        instance:subscribe(function(...)
			u_.push(notifiedValues, ...)
		end);

        -- No notification by default
        instance("A");
        assert_equal(0,#notifiedValues);

        -- But there is a notification if we null out the equality comparer
        instance.equalityComparer = false;
        instance("A");
        assert_equal("A",notifiedValues[1])
    end)

    test('Should ignore writes when the equalityComparer callback states that the values are equal', function()
        local instance = ko.observable();
        instance.equalityComparer = function(a, b)
			print(a,b)
			if a ~= nil and b ~= nil then
				return a.id == b.id
			else
				return a == b
			end
        end

        local notifiedValues = {}
		local changeCnt = 0;
        instance:subscribe(function(...)
			changeCnt = changeCnt + 1
			u_.push(notifiedValues, ...)
		end);

        instance({ id= 1 });
		print('changeCnt',changeCnt)
        assert_equal(1, #notifiedValues)

        -- Same key - no change
        instance({ id= 1, ignoredProp= 'abc' });
		print('changeCnt',changeCnt)
        assert_equal(1,#notifiedValues);

        -- Different key - change
        instance({ id= 2, ignoredProp= 'abc' });
		print('changeCnt',changeCnt)
        assert_equal(2, #notifiedValues);

        -- Null vs not-null - change
        instance:setNil();
		print('changeCnt',changeCnt, instance() )
        assert_equal(3, changeCnt)
		assert_equal(2, #notifiedValues);

        -- Null vs null - no change
        instance(nil);
        assert_equal(3, changeCnt)
		assert_equal(2, #notifiedValues);

--~         -- Null vs undefined - change
--~         instance(undefined);
--~         assert_equal(notifiedValues.length).should_be(4);

        -- undefined vs object - change
        instance({ id= 1 });
        assert_equal(4, changeCnt)
		assert_equal(3, #notifiedValues);

    end)

    test('Should expose an "update" extender that can configure the observable to notify on all writes, even if the value is unchanged', function()
        local instance = ko.observable();
        local notifiedValues = {};
        instance:subscribe(function(...)
			u_.push(notifiedValues, ...)
		end);

        instance(123);
        assert_equal(1,#notifiedValues);

        -- Typically, unchanged values don't trigger a notification
        instance(123);
        assert_equal(1, #notifiedValues);

        -- ... but you can enable notifications regardless of change
        instance:extend({ notify= 'always' });
        instance(123);
        assert_equal(2,#notifiedValues);

        -- ... or later disable that
        instance:extend({ notify= false });
        instance(123);
        assert_equal(2, #notifiedValues);
    end)

    test('Should be possible to replace notifySubscribers with a custom handler', function()
        local instance = ko.observable(123);
        local interceptedNotifications = {};
        instance:subscribe(function()
			error("Should not notify subscribers by default once notifySubscribers is overridden")
		end)

        instance.notifySubscribers = function(self, newValue, eventName)
			u_.push(interceptedNotifications,{ eventName= (eventName or "None"), value= newValue })
        end

        instance(456);

        assert_equal(2, #interceptedNotifications);
        assert_equal("beforeChange", interceptedNotifications[1].eventName)
        assert_equal("None",interceptedNotifications[2].eventName)
        assert_equal(123,interceptedNotifications[1].value);
        assert_equal(456,interceptedNotifications[2].value);
    end)
end)


--------------



context('Dependent Observable(computed)', function()
    test('Should be subscribable', function ()
        local instance = ko.computed(function () end);
        assert_equal(true, ko.isSubscribable(instance))
    end)

    test('Should advertise that instances are observable', function ()
        local instance = ko.computed(function () end);
        assert_equal(true, ko.isObservable(instance))
    end)

    test('Should advertise that instances are computed', function ()
        local instance = ko.computed(function () end);
        assert_equal(true, ko.isComputed(instance))
    end)

    test('Should advertise that instances cannot have values written to them', function ()
        local instance = ko.computed(function () end);
        assert_equal(false, ko.isWriteableObservable(instance))
    end)

    test('Should require an evaluator function as constructor param', function ()
        local stat,msg = pcall(function()
			local instance = ko.computed();
		end)

        assert_equal(false,stat);
    end)

    test('Should be able to read the current value of the evaluator function', function ()
        local instance = ko.computed(function ()  return 123; end);
        assert_equal(123,instance());
    end)

    test('Should not be able to write a value to it if there is no "write" callback', function ()
        local instance = ko.computed(function ()  return 123; end);

        local stat,msg = pcall(function()
			instance(456);
		end)

        assert_equal(123,instance())
        assert_equal(false, stat);
    end)

    test('Should invoke the "write" callback, where present, if you attempt to write a value to it', function()
        local invokedWriteWithValue, invokedWriteWithThis;
        local instance = ko.computed{
            read= function() end,
            write= function(value)
				invokedWriteWithValue = value;
--~ 				invokedWriteWithThis = this;
			end
        };

        local someContainer = { depObs= instance };
        someContainer.depObs("some value");

        assert_equal("some value", invokedWriteWithValue);
--~         assert_equal(invokedWriteWithThis).should_be(window); -- Since no owner was specified
    end)

    test('Should use options.owner as "this" when invoking the "write" callback, and can pass multiple parameters', function()
        local invokedWriteWithArgs, invokedWriteWithThis;
        local someOwner = {};
        local instance = ko.computed{
            read= function() end,
            write= function(...)
				local arguments = {...}
				invokedWriteWithArgs = arguments
--~ 				invokedWriteWithThis = this;
			end,
--~             owner: someOwner
        };

        instance("first", 2, {"third1", "third2"});
        assert_equal(3,#invokedWriteWithArgs);
        assert_equal("first",invokedWriteWithArgs[1]);
        assert_equal(2,invokedWriteWithArgs[2]);
        assert_equal(2,#(invokedWriteWithArgs[3]))

		assert_equal("third1",invokedWriteWithArgs[3][1])
		assert_equal("third2",invokedWriteWithArgs[3][2])

--~         assert_equal(invokedWriteWithThis).should_be(someOwner);
    end)

--~     test('Should use the second arg (evaluatorFunctionTarget) for "this" when calling read/write if no options.owner was given': function() {
--~         local expectedThis = {}
--~ 		local actualReadThis, actualWriteThis;
--~         local instance = ko.computed({
--~             read: function() actualReadThis = this end,
--~             write: function() actualWriteThis = this end,
--~         }, expectedThis);

--~         instance("force invocation of write");

--~         assert_equal(actualReadThis).should_be(expectedThis);
--~         assert_equal(actualWriteThis).should_be(expectedThis);
--~     end)

    test('Should be able to pass evaluator function using "options" parameter called "read"', function()
        local instance = ko.computed{
            read= function ()  return 123; end
        }
        assert_equal(123,instance())
    end)

    test('Should cache result of evaluator function and not call it again until dependencies change', function ()
        local timesEvaluated = 0;
        local instance = ko.computed(function ()
			timesEvaluated = timesEvaluated + 1;
			return 123;
		end);

        assert_equal(123,instance())
        assert_equal(123,instance())
        assert_equal(1,timesEvaluated)
    end)

    test('Should automatically update value when a dependency changes', function ()
        local observable = ko.observable(1);
        local depedentObservable = ko.computed(function ()
			return observable() + 1;
		end);

        assert_equal(2,depedentObservable());

        observable(50);
        assert_equal(51,depedentObservable());
    end)

    test('Should unsubscribe from previous dependencies each time a dependency changes', function ()
        local observableA = ko.observable("A");
        local observableB = ko.observable("B");
        local observableToUse = "A";
        local timesEvaluated = 0;
        local depedentObservable = ko.computed(function ()
            timesEvaluated = timesEvaluated + 1;
            return observableToUse == "A" and observableA() or observableB();
        end);

        assert_equal("A",depedentObservable());
        assert_equal(1,timesEvaluated);

        -- Changing an unrelated observable doesn't trigger evaluation
        observableB("B2");
        assert_equal(1,timesEvaluated);

        -- Switch to other observable
        observableToUse = "B";
        observableA("A2");
        assert_equal("B2",depedentObservable());
        assert_equal(2,timesEvaluated);

        -- Now changing the first observable doesn't trigger evaluation
        observableA("A3");
        assert_equal(2,timesEvaluated);
    end)

    test('Should notify subscribers of changes', function ()
        local notifiedValue;
        local observable = ko.observable(1);
        local depedentObservable = ko.computed(function ()
			return observable() + 1;
		end);

        depedentObservable:subscribe(function (value)
			notifiedValue = value;
		end);

        assert_equal(nil,notifiedValue);
        observable(2);
        assert_equal(3,notifiedValue);
    end)

    test('Should notify "beforeChange" subscribers before changes', function ()
        local notifiedValue;
        local observable = ko.observable(1);
        local depedentObservable = ko.computed(function ()
			return observable() + 1;
		end)

        depedentObservable:subscribe(function (value)
			notifiedValue = value;
		end, "beforeChange");

        assert_equal(nil, notifiedValue);
        observable(2);
        assert_equal(2,notifiedValue);
        assert_equal(3,depedentObservable());
    end)

    test('Should only update once when each dependency changes, even if evaluation calls the dependency multiple times', function ()
        local notifiedValues = {};
        local observable = ko.observable();
        local depedentObservable = ko.computed(function ()
			return observable() * observable();
		end);

        depedentObservable:subscribe(function (value)
			u_.push(notifiedValues,value);
		end);

        observable(2);
        assert_equal(1, #notifiedValues);
        assert_equal(4, notifiedValues[1]);
    end)

    test('Should be able to chain dependentObservables', function ()
        local underlyingObservable = ko.observable(1);
        local dependent1 = ko.computed(function ()
			return underlyingObservable() + 1;
		end);
        local dependent2 = ko.computed(function ()
			return dependent1() + 1;
		end);

        assert_equal(3,dependent2());

        underlyingObservable(11);
        assert_equal(13,dependent2());
    end)

--~     test('Should accept "owner" parameter to define the object on which the evaluator function should be called', function ()
--~         local model = new (function () {
--~             this.greeting = "hello";
--~             this.fullMessageWithoutOwner = ko.computed(function () { return this.greeting + " world" });
--~             this.fullMessageWithOwner = ko.computed(function () { return this.greeting + " world" end) this);
--~         })();
--~         assert_equal(model.fullMessageWithoutOwner()).should_be("undefined world");
--~         assert_equal(model.fullMessageWithOwner()).should_be("hello world");
--~     end)

    test('Should dispose and not call its evaluator function when the disposeWhen function returns true', function ()
        local underlyingObservable = ko.observable(100);
        local timeToDispose = false;
        local timesEvaluated = 0;
        local dependent = ko.computed(
            function ()
				timesEvaluated = timesEvaluated + 1;
				return underlyingObservable() + 1;
			end,
			{ disposeWhen= function () return timeToDispose; end }
        );
        assert_equal(1,timesEvaluated);
        assert_equal(1,dependent:getDependenciesCount());

        timeToDispose = true;
        underlyingObservable(101);
        assert_equal(1,timesEvaluated);
        assert_equal(0,dependent:getDependenciesCount())
    end)

    test('Should advertise that instances *can* have values written to them if you supply a "write" callback', function()
        local instance = ko.computed{
            read = function() end,
            write =function() end,
        };
        assert_equal(true,ko.isWriteableObservable(instance))
    end)

--~     test('Should allow deferring of evaluation (and hence dependency detection)', function ()
--~         local timesEvaluated = 0;
--~         local instance = ko.computed{
--~             read: function () timesEvaluated++; return 123 end)
--~             deferEvaluation: true
--~         });
--~         assert_equal(timesEvaluated).should_be(0);
--~         assert_equal(instance()).should_be(123);
--~         assert_equal(timesEvaluated).should_be(1);
--~      end)

end)
