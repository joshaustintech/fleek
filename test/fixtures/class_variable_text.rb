# The marker is source text, not executable class-variable syntax.
class TextOnly
  # @@inside_comment is inert text.
  def example
    "@@inside_string"
  end
end
