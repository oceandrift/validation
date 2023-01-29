/++
    Validation constraints

    Implemented as UDAs.

    $(B “Batteries included!”)
    This module provides a set of constraints
    for the most common use cases.


    ## Implementing your own constraints

    To implement a custom constraint,
    create a new `struct` and tag it with @[constraint].

    Implement a member function `check()` that accepts a parameter of the type to validate.
    Utilize templates or overloads to implement checks for different types.

    Implement an `errorMessage` member:
    Either a (property) function with return type `string`
    or a field `string`.
 +/
module oceandrift.validation.constraints;

import std.conv : to;
import std.traits : getSymbolsByUDA, hasUDA;

@safe:

// TODO: rewrite, once current preview “shortenedMethods” are enabled by default

/++
    UDA to mark constraint definitions
 +/
struct constraint
{
}

/++
    Inverts a constraint
 +/
@constraint struct not(OtherConstraint)
{
    OtherConstraint otherConstraint;

    bool check(T)(T actual)
    {
        return (!otherConstraint.check(actual));
    }

    string errorMessage()
    {
        // FIXME
        static assert(
            __traits(compiles, () { string s = otherConstraint.errorMessage; }),
            "`@not` cannot generate an error message for faulty constraint `@"
                ~ O.stringof
                ~ '`'
        );
        return "must *not* comply with: " ~ otherConstraint.errorMessage;
    }
}

/// ditto
@constraint struct not(alias otherConstraint)
{
    bool check(T)(T actual)
    {
        return (!otherConstraint.check(actual));
    }

    string errorMessage()
    {
        // FIXME
        static assert(
            __traits(compiles, () { string s = otherConstraint.errorMessage; }),
            "`@not` cannot generate an error message for faulty constraint `@"
                ~ O.stringof
                ~ '`'
        );
        return "must *not* comply with: " ~ otherConstraint.errorMessage;
    }
}

///
unittest
{
    struct Data
    {
        @not!nonNaN // <-- must be NaN
        float value = float.nan;
    }
}

///
unittest
{
    struct Data
    {
        @not!nonNegative // <-- must not be non-negative
        int value;
    }
}

/++
    Value must not be NULL
 +/
@constraint struct notNull
{
    bool check(T)(T actual)
    {
        return (actual !is null);
    }

    static immutable string errorMessage = "must not be NULL";
}

///
unittest
{
    assert(!test!notNull(null));
    assert(test!notNull(""));

    auto o = new Object();
    assert(test!notNull(o));
    Object o2 = null;
    assert(!test!notNull(o2));

    int* i = null;
    assert(!test!notNull(i));

    int* i2 = new int(10);
    assert(test!notNull(i2));
}

// string

/++
    Value must be longer than or as long as n units
 +/
@constraint struct minLength
{
    size_t n;

    bool check(T)(T actual)
    {
        return (actual.length >= this.n);
    }

    string errorMessage()
    {
        return "length must be >= " ~ this.n.to!string;
    }
}

///
unittest
{
    assert(test!(minLength(2))("12"));
    assert(test!(minLength(2))("123"));
    assert(!test!(minLength(2))("1"));

    assert(test!(minLength(4))("1234"));
    assert(!test!(minLength(4))("123"));

    assert(test!(minLength(1))("1"));
    assert(!test!(minLength(1))(""));

    assert(test!(minLength(0))("1"));
    assert(test!(minLength(0))(""));

    assert(test!(minLength(2))([99, 98, 97]));
    assert(!test!(minLength(2))([1]));
}

/++
    Value must be shorter than or as long as N units
 +/
@constraint struct maxLength
{
    size_t n;

    bool check(T)(T actual)
    {
        return (actual.length <= this.n);
    }

    string errorMessage()
    {
        return "length must be <= " ~ this.n.to!string;
    }
}

///
unittest
{
    assert(test!(maxLength(2))("1"));
    assert(test!(maxLength(2))("12"));
    assert(!test!(maxLength(2))("123"));

    assert(test!(maxLength(4))("1234"));
    assert(!test!(maxLength(4))("12345"));

    assert(test!(maxLength(1))("1"));
    assert(!test!(maxLength(1))("12"));

    assert(test!(maxLength(0))(""));
    assert(!test!(maxLength(0))("1"));

    immutable string null_ = null;
    assert(test!(maxLength(0))(null_));
}

/++
    Value must be exactly N units long
 +/
@constraint struct exactLength
{
    size_t n;

    bool check(T)(T actual)
    {
        return (actual.length == this.n);
    }

    string errorMessage()
    {
        return "length must be exactly " ~ this.n.to!string;
    }
}

///
unittest
{
    assert(test!(exactLength(2))("12"));
    assert(!test!(exactLength(2))("1"));
    assert(!test!(exactLength(2))("123"));

    assert(test!(exactLength(4))("1234"));
    assert(!test!(exactLength(4))("12345"));

    assert(test!(exactLength(1))("1"));
    assert(!test!(exactLength(1))("12"));

    assert(test!(exactLength(0))(""));
    assert(!test!(exactLength(0))("1"));

    immutable string null_ = null;
    assert(test!(exactLength(0))(null_));
}

/++
    Valid Unicode (UTF-8, UTF-16 or UTF-32) constraint
 +/
@constraint struct isUnicode
{
    bool check(T)(T s)
    {
        import std.utf : validate;

        try
            validate(s);
        catch (Exception)
            return false;

        return true;
    }

    static immutable string errorMessage = "is not well-formed UTF-8";
}

///
unittest
{
    assert(test!isUnicode("abcdefghijklmnopqrstuvwxyz"));
    assert(test!isUnicode("ABCDEFGHIUJKLMNOPQRSTUVXYZ"));
    assert(test!isUnicode("1234567890"));
    assert(test!isUnicode("Öl, Müll, Spaß"));
    assert(!test!isUnicode("\xFF"));
    assert(!test!isUnicode("\xF8\xA1\xA1\xA1\xA1"));
}

unittest
{
    const(char)[] s = "0000";
    assert(test!isUnicode(s));
}

/++
    Value must contain only letters (a … z, A … Z)
 +/
@constraint struct isAlpha
{
    bool check(T)(T s)
    {
        import std.traits : isIterable;
        import std.ascii : isAlpha;

        static if (isIterable!T)
        {
            foreach (c; s)
                if (!c.isAlpha)
                    return false;

            return true;
        }
        else
        {
            return s.isAlpha;
        }
    }

    static immutable string errorMessage = "must contain alphabetic letters only";
}

///
unittest
{
    assert(test!isAlpha("abcdefghijklmnopqrstuvwxyz"));
    assert(test!isAlpha("ABCDEFGHIUJKLMNOPQRSTUVXYZ"));
    assert(!test!isAlpha("a12"));
    assert(!test!isAlpha("Müll"));

    assert(test!isAlpha('a'));
    assert(test!isAlpha('A'));
    assert(!test!isAlpha('9'));
    assert(!test!isAlpha("\xFF"));
}

/++
    Value must contain only uppercase letters (A … Z)
 +/
@constraint struct isUpper
{
    bool check(T)(T s)
    {
        import std.traits : isIterable;
        import std.ascii : isUpper;

        static if (isIterable!T)
        {
            foreach (c; s)
                if (!c.isUpper)
                    return false;

            return true;
        }
        else
        {
            return s.isUpper;
        }
    }

    static immutable string errorMessage = "must contain uppercase letters only";
}

///
unittest
{
    assert(!test!isUpper("abcdefghijklmnopqrstuvwxyz"));
    assert(test!isUpper("ABCDEFGHIUJKLMNOPQRSTUVXYZ"));
    assert(!test!isUpper("A12"));
    assert(!test!isUpper("MÜLL"));

    assert(!test!isUpper('a'));
    assert(test!isUpper('A'));
    assert(!test!isUpper('9'));
    assert(!test!isUpper("\xFF"));
}

/++
    Value must contain only lowercase letters (A … Z)
 +/
@constraint struct isLower
{
    bool check(T)(T s)
    {
        import std.traits : isIterable;
        import std.ascii : isLower;

        static if (isIterable!T)
        {
            foreach (c; s)
                if (!c.isLower)
                    return false;

            return true;
        }
        else
        {
            return s.isLower;
        }
    }

    static immutable string errorMessage = "must contain alphabetic lowercase letters only";
}

///
unittest
{
    assert(test!isLower("abcdefghijklmnopqrstuvwxyz"));
    assert(!test!isLower("ABCDEFGHIUJKLMNOPQRSTUVXYZ"));
    assert(!test!isLower("A12"));
    assert(!test!isLower("müll"));

    assert(test!isLower('a'));
    assert(!test!isLower('A'));
    assert(!test!isLower('9'));
    assert(!test!isLower("\xFF"));
}

/++
    Value must contain only alpha-numeric characters (a … z, A … Z, 0 … 9)
 +/
@constraint struct isAlphaNum
{
    bool check(T)(T s)
    {
        import std.traits : isIterable;
        import std.ascii : isAlphaNum;

        static if (isIterable!T)
        {
            foreach (c; s)
                if (!c.isAlphaNum)
                    return false;

            return true;
        }
        else
        {
            return s.isAlphaNum;
        }
    }

    static immutable string errorMessage = "must contain alpha-numeric characters only";
}

///
unittest
{
    assert(test!isAlphaNum("abcdefghijklmnopqrstuvwxyz"));
    assert(test!isAlphaNum("ABCDEFGHIUJKLMNOPQRSTUVXYZ"));
    assert(test!isAlphaNum("A12"));
    assert(test!isAlphaNum("Az12"));
    assert(!test!isAlphaNum("Müll"));

    assert(test!isAlphaNum('a'));
    assert(test!isAlphaNum('A'));
    assert(test!isAlphaNum('9'));
    assert(!test!isAlphaNum("\xFF"));
}

/++
    Value must contain only digits (0 … 9)
 +/
@constraint struct isDigit
{
    bool check(T)(T s)
    {
        import std.traits : isIterable;
        import std.ascii : isDigit;

        static if (isIterable!T)
        {
            foreach (c; s)
                if (!c.isDigit)
                    return false;

            return true;
        }
        else
        {
            return s.isDigit;
        }
    }

    static immutable string errorMessage = "must contain digits only";
}

///
unittest
{
    assert(test!isDigit("12998"));
    assert(test!isDigit("1"));

    assert(!test!isDigit("abcdefghijklmnopqrstuvwxyz"));
    assert(!test!isDigit("ABCDEFGHIUJKLMNOPQRSTUVXYZ"));
    assert(!test!isDigit("A12"));
    assert(!test!isDigit("Az12"));
    assert(!test!isDigit("Müll"));

    assert(!test!isDigit('a'));
    assert(!test!isDigit('A'));
    assert(test!isDigit('9'));
    assert(!test!isDigit("\xFF"));
}

///
enum notEmpty = minLength(1);

///
unittest
{
    assert(test!notEmpty("12998"));
    assert(test!notEmpty("0"));
    assert(!test!notEmpty(""));

    assert(test!notEmpty([123, 456, 789,]));
    assert(!test!notEmpty([]));

    immutable string null_ = null;
    assert(!test!notEmpty(null_));
}

// numeric

/++
    Value must be >= N

    Minimum value constraint
 +/
@constraint struct greaterThanOrEqualTo
{
    long n;

    bool check(T)(T actual)
    {
        return (actual >= n);
    }

    string errorMessage()
    {
        return "must be >= " ~ this.n.to!string;
    }
}

///
unittest
{
    assert(test!(greaterThanOrEqualTo(10))(11));
    assert(test!(greaterThanOrEqualTo(10))(10));
    assert(!test!(greaterThanOrEqualTo(10))(9));
    assert(!test!(greaterThanOrEqualTo(10))(-1));

    assert(test!(greaterThanOrEqualTo(-10))(1));
    assert(test!(greaterThanOrEqualTo(-10))(-10));
    assert(!test!(greaterThanOrEqualTo(-10))(-11));
}

/++
    Value must be <= N

    Maximum value constraint
 +/
@constraint struct lessThanOrEqualTo
{
    long n;

    bool check(T)(T actual)
    {
        return (actual <= n);
    }

    string errorMessage()
    {
        return "must be <= " ~ this.n.to!string;
    }
}

///
unittest
{
    assert(!test!(lessThanOrEqualTo(10))(11));
    assert(test!(lessThanOrEqualTo(10))(10));
    assert(test!(lessThanOrEqualTo(10))(9));
    assert(test!(lessThanOrEqualTo(10))(-1));

    assert(!test!(lessThanOrEqualTo(-10))(1));
    assert(test!(lessThanOrEqualTo(-10))(-10));
    assert(test!(lessThanOrEqualTo(-10))(-11));
}

/++
    Value must be < N
 +/
@constraint struct lessThan
{
    long n;

    bool check(T)(T actual)
    {
        return (actual < n);
    }

    string errorMessage()
    {
        return "must be < " ~ n.to!string;
    }
}

///
unittest
{
    assert(!test!(lessThan(10))(11));
    assert(!test!(lessThan(10))(10));
    assert(test!(lessThan(10))(9));
    assert(test!(lessThan(10))(-1));

    assert(!test!(lessThan(-10))(1));
    assert(!test!(lessThan(-10))(-10));
    assert(test!(lessThan(-10))(-11));
}

/++
    Value must be > N
 +/
@constraint struct greaterThan
{
    long n;

    bool check(T)(T actual)
    {
        return (actual > n);
    }

    string errorMessage()
    {
        return "must be > " ~ n.to!string;
    }
}

///
unittest
{
    assert(test!(greaterThan(10))(11));
    assert(!test!(greaterThan(10))(10));
    assert(!test!(greaterThan(10))(9));
    assert(!test!(greaterThan(10))(-1));

    assert(test!(greaterThan(-10))(1));
    assert(!test!(greaterThan(-10))(-10));
    assert(!test!(greaterThan(-10))(-11));
}

/++
    Value must not be equal to zero
 +/
@constraint struct nonZero
{
    bool check(T)(T actual)
    {
        return (actual != 0);
    }

    enum string errorMessage = "must be non-zero";
}

///
unittest
{
    assert(test!nonZero(1));
    assert(test!nonZero(2));
    assert(test!nonZero(-1));
    assert(!test!nonZero(0));
}

enum positive = greaterThan(0); ///
enum negative = lessThan(0); ///
enum nonNegative = greaterThanOrEqualTo(0); ///
enum nonPositive = lessThanOrEqualTo(0); ///
alias minValue = greaterThanOrEqualTo; ///
alias maxValue = lessThanOrEqualTo; ///

// floating point

///
struct nonNaN
{
    bool check(T)(T actual)
    {
        import std.math : isNaN;

        return (!actual.isNaN);
    }

    enum string errorMessage = "must be non-NaN";
}

///
unittest
{
    assert(test!nonNaN(1.0f));
    assert(test!nonNaN(-1.0f));

    assert(test!nonNaN(1.0));
    assert(test!nonNaN(-1.0));

    enum float nan = 0f / 0f;
    assert(!test!nonNaN(nan));
}

// probably not something you’d want to use
alias allFactoryConstraints = getSymbolsByUDA!(oceandrift.validation.constraints, constraint);

/++
    Determines whether a symbol qualifies as constraint

    $(WARNING
        Does not validate the constraint implementation.
        Just checks whether it’s marked @[constraint].
    )
 +/
enum isConstraint(alias ConstraintCandidate) = hasUDA!(ConstraintCandidate, constraint);

///
unittest
{
    @constraint static struct aConstraint
    {
        bool check(int)
        {
            return false;
        }

        enum string errorMessage = "hi";
    }

    static struct notAConstraint
    {
        bool check(int)
        {
            return false;
        }

        enum string errorMessage = "hi";
    }

    assert(isConstraint!(minLength));
    assert(isConstraint!(aConstraint));
    assert(!(isConstraint!(notAConstraint)));
}

// unittest helper function
private bool test(alias constraintToTest, T)(T actual)
{
    string error = constraintToTest.errorMessage;
    assert(error !is null);

    return constraintToTest.check(actual);
}

// unittest helper function
private bool test(ConstraintToTest, T)(T actual)
{
    auto constraintToTest = ConstraintToTest.init;

    immutable string error = constraintToTest.errorMessage;
    assert(error !is null);

    return constraintToTest.check(actual);
}
