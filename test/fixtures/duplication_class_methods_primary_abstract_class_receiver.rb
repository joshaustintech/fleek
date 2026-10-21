class AbstractRecord < ActiveRecord::Base
  ActiveRecord::Base.primary_abstract_class
end
