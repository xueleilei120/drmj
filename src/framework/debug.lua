--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

--------------------------------
-- @module debug

--[[--

�ṩ���Խӿ�

]]

if ngx and ngx.log then
    -- ���������
    print = function(...)
        local arg = {...}
        for k,v in pairs(arg) do
            arg[k] = tostring(v)
        end
        ngx.log(ngx.ERR, table.concat(arg, "\t"))
    end
end

--[[--

����һ�����ϵĽӿ�

]]
function DEPRECATED(newfunction, oldname, newname)
    return function(...)
        PRINT_DEPRECATED(string.format("%s() is deprecated, please use %s()", oldname, newname))
        return newfunction(...)
    end
end

--[[--

��ʾ������Ϣ

]]
function PRINT_DEPRECATED(msg)
    if not DISABLE_DEPRECATED_WARNING then
        printf("[DEPRECATED] %s", msg)
    end
end

--[[--

��ӡ������Ϣ

### �÷�ʾ��

~~~ lua

printLog("WARN", "Network connection lost at %d", os.time())

~~~

@param string tag ������Ϣ�� tag
@param string fmt ������Ϣ��ʽ
@param [mixed ...] �������

]]
function printLog(tag, fmt, ...)
    local t = {
        "[",
        string.upper(tostring(tag)),
        "] ",
        string.format(tostring(fmt), ...)
    }
    print(table.concat(t))
end

--[[--

��� tag Ϊ ERR �ĵ�����Ϣ

@param string fmt ������Ϣ��ʽ
@param [mixed ...] �������

]]
function printError(fmt, ...)
    printLog("ERR", fmt, ...)
    print(debug.traceback("", 2))
end

--[[--

��� tag Ϊ INFO �ĵ�����Ϣ

@param string fmt ������Ϣ��ʽ
@param [mixed ...] �������

]]
function printInfo(fmt, ...)
    printLog("INFO", fmt, ...)
end

--[[--

���ֵ������

### �÷�ʾ��

~~~ lua

local t = {comp = "chukong", engine = "quick"}

dump(t)

~~~

@param mixed value Ҫ�����ֵ

@param [string desciption] �������ǰ����������

@parma [integer nesting] ���ʱ��Ƕ�ײ㼶��Ĭ��Ϊ 3

]]
function dump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, desciption)
            else
                result[#result +1 ] = string.format("%s%s = {", indent, _v(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end
