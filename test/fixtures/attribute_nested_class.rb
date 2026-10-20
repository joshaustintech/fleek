class Profile
  private

  class Credentials
    attr_accessor :secret
    attr_writer :token
    attr_reader :label
  end
end
