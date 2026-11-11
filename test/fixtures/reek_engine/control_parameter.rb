# Control parameter fixtures covering branches, calls in conditions and nesting.
class Controls
  def flag(verbose)
    if verbose
      puts "loud"
    end
  end

  def used(verbose)
    return verbose if verbose
    1
  end

  def compared(mode)
    if mode == :fast
      1
    else
      2
    end
  end

  def called(mode)
    if mode.fast?
      1
    end
  end

  def negated(flag)
    return 1 unless !flag
    2
  end

  def chosen(kind)
    case kind
    when :a then 1
    when :b then 2
    end
  end

  def logical(enabled, value)
    enabled && value.to_s
  end

  def logical_rhs(enabled, value)
    value.present? && enabled
  end

  def nested(outer, inner)
    if outer
      if inner
        1
      end
    end
  end

  def ternary(dry_run = false, &block)
    dry_run ? 1 : 2
    block ? 1 : 2
  end

  def in_block(items, strict)
    items.each { |item| item.save if strict }
  end

  def self.singleton(force)
    force ? :yes : :no
  end

  def keyword(force: false, **options)
    return 1 if force
    options
  end

  def destructured((flag, other))
    flag ? other : 1
  end

  def elsif_chain(level)
    if level > 2
      1
    elsif level > 1
      2
    end
  end
end
