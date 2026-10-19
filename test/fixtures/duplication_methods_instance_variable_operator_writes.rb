def increment
  publish(@count += 1)
  audit(@count += 1)
end

def increment
  publish(@count += 1)
  audit(@count += 1)
end
