class RbTeam < Group
  unloadable
  def position
    0
  end
end

class RbGenericboard < ActiveRecord::Base
  include Redmine::SafeAttributes
  attr_accessible :cols, :elements, :name, :prefilter, :rows

  private

  def resolve_scope(id, project, options={})
    if id == '__sprint'
      return project.open_shared_sprints
    elsif id == '__release'
      return project.open_releases_by_date
    elsif id == '__team'
      return Group.order(:lastname).map {|g| g.becomes(RbTeam) }
    else
      return RbGeneric.visible.order("#{RbGeneric.table_name}.position").
      backlog_scope(
        options.dup.merge({
          :project => project,
          :trackers => resolve_trackers(id)
      }))
    end
  end

  def resolve_trackers(id)
    if id.start_with?('__')
      return nil
    end
    RbGeneric.all_trackers(Tracker.find(id).id)
  end

  public

  safe_attributes 'name',
    'elements',
    'rows',
    'cols',
    'prefilter'

  def to_s
    name
  end

  def get_columns(project, options={})
    cls = resolve_scope(cols, project, options)
  end

  def get_rows(project, options={})
    cls = resolve_scope(rows, project, options)
  end

  def get_elements(project, options={})
    cls = resolve_scope(elements, project, options)
  end

end
