tpeg = require('terrapeg')

-- lol unicode
-- झ ञ ट ठ ड ढ ण त थ द ध न

minus = tpeg.symbol()
digits = tpeg.fast_byteset("0123456789")
bare_number = tpeg.min_reps(digits, 1)
s_end = tpeg.stringend
print(digits)

patt = tpeg.choice{
    tpeg.sequence{minus, bare_number,
                  tpeg.literal("."),
                  tpeg.option(bare_number),
                  s_end},
    tpeg.sequence{minus, bare_number, s_end}
}

tpeg.define(minus, tpeg.option(tpeg.literal("-")))
print(minus)
minus:disas()

cb = tpeg.capturebuffer(100)

tests = {"23", "23.3", "0.5", "-1", "--1", "-12.5", "-12.", "-.3"}

for _, s in ipairs(tests) do
    cb.cb.pos = 0
    local ret = patt(terralib.cast(&uint8, s), 0, s:len(), cb.cb)
    print(s .. ": " .. tostring(ret._0))
end
