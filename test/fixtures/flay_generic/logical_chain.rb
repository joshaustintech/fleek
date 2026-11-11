first = alpha(1) && beta(2, :x) && gamma(3, :y)
second = beta(2, :x) && gamma(3, :y)
third = alpha(1) || beta(2, :x) || gamma(3, :y)
fourth = beta(2, :x) || gamma(3, :y)
