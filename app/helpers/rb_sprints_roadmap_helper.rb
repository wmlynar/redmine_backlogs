module RbSprintsRoadmapHelper
  unloadable

  # the resource definition in routes should be able to create it
  # but that failed for some reason
  def rb_sprint_path(sprint)
    "/rb/sprint/#{sprint.id}"
  end

  def edit_rb_sprint_path(sprint)
    "/rb/sprint/#{sprint.id}/edit"
  end

  def new_rb_sprints_project_path(project)
    "/rb/sprints/#{project.identifier}/new"
  end

  def rb_taskboard_path(sprint)
    "/rb/taskboards/#{sprint.id}"
  end

  def link_to_sprint(sprint, options = {})
    return 'no sprint' unless sprint && sprint.is_a?(RbSprint)
    options = {:title => format_date(sprint.effective_date)}.merge(options)
    link_to_if sprint.visible?, format_version_name(sprint), rb_sprint_path(sprint), options
  end
end