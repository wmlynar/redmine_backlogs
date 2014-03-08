class RbFakeGeneric < RbGeneric
  attr_accessor :subject
  def initialize(subject)
    @subject = subject
  end
  def name
    subject
  end
  #def to_s
  #  subject
  #end
  def id
    0
  end

  def new_record?
    true
  end
  def status
    nil
  end
  def fakeelement
    true
  end

end
