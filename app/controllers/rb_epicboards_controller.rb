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
    @sprint_backlogs = cls.backlogs_by_sprint(@project, sprints)
    @sprint_backlogs.each do |s|
      s[:type] = 'sprint'
    end

    releases = @project.open_releases_by_date
    @release_backlogs = cls.backlogs_by_release(@project, releases)
    @release_backlogs.each do |r|
      r[:type] = 'release'
      r[:sprint] = r.delete(:release)
    end

    #This project and subprojects
    @epics = RbEpic.where(:project_id => @project).select { |s| RbEpic.trackers.include?(s.tracker_id) }

    @columns = @release_backlogs
    @columns.concat(@sprint_backlogs)
    @columns.append(@product_backlog)

    respond_to do |format|
      format.html { render :layout => "rb" }
    end
  end

end
