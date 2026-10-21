class InheritedPrivateBase
  private

  def inherited_helper
    1
  end
end

class InheritedPrivateChild < InheritedPrivateBase
  def child_method
    2
  end
end
