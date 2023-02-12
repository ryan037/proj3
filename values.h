#ifndef VALUES_H
#define VALUES_H

#include<stdio.h>

enum ValueType
{
    type_integer = 0,
    type_real = 1,
    type_bool = 2,
    type_string = 3,
    type_void = 4,
    type_array = 5
};

enum EntryType
{
    Constant = 0,
    Variable = 1,
    Argument = 2,
    Function = 3
};

inline char* vEnumToString(const ValueType value)
{
    switch (value)
    {
    case ValueType::type_integer:
        return "Int";
    case ValueType::type_real:
        return "Float";
    case ValueType::type_bool:
        return "Bool";
    case ValueType::type_string:
        return "String";
    case ValueType::type_void:
        return "Void";
    case ValueType::type_array:
        return "Array";
    default:
        return "Fail";
    }
}
inline char* eEnumToString(const EntryType value)
{
    switch (value)
    {
    case EntryType::Constant:
	    return "Constant";
    case EntryType::Variable:
	    return "Variable";
    case EntryType::Argument:
	    return "Argument";
    case EntryType::Function:
	    return "Function";
    default:
        return "Fail";
    }
}
#endif
