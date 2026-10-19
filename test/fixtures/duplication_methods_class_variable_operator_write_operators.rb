def update
  publish(@@count += 1)
  audit(@@count += 1)
end

def update
  publish(@@count -= 1)
  audit(@@count -= 1)
end
