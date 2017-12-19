
local lu = require('luaunit')

print( lu.EPS )

local pi_div_6_deg_expected, pi_div_6_deg_calculated, pi_div_3_deg_expected, pi_div_3_deg_calculated

pi_div_6_deg_calculated = math.deg(math.pi/6)
pi_div_6_deg_expected = 30

pi_div_3_deg_calculated = math.deg(math.pi/3)
pi_div_3_deg_expected = 60

print( (pi_div_6_deg_expected - pi_div_6_deg_calculated) / lu.EPS ) -- prints: 16
print( (pi_div_3_deg_expected - pi_div_3_deg_calculated) / lu.EPS ) -- prints: 32

-- Better use relative error:
print( ( (pi_div_6_deg_expected - pi_div_6_deg_calculated) / pi_div_6_deg_expected) / lu.EPS ) -- prints: 0.53333
print( ( (pi_div_3_deg_expected - pi_div_3_deg_calculated) / pi_div_3_deg_expected) / lu.EPS ) -- prints: 0.53333

-- relative error is constant. Assertion can take the form of:
lu.assertAlmostEquals( (pi_div_6_deg_expected - pi_div_6_deg_calculated) / pi_div_6_deg_expected, 0, lu.EPS )
lu.assertAlmostEquals( (pi_div_3_deg_expected - pi_div_3_deg_calculated) / pi_div_3_deg_expected, 0, lu.EPS )