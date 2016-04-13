tpeg = require('terrapeg')

-- lol unicode
-- झ ञ ट ठ ड ढ ण त थ द ध न

minus = tpeg.option(tpeg.literal("-"))
digits = tpeg.min_reps(tpeg.byteset("0123456789"), 1)
s_end = tpeg.stringend

patt = tpeg.choice{
    tpeg.sequence{minus, digits, tpeg.literal("."), tpeg.option(digits), s_end},
    tpeg.sequence{minus, digits, s_end}
}

print(patt)
patt:disas()

cb = tpeg.capturebuffer(100)

tests = {"23", "23.3", "0.5", "-1", "--1", "-12.5", "-12.", "-.3"}

for _, s in ipairs(tests) do
    cb.cb.pos = 0
    local ret = patt(terralib.cast(&uint8, s), 0, s:len(), cb.cb)
    print(s .. ": " .. tostring(ret._0))
end
