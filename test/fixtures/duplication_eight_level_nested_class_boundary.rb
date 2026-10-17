class Current
  class Feed
    class Events
      class Stream
        class Entry
          class Detail
            class Metadata
              class Summary
                def current
                  @heading = "Current"
                  @stream = Stream.open(params[:token])
                  @entries = @stream.current.list(limit: params[:limit])
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

class Archived
  class Feed
    class Events
      class Stream
        class Entry
          class Detail
            class Metadata
              class Summary
                def archived
                  @heading = "Archived"
                  @stream = Stream.open(params[:token])
                  @entries = @stream.archived.list(limit: params[:limit])
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
