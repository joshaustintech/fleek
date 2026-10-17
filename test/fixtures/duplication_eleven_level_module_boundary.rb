module Current
  module One
    module Two
      module Three
        module Four
          module Five
            module Six
              module Seven
                module Eight
                  module Nine
                    module Ten
                      def current
                        @heading = "Current"
                        @stream = Stream.open(params[:token])
                        render "current", status: :unprocessable_entity
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

module Archived
  module One
    module Two
      module Three
        module Four
          module Five
            module Six
              module Seven
                module Eight
                  module Nine
                    module Ten
                      def archived
                        @heading = "Archived"
                        @stream = Stream.open(params[:token])
                        render "archive", status: :unprocessable_entity
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
