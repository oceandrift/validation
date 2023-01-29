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

@safe pure nothrow @nogc:

// TODO: rewrite, once current preview “shortenedMethods” are enabled by default

/++
    UDA to mark constraint definitions
 +/
struct constraint
{
}

// string

/++
    Minimum length constraint
 +/
@constraint struct minLength
{
    size_t min;
    bool check(T)(T actual)
    {
        return (actual.length >= this.min);
    }

    string errorMessage()
    {
        return "Too short, expected length >= " ~ this.min.to!string;
    }
}

/++
    Maximum length constraint
 +/
@constraint struct maxLength
{
    size_t max;
}

/++
    Minimum length constraint
 +/
@constraint struct exactLength
{
    size_t expected;
}

/++
    Valid UTF-8 constraint
 +/
@constraint struct validUTF8
{
}

/++
    Value must contain only letters (a … z, A … Z) constraint
 +/
@constraint struct onlyAlpha
{
}

/++
    Value must contain only uppercase letters (A … Z) constraint
 +/
@constraint struct onlyUpper
{
}

/++
    Value must contain only lowercase letters (A … Z) constraint
 +/
@constraint struct onlyLower
{
}

/++
    Value must contain only alpha-numeric characters (a … z, A … Z, 0 … 9) constraint
 +/
@constraint struct onlyAlphaNum
{
}

/++
    Value must contain only digits (0 … 9) constraint
 +/
@constraint struct onlyDigits
{
}

enum isNotEmpty = minLength(1);

// numeric

/++
    Minimum value constraint

    Value must be >= min
 +/
@constraint struct minValue
{
    long min;

    bool check(T)(T actual)
    {
        return (actual >= min);
    }

    string errorMessage()
    {
        return "Too low, expected minimum " ~ this.min.to!string;
    }
}

/++
    Maximum value constraint

    Value must be <= max
 +/
@constraint struct maxValue
{
    long max;
}

/++
    Number is positive constraint
 +/
enum isPositive = minValue(0);

///
alias greaterThanOrEqualTo = minValue;

///
alias lessThanOrEqualTo = maxValue;

alias allFactoryConstraints = getSymbolsByUDA!(oceandrift.validation.constraints, constraint);

/++
    Determines whether a symbol qualifies as constraint
 +/
enum isConstraint(alias ConstraintCandidate) = hasUDA!(ConstraintCandidate, constraint);

unittest
{
    static struct notAConstraint
    {
    }

    assert(isConstraint!minLength);
    assert(!(isConstraint!notAConstraint));

}
