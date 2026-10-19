def increment
  total += 1
  remember(total)
  publish(total)
  audit(total)
end

def increment
  count += 1
  remember(count)
  publish(count)
  audit(count)
end
