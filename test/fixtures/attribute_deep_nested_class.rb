class Profile
  private

  class Credentials
    attr_accessor :secret
    attr_writer :token
    attr_reader :label

    class Secrets
      private
      attr_accessor :internal
      public
      attr_writer :visible
    end
  end
end
