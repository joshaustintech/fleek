def start
  unless ready? then launch(:engine, 3, retries: 2) end
end

def start
  if ready? then launch(:engine, 3, retries: 2) end
end
