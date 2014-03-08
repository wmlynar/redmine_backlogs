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
    values.append(["State", '__state'])
    values.append(["None", 0])
    options_for_select((values || []), selected)
  end

  def genericboards_rows_options_for_select(selected=nil)
    values = Tracker.all.collect {|t| [t.name, t.id ] }
    values.append(["Sprint", '__sprint'])
    values.append(["Release", '__release'])
    values.append(["Team", '__team'])
    values.append(["None", 0])
    options_for_select((values || []), selected)
  end

  def genericboards_prefilter_options_for_select(selected=nil)
    values = []
    values.append(["No filter", 0])
    values.append(["Current Release", '__current_release'])
    values.append(["Current Sprint", '__current_sprint'])
    values.append(["My team", '__my_team'])
    options_for_select((values || []), selected)
  end

  def genericboards_boardlist_options_for_select(selected=nil)
    values = RbGenericboard.order(:name).map {|b| [b.name, b.id]}
    options_for_select((values || []), selected)
  end
end
