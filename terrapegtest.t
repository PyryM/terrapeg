tpeg = require('terrapeg')

s = "abecbebebeccbebed"

b = tpeg.literal("a")
m = tpeg.min_reps(tpeg.choice{tpeg.literal("be"),
                              tpeg.literal("c")}, 1)
mc = tpeg.capture(m, 23)
e = tpeg.literal("d")

mm = tpeg.sequence{b, mc, e}

print(mm)
mm:disas()

cb = tpeg.capturebuffer(100)

for i = 0,s:len() do
    print("-------------------")
    cb.cb.pos = 0
    local ret = mm(s, i, s:len(), cb.cb)
    print(ret._0)
    print(ret._1)
    if cb.cb.pos > 0 then
        local p0 = cb.cb.buff[0].startpos
        local p1 = cb.cb.buff[0].endpos
        print(p0 .. " -> " .. p1)
        print(s:sub(p0+1, p1))
    end
end
