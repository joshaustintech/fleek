def current_state(state)
  case state
  when :active, :paused
    transition(:current)
  when :paused
    transition(:pause)
  else
    transition(:missing)
  end
end

def desired_state(state)
  case state
  when :active, :paused
    transition(:desired)
  when :paused
    transition(:hold)
  else
    transition(:missing)
  end
end
