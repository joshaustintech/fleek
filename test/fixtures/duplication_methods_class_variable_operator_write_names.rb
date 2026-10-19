def increment
  publish(@@count += 1)
  audit(@@count += 1)
end

def increment
  publish(@@total += 1)
  audit(@@total += 1)
end
