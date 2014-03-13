Given(/^scaled agile features are enabled and configured$/) do
  Backlogs.setting[:scaled_agile_enabled] = true

  # Configure the epic and feature trackers
  epic_trackers = [(Tracker.find_by_name('Epic') || Tracker.create!(:name => 'Epic'))]
  feature_trackers = [(Tracker.find_by_name('Feature') || Tracker.create!(:name => 'Feature'))]
  # get the ids
  epic_trackers = epic_trackers.map { |t| t.id }
  feature_trackers = feature_trackers.map { |t| t.id }
  # set the ids into settings
  Backlogs.setting[:epic_trackers] = epic_trackers
  Backlogs.setting[:feature_trackers] = feature_trackers
  Backlogs.setting[:default_epic_tracker] = epic_trackers[0]
  Backlogs.setting[:default_feature_tracker] = feature_trackers[0]
  #enable the trackers in project
  @project.update_attribute :tracker_ids, (@project.tracker_ids + epic_trackers + feature_trackers)
end

Given(/^some default generic boards are configured$/) do
  epic = Tracker.find_by_name('Epic').id
  feature = Tracker.find_by_name('Feature').id
  story = Tracker.find_by_name('Story').id
  task = Tracker.find_by_name('Task').id
  release = '__release'
  sprint = '__sprint'
  team = '__team'
  state = '__state'

  #1.2
  board = RbGenericboard.new
  board.name = "1.2 Establish epics and features"
  board.col_type = feature
  board.element_type = feature
  board.row_type = epic
  board.save!

  #1.3
  board = RbGenericboard.new
  board.name = "1.3 Put features in release"
  board.col_type = release
  board.element_type = feature
  board.row_type = Tracker.find_by_name('Epic').id
  board.save!

  #2.1
  board = RbGenericboard.new
  board.name = "2.1 Establish stories for features"
  board.col_type = story
  board.element_type = story
  board.row_type = feature
  board.prefilter = '__current_release'
  board.save!

  #2.2
  board = RbGenericboard.new
  board.name = "2.2 Assign stories to teams"
  board.col_type = team
  board.element_type = story
  board.row_type = feature
  board.prefilter = '__current_release'
  board.save!

  #2.3
  board = RbGenericboard.new
  board.name = "2.3 Plan release sprints"
  board.col_type = sprint
  board.element_type = story
  board.row_type = team
  board.prefilter = '__current_release __my_team'
  board.save!

  #2.4
  board = RbGenericboard.new
  board.name = "2.4 View release plan by Ffature"
  board.col_type = sprint
  board.element_type = story
  board.row_type = feature
  board.prefilter = '__current_release'
  board.save!

  #3.1
  board = RbGenericboard.new
  board.name = "3.1 View selected product backlog"
  board.col_type = story
  board.element_type = story
  board.row_type = sprint
  board.prefilter = '__current_sprint __my_team'
  board.save!

  #3.2
  board = RbGenericboard.new
  board.name = "3.2 Manage sprint backlog"
  board.col_type = state
  board.element_type = task
  board.row_type = story
  board.prefilter = '__current_sprint __my_team'
  board.save!

end

Given(/^I am viewing the boards page$/) do
  first_genericboard_id = RbGenericboard.order(:name).first.id
  visit url_for(:controller => :projects, :action => :show, :id => @project.identifier, :only_path=>true)
  verify_request_status(200)
  click_link("Boards")
  page.current_path.should == url_for(:controller => :rb_genericboards, :action => :show, :genericboard_id => first_genericboard_id, :project_id => @project.identifier, :only_path=>true)
  verify_request_status(200)
end

Then(/^the scaled agile tracker fields should be set to their correct trackers$/) do
    field = find_field('settings[epic_trackers][]')
    field.value.should == ["#{Tracker.find_by_name('Epic').id}"]

    field = find_field('settings[feature_trackers][]')
    field.value.should == ["#{Tracker.find_by_name('Feature').id}"]

    field = find_field('settings[default_epic_tracker]')
    field.value.should == "#{Tracker.find_by_name('Epic').id}"

    field = find_field('settings[default_feature_tracker]')
    field.value.should == "#{Tracker.find_by_name('Feature').id}"
end