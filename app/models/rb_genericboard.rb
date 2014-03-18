class RbTeam < Group
  unloadable
  def position
    0
  end
  def status
    nil
  end
  def subject
    lastname
  end
end



class RbGenericboard < ActiveRecord::Base
  include Redmine::SafeAttributes
  attr_accessible :col_type, :element_type, :name, :prefilter, :colfilter, :rowfilter, :row_type
  serialize :prefilter, Array

  attr_accessor :filteroptions

  private

  def open_shared_versions(project)
    #similar to project.open_shared_sprints but we not become(RbSprint) and return scopable query
    if Backlogs.setting[:sharing_enabled]
      order = 'ASC'
      project.shared_versions.visible.scoped(:conditions => {:status => ['open', 'locked']}, :order => "sprint_start_date #{order}, effective_date #{order}")
    else #no backlog sharing
      RbSprint.open_sprints(project)
    end
  end

  def open_releases_by_date(project)
    #similar to project.open_releases_by_date but we want to order ascending
    order = 'ASC'
    (Backlogs.setting[:sharing_enabled] ? project.shared_releases : project.releases).
      visible.open.
      reorder("#{RbRelease.table_name}.release_end_date ASC, #{RbRelease.table_name}.release_start_date ASC")
  end


  def __sprints_condition(project, filteroptions={})
    options = {}
    options[:conditions] ||= []
    pf = prefilter_objects(project, filteroptions)
    r = pf['__current_or_no_release'] || pf['__current_release']
    if r
      condition = ["#{RbSprint.table_name}.sprint_start_date >= ? and #{RbSprint.table_name}.effective_date <= ? ", r.release_start_date, r.release_end_date]
      Backlogs::ActiveRecord.add_condition(options, condition) if condition
    end
    r = pf['__current_or_no_sprint'] || pf['__current_sprint']
    if r
      condition = ["#{RbSprint.table_name}.id = ?", r.id]
      Backlogs::ActiveRecord.add_condition(options, condition) if condition
    end
    options
  end

  def __release_condition(project, filteroptions={})
    options = {}
    options[:conditions] ||= []
    pf = prefilter_objects(project, filteroptions)
    r = pf['__current_release'] || pf['__current_or_no_release']
    if r
      condition = ["#{RbRelease.table_name}.id = ? ", r.id]
      Backlogs::ActiveRecord.add_condition(options, condition) if condition
    end
    options
  end

  def __team_condition(project, filteroptions={})
    options = {}
    options[:conditions] ||= []
    pf = prefilter_objects(project, filteroptions)
    r = pf['__my_team']
    if r
      condition = ["#{Group.table_name}.id = ? ", r.id]
      Backlogs::ActiveRecord.add_condition(options, condition) if condition
    end
    options
  end

  def __element_condition(project, filteroptions={})
    options = {}
    options[:conditions] ||= []
    pf = prefilter_objects(project, filteroptions)
    puts "Element condition for prefilter #{pf}"
    r = pf['__current_or_no_release']
    if r
      condition = ["(#{RbGeneric.table_name}.release_id is null or #{RbGeneric.table_name}.release_id in (?)) ", r.id]
      Backlogs::ActiveRecord.add_condition(options, condition) if condition
    end
    r = pf['__current_release']
    if r
      condition = ["#{RbGeneric.table_name}.release_id in (?) ", r.id]
      Backlogs::ActiveRecord.add_condition(options, condition) if condition
    end
    r = pf['__current_or_no_sprint']
    if r
      condition = ["(#{RbGeneric.table_name}.fixed_version_id is null or #{RbGeneric.table_name}.fixed_version_id in (?)) ", r.id]
      Backlogs::ActiveRecord.add_condition(options, condition) if condition
    end
    r = pf['__current_sprint']
    if r
      condition = ["#{RbGeneric.table_name}.fixed_version_id in (?) ", r.id]
      Backlogs::ActiveRecord.add_condition(options, condition) if condition
    end
    r = pf['__my_team']
    if r
      condition = ["(#{RbGeneric.table_name}.rbteam_id is null or #{RbGeneric.table_name}.rbteam_id in (?)) ", r.id]
      Backlogs::ActiveRecord.add_condition(options, condition) if condition
    end
    options
  end


  def resolve_scope(object_type, project, options={})
    puts "SCOPE OPTIONS #{options}"
    case object_type
    when '__sprint'
      conditions = __sprints_condition(project, options)
      open_shared_versions(project).scoped(conditions).collect{|v| v.becomes(RbSprint)}

    when '__release'
      conditions = __release_condition(project, options)
      open_releases_by_date(project).scoped(conditions)

    when '__team'
      conditions = __team_condition(project, options)
      Group.order(:lastname).scoped(conditions).collect{|g| g.becomes(RbTeam) }

    when '__state'
      tracker = Tracker.find(element_type) #FIXME multiple trackers, no tracker
      tracker.issue_statuses

    else #assume an id of tracker, see our options in helper
      tracker_id = object_type
      conditions = __element_condition(project, options)
      return RbGeneric.visible.order("#{RbGeneric.table_name}.position").
        scoped(conditions).
        generic_backlog_scope({
            :project => project,
            :trackers => resolve_trackers(tracker_id)
        })
    end
  end

  def resolve_trackers(object_type)
    if object_type.start_with?('__')
      return nil
    end
    RbGeneric.all_trackers(Tracker.find(object_type).id)
  end

  def resolve_parent_attribute(object_type)
    case object_type
    when '__sprint'
      :sprint
    when '__release'
      :release
    when '__team'
      :rbteam
    when '__state'
      :status
    else
      :parent
    end
  end

  def find_filter_object(project, f, filteroptions)
    return nil if project.nil?
    object = case f
    when '__current_release', '__current_or_no_release'
      fo = filteroptions['__release']
      if fo.blank?
        project.active_release
      else
        if fo.to_i > 0
          RbRelease.find(filteroptions['__release'])
        end
      end
    when '__current_sprint', '__current_or_no_sprint'
      if filteroptions['__sprint'].to_i > 0
        RbSprint.find(filteroptions['__sprint'])
      elsif filteroptions['__sprint'].to_i == 0
        return nil
      else
        project.active_sprint
      end
    when '__my_team'
      if filteroptions['__team'].to_i > 0
        Group.find(filteroptions['__team'])
      elsif filteroptions['__team'].to_i == 0
        return nil
      else
        User.current.groups.order(:lastname).first
      end
    else
      return nil
    end
    puts "GOT FILTER OBJECT #{object}"
    #unless object
    #  object = find_filter_alternative_options(project, f).first()
    #end
    #puts "RETURN FILTER OBJECT #{object}"

    object
  end

  def find_filter_alternative_options(project, f)
    return nil if project.nil?
    case f
    when '__current_sprint', '__current_or_no_sprint'
      open_shared_versions(project).to_a
    when '__current_release', '__current_or_no_release'
      open_releases_by_date(project).to_a
    when '__my_team'
      #User.current.groups.order(:lastname).to_a
      Group.order(:lastname).to_a
    else
      nil
    end
  end

  def find_filter_option_key(f)
    case f
    when '__current_sprint', '__current_or_no_sprint'
      '__sprint'
    when '__current_release', '__current_or_no_release'
      '__release'
    when '__my_team'
      '__team'
    else
      nil
    end
  end

  public

  safe_attributes 'name',
    'element_type',
    'row_type',
    'col_type',
    'prefilter',
    'rowfilter',
    'colfilter'

  def to_s
    name
  end

  def resolve_class(object_type)
    case object_type
    when '__sprint'
      RbSprint
    when '__release'
      RbRelease
    when '__team'
      Group
    when '__state'
      Tracker
    else #assume an id of tracker, see our options in helper
      RbGeneric
    end
  end

  def row_object(id)
    unless id > 0
      return nil
    end
    cls = resolve_class(row_type)
    cls.find(id)
  end

  def col_object(id)
    unless id > 0
      return nil
    end
    cls = resolve_class(col_type)
    cls.find(id)
  end

  def type_name(object_type)
    case object_type
    when '__sprint'
      "Sprint"
    when '__release'
      "Release"
    when '__team'
      "Team"
    when '__state'
      "State"
    else #assume an id of tracker, see our options in helper
      tracker_id = object_type
      tracker = Tracker.find(tracker_id)
      if tracker
        tracker.name
      else
        "unknown"
      end
    end
  end

  def element_type_name
    type_name(element_type)
  end

  def row_type_name
    type_name(row_type)
  end

  def col_type_name
    type_name(col_type)
  end

  def prefilter_name
    if prefilter.blank?
      return ''
    end
    filter = prefilter
    filter = [filter] if filter && !filter.is_a?(Array)
    filter.collect { |f| filter_name(f, nil) }.compact.join(' and ')
  end

  def filter_name(f, default="")
    case f
    when '__current_release'
      "Current Release"
    when '__current_or_no_release'
      "Current or no Release"
    when '__current_sprint'
      "Current Sprint"
    when '__current_or_no_sprint'
      "Current or no Sprint"
    when '__my_team'
      "my Team"
    else
      default
    end
  end

  def prefilter_objects(project, filteroptions)
    if prefilter.nil?
      return {}
    end
    filter = prefilter
    filter = [filter] if filter && !filter.is_a?(Array)

    Hash[filter.zip(filter.collect{|f| find_filter_object(project, f, filteroptions)})]
  end

  def prefilter_alternative_options(project, filteroptions)
    puts "Prefilter alternative options #{prefilter}"
    filter = prefilter
    filter = [filter] if filter && !filter.is_a?(Array)
    # assemble objects into __filter => list
    opts = Hash[filter.collect{|f|
      [f, {:values=>find_filter_alternative_options(project, f)}] unless f.blank?
    }.compact()]
    # convert onbjects in lists to [id, name] tuples
    opts.each {|key, optionlist|
      unless optionlist.blank?
        optionlist[:values].collect!{|o| [o.name, o.id] unless o.blank?}.compact()
        optionlist[:values] << [ 'Any', 0]
        fo = find_filter_object(project, key, filteroptions)
        optionlist[:selected] = (fo && fo.id) || 0
        optionlist[:label] = filter_name(key)
        optionlist[:key] = find_filter_option_key(key)
      end
    }
    opts
  end

  def columns(project, options={})
    if col_type != element_type #elements by col_type
      c = resolve_scope(col_type, project, options)
      if col_type != '__state' #taskboard states have no automatic 'no state' column
        c = c.to_a.unshift(RbFakeGeneric.new("No #{col_type_name}"))
      end
      puts "COLUMNS #{c.to_a}"
      return c
    else #one column for the elements
      return [ RbFakeGeneric.new("#{col_type_name}") ]
    end
  end

  def rows(project, options={})
    resolve_scope(row_type, project, options)
  end

  def elements(project, options={})
    resolve_scope(element_type, project, options)
  end

  def elements_by_cell(project, options={})
    parent_attribute = resolve_parent_attribute(row_type)
    if col_type != element_type
      column_attribute = resolve_parent_attribute(col_type)
    else
      column_attribute = nil
      col_id = 0
    end

    #aggregate all elements in scope into a matrix indexed by row/column object ids
    map = {}
    elements(project, options).each {|element|
      row_id = element.send(parent_attribute)
      unless row_id.nil?
        row_id = row_id.id
      else
        row_id = 0
      end

      unless column_attribute.nil?
        col_id = element.send(column_attribute)
        unless col_id.nil?
          col_id = col_id.id
        else
          col_id = 0
        end
      end
      unless map.include? row_id
        map[row_id] = {}
      end
      unless map[row_id].include? col_id
        map[row_id][col_id] = []
      end
      map[row_id][col_id].append(element)
    }
    map
  end

end
