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
  board = RbGenericboard.new
  board.name = "Establish epics and Features"
  board.col_type = Tracker.find_by_name('Feature').id
  board.element_type = Tracker.find_by_name('Feature').id
  board.row_type = Tracker.find_by_name('Epic').id
  board.save!
  #puts board

  board = RbGenericboard.new
  board.name = "Plan Features into Releases"
  board.col_type = '__release'
  board.element_type = Tracker.find_by_name('Feature').id
  board.row_type = Tracker.find_by_name('Epic').id
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