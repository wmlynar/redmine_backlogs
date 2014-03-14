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

  private

  def __sprints_condition(project, options={})
    options[:conditions] ||= []
    pf = prefilter_objects(project)
    r = pf['__current_release']
    if r
      condition = ["#{RbSprint.table_name}.sprint_start_date >= ? and #{RbSprint.table_name}.effective_date <= ? ", r.release_start_date, r.release_end_date]
      Backlogs::ActiveRecord.add_condition(options, condition) if condition
    end
    options
  end

  def __release_condition(project, options={})
    options[:conditions] ||= []
    pf = prefilter_objects(project)
    r = pf['__current_release']
    if r
      condition = ["#{RbRelease.table_name}.id = ? ", r.id]
      Backlogs::ActiveRecord.add_condition(options, condition) if condition
    end
    options
  end
  def __team_condition(project, options={})
    options[:conditions] ||= []
    pf = prefilter_objects(project)
    r = pf['__my_team']
    if r
      condition = ["#{Group.table_name}.id = ? ", r.id]
      Backlogs::ActiveRecord.add_condition(options, condition) if condition
    end
    options
  end

  def resolve_scope(object_type, project, options={})
    case object_type
    when '__sprint'
      options = __sprints_condition(project, options)
      project.open_shared_sprints.scoped(options)

    when '__release'
      options = __release_condition(project, options)
      project.open_releases_by_date.scoped(options)

    when '__team'
      options = __team_condition(project, options)
      Group.order(:lastname).scoped(options).map {|g| g.becomes(RbTeam) }

    when '__state'
      tracker = Tracker.find(element_type) #FIXME multiple trackers, no tracker
      tracker.issue_statuses

    else #assume an id of tracker, see our options in helper
      tracker_id = object_type
      return RbGeneric.visible.order("#{RbGeneric.table_name}.position").
        generic_backlog_scope(
          options.dup.merge({
            :project => project,
            :trackers => resolve_trackers(tracker_id)
        }))
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
      nil
    else
      :parent
    end
  end

  def find_filter_object(project, f)
    return nil if project.nil?
    case f
    when '__current_release'
      #"Current Release"
      project.active_release
      #project.open_releases_by_date
    when '__current_sprint'
      #"Current Sprint"
      project.active_sprint
      #project.open_shared_sprints
    when '__my_team'
      #"my Team"
      User.current.groups.order(:lastname).first
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
    if prefilter.nil?
      return ''
    end
    filter = prefilter.split
    filter.map { |f| filter_name(f, nil) }.compact.join(' and ')
  end

  def filter_name(f, default="")
    case f
    when '__current_release'
      "Current Release"
    when '__current_sprint'
      "Current Sprint"
    when '__my_team'
      "my Team"
    else
      default
    end
  end

  def prefilter_objects(project)
    if prefilter.nil?
      return {}
    end
    filter = prefilter.split
    #filters = {}
    #prefilter.split.each {|f|
    #  obj = find_filter_object(project, f)
    #  filters[f] = obj unless obj.nil?
    #}

    Hash[filter.zip(filter.map{|f| find_filter_object(project, f)})]
  end

  def columns(project, options={})
    if col_type != element_type #elements by col_type
      c = resolve_scope(col_type, project, options).to_a
      if col_type != '__state' #taskboard states have no automatic 'no state' column
        c.unshift(RbFakeGeneric.new("No #{col_type_name}"))
      end
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

  def elements_by_cell(project)
    parent_attribute = resolve_parent_attribute(row_type)
    if col_type != element_type
      column_attribute = resolve_parent_attribute(col_type)
    else
      column_attribute = nil
      col_id = 0
    end

    #aggregate all elements in scope into a matrix indexed by row/column object ids
    map = {}
    elements(project).each {|element|
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
