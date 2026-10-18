def current_state(state)
  case state
  when :active, :paused
    transition(:current)
  end
end

def desired_state(state)
  case state
  when :active
    transition(:desired)
  end
end
