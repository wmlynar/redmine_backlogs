module RbGenericboardsHelper
  unloadable

  def genericboards_elements_options_for_select(selected=nil)
    values = Tracker.all.collect {|t| [t.name, t.id ] }
    options_for_select((values || []), selected)
  end

  def genericboards_columns_options_for_select(selected=nil)
    values = Tracker.all.collect {|t| [t.name, t.id ] }
    values.append(["Sprint", '__sprint'])
    values.append(["Release", '__release'])
    values.append(["Team", '__team'])
    options_for_select((values || []), selected)
  end

  def genericboards_rows_options_for_select(selected=nil)
    values = Tracker.all.collect {|t| [t.name, t.id ] }
    values.append(["Sprint", '__sprint'])
    values.append(["Release", '__release'])
    values.append(["Team", '__team'])
    options_for_select((values || []), selected)
  end

end
