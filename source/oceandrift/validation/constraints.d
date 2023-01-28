/++
    Validation constraints

    Implemented as UDAs.
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
}

/++
    Maximum value constraint

    Value must be <= max
 +/
@constraint struct maxValue
{
    long max;
}

enum isPositive = minValue(0);
alias greaterThanOrEqualTo = minValue;
alias lessThanOrEqualTo = maxValue;

alias allConstraints = getSymbolsByUDA!(oceandrift.validation.constraints, constraint);
