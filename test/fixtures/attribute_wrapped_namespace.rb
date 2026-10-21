module Profile
  private

  begin
    class Credentials
      private
      attr_writer :hidden
      public
      attr_accessor :secret
      attr_reader :label
    end
  end
end
