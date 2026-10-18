def alpha
  begin
    operation
  rescue StandardError
    retry
  end
end

def beta
  begin
    operation
  rescue StandardError
    retry
  end
end
