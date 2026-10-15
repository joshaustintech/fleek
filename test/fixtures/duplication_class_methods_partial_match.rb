class PartialMatchController
  def first
    outer(inner(leaf), sibling)
    shared.a.b.c.d.e.f.g.h.i.j.k.l.m.n.o
  end

  def second
    outer(inner, leaf(sibling))
    shared.a.b.c.d.e.f.g.h.i.j.k.l.m.n.o
  end
end
