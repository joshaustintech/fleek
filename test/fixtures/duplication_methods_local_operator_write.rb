def increment
  total += 1
  remember(total)
  publish(total)
  audit(total)
end

def increment_again
  total += 1
  remember(total)
  publish(total)
  audit(total)
end
