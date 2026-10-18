def same(value)
  /pre#{value}post/ =~ "status"
end

def same(value)
  /pre#{value}post/i =~ "status"
end
