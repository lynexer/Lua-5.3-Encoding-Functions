--[[=====================================================================
// 
//  Filename: strbinary.lua
//  Date: July 18, 2020
//
//  Description:
//      Pure Lua String to Binary Encoder
//
//  Original Author:
//      Corroder
// 
=====================================================================]]--

local basexx = {}
local bitMap = { o = "0", i = "1", l = "1" }

local function ignore_set( str, set )
    if set then
        str = str:gsub( "["..set.."]", "" )
    end
    return str
end

local function pure_from_bit( str )
    return ( str:gsub( '........', function ( cc )
        return string.char( tonumber( cc, 2 ) )
    end))
end

local function unexpected_char_error( str, pos )
    local c = string.sub( str, pos, pos )
    return string.format( "unexpected character at position %d: '%s'", pos, c )
end

function string.frombinary(str,ignore)
    str = ignore_set(str,ignore) str = string.lower(str) str = str:gsub('[ilo]',function(c)
        return bitMap[c]
    end)
    local pos = string.find(str,"[^01]")
    if pos then
        return nil,unexpected_char_error(str,pos)
    end
    return pure_from_bit(str)
end

function string.tobinary(str)
    return ( str:gsub( '.', function(c)
        local byte = string.byte(c)
        local bits = {}
        for _ = 1,8 do
            table.insert( bits, byte%2) byte = math.floor(byte/2)
        end
        return table.concat(bits):reverse()
    end))
end