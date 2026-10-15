class TopologyController
  def first
    outer(inner(leaf), sibling)
    one
    two
    three
    four
    five
    six
    seven
    eight
    nine
    ten
    eleven
    twelve
    thirteen
    fourteen
  end

  def second
    outer(inner, leaf(sibling))
    one
    two
    three
    four
    five
    six
    seven
    eight
    nine
    ten
    eleven
    twelve
    thirteen
    fourteen
  end
end
