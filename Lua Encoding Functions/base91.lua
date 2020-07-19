--[[=====================================================================
// 
//  Filename: base91.lua
//  Date: July 18, 2020
//
//  Description:
//      Pure Lua Base91 Encode and Decoder modifed to support Lua 5.3
//
//  Original Author:
//      Ryan Ward (https://github.com/rayaman)
//
//  Modified By:
//      lynexer (https://github.com/lynexer)
// 
=====================================================================]]--

bit=require("bit")

local function _W(f)
    local e = setmetatable({}, {__index = _ENV or getfenv()})
    if setfenv then
        setfenv(f, e)
    end
    return f(e) or e
end

bit = _W(function(_ENV, ...)
    --[[
        This bit API is designed the repalce the no deprecated bit library.
        This is not my orginal code, but I can't for the life of me find the guy on
        Stack Overflow.
    ]]
    
    local floor = math.floor

    local bnot, band, bor, bxor, lshift, rshift

    bnot = function(n)
		local p,c=1,0
		while n>0 do
			local r=n%2
			if r<1 then c=c+p end
			n,p=(n-r)/2,p*2
		end
		return c
	end

	band = function(a,b)
		local p,c=1,0
		while a>0 and b>0 do
			local ra,rb=a%2,b%2
			if ra+rb>1 then c=c+p end
			a,b,p=(a-ra)/2,(b-rb)/2,p*2
		end
    	return c
	end

	bor = function(a,b)
		local p,c=1,0
		while a+b>0 do
			local ra,rb=a%2,b%2
			if ra+rb>0 then c=c+p end
			a,b,p=(a-ra)/2,(b-rb)/2,p*2
		end
		return c
	end

	bxor = function(a,b)
		local p,c=1,0
		while a>0 and b>0 do
			local ra,rb=a%2,b%2
			if ra~=rb then c=c+p end
			a,b,p=(a-ra)/2,(b-rb)/2,p*2
		end
		if a<b then a=b end
		while a>0 do
			local ra=a%2
			if ra>0 then c=c+p end
			a,p=(a-ra)/2,p*2
		end
		return c
	end

	rshift = function(a,disp)
		return floor(a % 4294967296 / 2^disp)
	end

	lshift = function(a,disp)
		return (a * 2^disp) % 4294967296
	end

	return {
		-- bit operations
		bnot = bnot,
		band = band,
		bor  = bor,
		bxor = bxor,
		rshift = rshift,
		lshift = lshift
	}  
end)

function table.flip(t)
	local tt={}
	for i,v in pairs(t) do
		tt[v]=i
	end
	return tt
end

b91enc={'B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9','!','#','$','%','&','(',')','*','+',',','.','/',':',';','<','=','>','?','@','[',']','^','_','`','{','|','}','~','"'}
b91enc[0]='A' -- algorithm expects a 0 as the first index, lua starts at 1... easy fix :)
b91dec=table.flip(b91enc)

function base91Decode(d)
	local l,v,o,b,n = #d,-1,"",0,0
	for i in d:gmatch(".") do
		local c=b91dec[i]
		if not(c) then
			-- Continue
		else
			if v < 0 then
				v = c
			else
				v = v+c*91
				b = bit.bor(b, bit.lshift(v,n))
				if bit.band(v,8191) then
					n = n + 13
				else
					n = n + 14
				end
				while true do
					o=o..string.char(bit.band(b,255))
					b=bit.rshift(b,8)
					n=n-8
					if not (n>7) then
						break
					end
				end
				v=-1
			end
		end
	end
	if v + 1>0 then
		o=o..string.char(bit.band(bit.bor(b,bit.lshift(v,n)),255))
	end
	return o
end

function base91Encode(d)
	local b,n,o,l=0,0,"",#d
	for i in d:gmatch(".") do
		b=bit.bor(b,bit.lshift(string.byte(i),n))
		n=n+8
		if n>13 then
			v=bit.band(b,8191)
			if v>88 then
				b=bit.rshift(b,13)
				n=n-13
			else
				v=bit.band(b,16383)
				b=bit.rshift(b,14)
				n=n-14
			end
			o=o..b91enc[v % 91] .. b91enc[math.floor(v / 91)]
		end
	end
	if n>0 then
		o=o..b91enc[b % 91]
		if n>7 or b>90 then
			o=o .. b91enc[math.floor(b / 91)]
		end
	end
	return o
end