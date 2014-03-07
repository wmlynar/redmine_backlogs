class RbGenericboard < ActiveRecord::Base
  include Redmine::SafeAttributes
  attr_accessible :cols, :elements, :name, :prefilter, :rows

  safe_attributes 'name'

  def to_s
    name
  end
end
