module M::N
  X = 1
  class << self
    def s; end
  end
  def self.t(*, **, &) = nil
  attr_reader :a
end
a, (b, *c) = 1, 2
case x when 1, 2 then :one else nil end
case y; in {k:} then 1; end
if a then b elsif c then d else e end
x = y unless z
while a do b end
begin; a; rescue E => e; b; ensure c; end
"a#{b}c"; :"s#{1}"; /r#{2}/i; `ls`
[1, *a]; {a => 1, **h}; 1..2; 1...nil
yield 1; super; super(1); return 1, 2; next; break 3
a&&b||!c and not d
$g = @@c = C = 1; A::B = 2; ::C
def f(...) = g(...)
f(&:x); f(*a, **b, &c)
x += 1; x &&= 2; a.b += 1; a[1] ||= 2; A::B ||= 3
defined?(x); alias a b; undef c
1.5; 2r; 3i; nil; true; false; self; __LINE__; __ENCODING__
