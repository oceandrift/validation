/++
    Input validation
 +/
module oceandrift.validation.validate;

import oceandrift.validation.constraints;
import std.conv : to;
import std.traits : Fields, FieldNameTuple, getUDAs;

@safe pure nothrow:

///
ValidationResult!T validate(bool bailOut = false, T)(T input)
        if (is(T == struct) || is(T == class))
{
    auto output = ValidationResult!T(true);

    static foreach (idx, fieldName; FieldNameTuple!T)
    {
        static foreach (constraint; allConstraints)
        {
            { // static foreach doesn’t introduce a scope per default
                alias constraintData = getUDAs!(__traits(getMember, T, fieldName), constraint);

                // constraint applicable?
                static if (constraintData.length != 0)
                {
                    // ensure non-ambiguous constraint
                    static assert(
                        (constraintData.length == 1),
                        "Ambiguous `@" ~ constraint.stringof ~ "` constraint."
                            ~ " Please specify each constraint only once per field; found: "
                            ~ constraintData.length.to!string
                    );

                    mixin(`immutable bool valid = constraintData[0].check(input.` ~ fieldName ~ `);`);

                    if (!valid)
                    {
                        enum em = constraintData[0].errorMessage;
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

    return output;
}

debug pragma(msg, "Available oceandrift/validation constraints: " ~ allConstraints.stringof);

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

///
struct ValidationResult(Data)
{
@safe pure nothrow @nogc:

    // public on purpose, though undocumented; “to be used with care”
    public
    {
        bool _ok = false;
        Data _data;
        ValidationError[(Fields!Data).length] _errors;
    }

    ///
    bool ok() inout
    {
        return this._ok;
    }

    /++
        Validated data (only valid if `.ok` == `true`)
     +/
    Data data() inout
    in (this.ok)
    {
        return _data;
    }

    /++
        Returns:
            InputRange containing all errors
     +/
    auto errors()
    {
        import std.algorithm : filter;

        return _errors[].filter!(e => e.message !is null);
    }
}

unittest
{
    struct Person
    {
        @isNotEmpty
        string name;

        int age;
    }

    auto personA = Person("Some Body", 32);
    ValidationResult!Person rA = validate(personA);
    assert(rA.ok);

    auto personB = Person("", 32);
    ValidationResult!Person rB = validate(personB);
    assert(!rB.ok);
}
