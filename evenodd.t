tpeg = require('terrapeg')

EE = tpeg.symbol()
OE = tpeg.symbol()
EO = tpeg.symbol()
OO = tpeg.symbol()

zero = tpeg.literal('0')
one = tpeg.literal('1')

tpeg.define(EE,
    tpeg.choice{
        tpeg.sequence{zero, OE},
        tpeg.sequence{one, EO},
        tpeg.stringend
    }
)

tpeg.define(OE,
    tpeg.choice{
        tpeg.sequence{zero, EE},
        tpeg.sequence{one, OO}
    }
)

tpeg.define(EO,
    tpeg.choice{
        tpeg.sequence{zero, OO},
        tpeg.sequence{one, EE}
    }
)

tpeg.define(OO,
    tpeg.choice{
        tpeg.sequence{zero, EO},
        tpeg.sequence{one, OE}
    }
)

cb = tpeg.capturebuffer(100)

tests = {"0110", "1010", "1100", "11", "100"}

for _, s in ipairs(tests) do
    cb.cb.pos = 0
    local ret = EE(terralib.cast(&uint8, s), 0, s:len(), cb.cb)
    print(s .. ": " .. tostring(ret._0))
end
