def current?
  FeatureFlag.prepare
  FeatureFlag.load
  enabled? && authorized?
  FeatureFlag.audit
  FeatureFlag.publish
  FeatureFlag.finish
  FeatureFlag.close
end

def active?
  FeatureFlag.prepare
  FeatureFlag.load
  enabled? && authorized?
  FeatureFlag.audit
  FeatureFlag.publish
  FeatureFlag.finish
  FeatureFlag.close
end
