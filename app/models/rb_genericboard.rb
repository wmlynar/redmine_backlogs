class RbTeam < Group
  unloadable
  def position
    0
  end
end

class RbGenericboard < ActiveRecord::Base
  include Redmine::SafeAttributes
  attr_accessible :col_type, :element_type, :name, :prefilter, :colfilter, :rowfilter, :row_type

  private

  def resolve_scope(object_type, project, options={})
    if object_type == '__sprint'
      return project.open_shared_sprints
    elsif object_type == '__release'
      return project.open_releases_by_date
    elsif object_type == '__team'
      return Group.order(:lastname).map {|g| g.becomes(RbTeam) }
    else #assume an id of tracker, see our options in helper
      tracker_id = object_type
      return RbGeneric.visible.order("#{RbGeneric.table_name}.position").
        backlog_scope(
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

  def get_columns(project, options={})
    cls = resolve_scope(col_type, project, options)
  end

  def get_rows(project, options={})
    cls = resolve_scope(row_type, project, options)
  end

  def get_elements(project, options={})
    cls = resolve_scope(element_type, project, options)
  end

end
