-- terrapeg.t
--
-- parsing expression grammars in terra

local terrapeg = {}

struct terrapeg.CaptureEntry_t {
    id: uint16;
    startpos: uint16;
    endpos: uint16;
}

struct terrapeg.CaptureBuffer_t {
    maxsize: uint32;
    pos: uint32;
    buff: &terrapeg.CaptureEntry_t;
}
local CB = terrapeg.CaptureBuffer_t

-- allocates a capture buffer
function terrapeg.capturebuffer(maxsize)
    local ret = terralib.new(CB)
    ret.maxsize = maxsize
    ret.pos = 0
    local data = terralib.new(terrapeg.CaptureEntry_t[maxsize])
    ret.buff = data
    return {cb = ret, buff = data}
end

-- copy and null terminate a string
-- dest must have size at least n+1
local terra strcpy_nt(src: &int8, dest: &int8, n: int)
    for i = 0,n do
        dest[i] = src[i]
    end
    dest[n] = 0 -- null terminate just to be safe
end

-- convert a string into a terra value (int8 array)
local function stringToTerra(s)
    local n = s:len()
    local ret = terralib.new(int8[n+1])
    strcpy_nt(s, ret, n)
    return ret
end

-- convert a string into a terra constant
local function stringToConstant(s)
    local tstr = stringToTerra(s)
    local tconst = terralib.constant(tstr)
    return {tstr = tstr, tconst = tconst, slen = s:len()}
end

-- create a terra function that pattern matches a literal
function terrapeg.literal(s)
    local const_info = stringToConstant(s)
    local const_str = const_info.tconst
    local terra literal_(src: &int8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        -- Square brackets in terra indicate an escape: the string length
        -- will be evaluated to a literal value as if it were a #define
        if slen - pos < [const_info.slen] then
            return false, pos
        end
        var offset_src = (src + pos)
        for i = 0,[const_info.slen] do
            if offset_src[i] ~= const_str[i] then
                return false, pos
            end
        end
        return true, pos + [const_info.slen]
    end
    return literal_
end

-- create a terra function that will match any exactly n characters
function terrapeg.any_n(n)
    local nn = n
    local terra any_n_(src: &int8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        if slen - pos < [nn] then
            return false, pos
        else
            return true, pos + [nn]
        end
    end
    return any_n_
end

-- create a terra function that matches minmatches or more repetitions
-- of the given pattern
function terrapeg.min_reps(patt, minmatches)
    local terra min_reps_(src: &int8, pos: int, slen: int,  cbuff: &CB) : {bool, int}
        var p0 : int = pos -- save position in case we fail and need to revert
        var succeeded : bool = true
        var nsuccesses : int = -1 -- we always get one 'free' success
        while succeeded do
            succeeded, pos = patt(src, pos, slen, cbuff)
            nsuccesses = nsuccesses + 1
        end
        if nsuccesses >= minmatches then
            return true, pos
        else
            return false, p0
        end
    end
    return min_reps_
end

local function listcall_(patterns, success, src, pos, oldp, slen, cb)
    local stmts = terralib.newlist()
    for _,v in ipairs(patterns) do
        local stmnt = quote
            success, pos = v(src, pos, slen, cb)
            if not success then
                return false, oldp
            end
        end
        stmts:insert(stmnt)
    end
    return stmts
end

-- create a terra function that matches the given patterns in order
function terrapeg.sequence(patterns)
    local terra sequence_(src: &int8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        var oldpos: int = pos
        var success: bool = true
        [listcall_(patterns, success, src, pos, oldpos, slen, cbuff)]
        return true, pos
    end
    return sequence_
end

-- create a terra function that captures what it is enclosing
function terrapeg.capture(patt, id)
    local terra cap_(src: &int8, pos: int, slen: int, cbuff: &CB) : {bool, int}
        var oldcbpos = cbuff.pos
        var capturestart = pos
        var success: bool
        var endpos: int
        var ourentry: &terrapeg.CaptureEntry_t = &(cbuff.buff[cbuff.pos])
        cbuff.pos = (cbuff.pos + 1) % cbuff.maxsize -- corrupt rather overflow
        success, endpos = patt(src, pos, slen, cbuff)
        if success then
            ourentry.id = id
            ourentry.startpos = capturestart
            ourentry.endpos = endpos
        else
            -- roll back capture buffer
            cbuff.pos = oldcbpos
        end
        return success, endpos
    end
    return cap_
end

return terrapeg
