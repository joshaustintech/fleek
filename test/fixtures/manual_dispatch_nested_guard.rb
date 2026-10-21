class Parcel
  def guarded_dispatch(target, ready)
    if target.respond_to?(:save)
      if ready
        target.save
      end
    end
  end

  def unguarded_dispatch(target, ready)
    if ready
      target.save
    end
  end
end
