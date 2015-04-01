include RbCommonHelper

class FakeProductBacklog
  def id; 0 end
  def name; 'Product Backlog' end
end

class RbEpicboardsController < RbApplicationController
  unloadable

  def show
    cls = RbStory
    product_backlog_stories = cls.product_backlog(@project)
    @product_backlog = { :sprint => FakeProductBacklog.new,
      :type => 'productbacklog', :stories => product_backlog_stories||[] }

    sprints = @project.open_shared_sprints
    #sprints_backlog_stories_of = cls.backlogs_by_sprint(@project, sprints)
    #@sprint_backlogs = sprints.map{ |s| { :sprint => s,
    #  :type => 'sprint', :stories => sprints_backlog_stories_of[s.id]||[] } }
    @sprint_backlogs = cls.backlogs_by_sprint(@project, sprints)
    @sprint_backlogs.each do |s|
      s[:type] = 'sprint'
    end

    releases = @project.open_releases_by_date
    #releases_backlog_stories_of = cls.backlogs_by_release(@project, releases)
    #@release_backlogs = releases.map{ |r| { :sprint => r,
    #  :type => 'release', :stories => releases_backlog_stories_of[r.id]||[] } }
    @release_backlogs = cls.backlogs_by_release(@project, releases)
    @release_backlogs.each do |r|
      r[:type] = 'release'
      r[:sprint] = r.delete(:release)
    end

    #This project
    #@epics = RbEpic.in_projects([@project]).epics.visible.order(:position)||[]

    #This project and subprojects
    @epics = RbEpic.find(:all, :conditions => { :project_id => @project }).select { |s| RbEpic.trackers.include?(s.tracker_id) }
    #add All relevant from sprints and releases
    #sprints.each{|sprint|
    #@epics += RbEpic.backlog(sprint.project.id, sprint.id, nil, {})||[]
    #}
    #releases.each{|release|
    #@epics += RbEpic.backlog(release.project.id, nil, release.id {})||[]
    #}
    #@epics make unique and sort by position

    @columns = @release_backlogs
    @columns.concat(@sprint_backlogs)

    respond_to do |format|
      format.html { render :layout => "rb" }
    end
  end

end
