/++
    Input validation
 +/
module oceandrift.validation.validate;

import oceandrift.validation.constraints;
import std.conv : to;

/++
    Validates data according to its type’s constraints
 +/
ValidationResult!T validate(bool bailOut = false, T)(T input)
        if (is(T == struct) || is(T == class))
{
    auto output = ValidationResult!T(true);

    // foreach field in `T`
    static foreach (idx, field; T.tupleof)
    {
        {
            enum string fieldName = __traits(identifier, field);

            // foreach @UDA of `field`
            alias attributes = __traits(getAttributes, field);
            static foreach (attribute; attributes)
            {
                {
                    static if (is(attribute))
                    {
                        alias attributeType = attribute;
                        enum attributeValue = attributeType.init;
                    }
                    else
                    {
                        enum attributeValue = attribute;
                        alias attributeType = typeof(attributeValue);
                    }

                    static assert(
                        !is(attributeType == void),
                        "Potentially broken attribute `@"
                            ~ attributeValue.stringof
                            ~ "` on field `"
                            ~ fieldName
                            ~ '`'
                    );

                    enum attributeName = __traits(identifier, attributeType);

                    // is UDA a @constraint?
                    static if (isConstraint!attributeType)
                    {
                        // validate constraint implementation
                        static assert(
                            __traits(compiles, () {
                                string s = attributeValue.errorMessage;
                            }),
                            "Invalid Constraint: `@"
                                ~ attributeName ~ "` does not implement `string errorMessage` (at least not properly)"
                        );
                        static assert(
                            __traits(compiles, () {
                                mixin(`bool valid = attributeValue.check(input.` ~ fieldName ~ `);`);
                            }),
                            "Invalid Constraint: `@"
                                ~ attributeName
                                ~ "` does not implement `bool check("
                                ~ typeof(
                                    field
                                ).stringof ~ ") {…}`"
                        );

                        // apply constraint
                        mixin(
                            `immutable bool valid = attributeValue.check(input.` ~ fieldName ~ `);`
                        );

                        // check failed?
                        if (!valid)
                        {
                            enum em = attributeValue.errorMessage;
                            enum ve = ValidationError(fieldName, em);
                            output._errors[idx] = ve;
                            output._ok = false;

                            static if (bailOut)
                                return output;
                        }
                    }
                }
            }
        }
    }

    output._data = input;
    return output;
}

///
@safe unittest
{
    struct Person
    {
        @notEmpty
        string name;

        @nonNegative
        int age;
    }

    auto personA = Person("Somebody", 32);
    ValidationResult!Person rA = validate(personA);
    assert(rA.ok);
    assert(rA.data.name == "Somebody"); // accessing validated data

    auto personB = Person("", 32);
    ValidationResult!Person rB = validate(personB);
    assert(!rB.ok);

    auto personC = Person("Tom", -1);
    ValidationResult!Person rC = validate(personC);
    assert(!rC.ok);
}

/// Validation Error
struct ValidationError
{
@safe pure nothrow:

    ///
    string field;

    ///
    string message;

    ///
    string toString() inout
    {
        return field ~ ": " ~ message;
    }
}

/// Validation Result
struct ValidationResult(Data) if (is(Data == struct) || is(Data == class))
{
@safe pure nothrow @nogc:

    private
    {
        bool _ok = false;
        Data _data;
    }

    // public on purpose, though undocumented; “to be used with care”
    public
    {
        ValidationError[Data.tupleof.length] _errors;
    }

    ///
    bool ok() inout
    {
        return this._ok;
    }

    /++
        Validated data

        (only valid if `.ok` == `true`)
     +/
    Data data() inout
    in (this.ok, "Trying to access data that did not pass validation.")
    {
        return _data;
    }

    /++
        Returns:
            InputRange containing all [ValidationError]s
     +/
    auto errors()
    {
        import std.algorithm : filter;

        return _errors[].filter!(e => e.message !is null);
    }
}
