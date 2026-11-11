z = 1
case y
in {k:} then 1
in {a: Integer => n, **rest} if n > 1 then 2
in [1, *r, 2] unless r.empty? then 3
in [*, 4, *post] then 4
in ^z | nil | Foo::Bar(x: 1) | Baz[1] then 5
in {a: ^(1 + 2), **nil} then 6
in [] then 7
in Qux then 8
end
x in [a, b]
y => {c:}
