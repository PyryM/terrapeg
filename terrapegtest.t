tpeg = require('terrapeg')

s = "abeginmidmidend"

b = tpeg.literal("begin")
m = tpeg.min_reps(tpeg.literal("mid"), 0)
e = tpeg.literal("end")

mm = tpeg.sequence{b, m, e}

print(mm)

for i = 0,s:len() do
    print("-------------------")
    local ret = mm(s, i, s:len())
    print(ret._0)
    print(ret._1)
end
