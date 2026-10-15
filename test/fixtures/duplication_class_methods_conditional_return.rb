class TokenValidator
  def validate_digest(digest, token)
    return false if digest.nil?
    return false if token.nil?
    TokenValidator.check_digest(digest)
    TokenValidator.check_token(token)
    TokenValidator.record_attempt(digest, token)
  end

  def authenticate_digest(digest, token)
    return false if digest.nil?
    return false if token.nil?
    TokenValidator.check_digest(digest)
    TokenValidator.check_token(token)
    TokenValidator.record_attempt(digest, token)
  end
end
