class RbGenericboard < ActiveRecord::Base
  attr_accessible :cols, :elements, :name, :prefilter, :rows
end
