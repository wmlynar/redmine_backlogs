class RbGeneric < Issue
  unloadable

  RELEASE_RELATIONSHIP = %w(auto initial continued added)

  private

  public

  def self.trackers(options = {})
    self.get_trackers(:story_trackers, options)
  end

  def self.epic_trackers(options = {})
    self.get_trackers(:epic_trackers, options)
  end

  def self.feature_trackers(options = {})
    self.get_trackers(:feature_trackers, options)
  end

  def self.get_trackers(trackersettings, options = {})
    # legacy
    options = {:type => options} if options.is_a?(Symbol)

    # somewhere early in the initialization process during first-time migration this gets called when the table doesn't yet exist
    trackers = []
    if has_settings_table
      trackers = Backlogs.setting[trackersettings]
      trackers = [] if trackers.blank?
    end

    trackers = Tracker.find_all_by_id(trackers)
    trackers = trackers & options[:project].trackers if options[:project]
    trackers = trackers.sort_by { |t| [t.position] }

    case options[:type]
      when :trackers      then return trackers
        when :array, nil  then return trackers.collect{|t| t.id}
        when :string      then return trackers.collect{|t| t.id.to_s}.join(',')
        else                   raise "Unexpected return type #{options[:type].inspect}"
    end
  end

  def self.has_settings_table
    ActiveRecord::Base.connection.tables.include?('settings')
  end

  def update_and_position!(params)
    params['prev'] = params.delete('prev_id') if params.include?('prev_id')
    params['next'] = params.delete('next_id') if params.include?('next_id')
    self.position!(params)

    # lft and rgt fields are handled by acts_as_nested_set
    attribs = params.select{|k,v| !['prev', 'id', 'project_id', 'lft', 'rgt'].include?(k) && RbStory.column_names.include?(k) }
    attribs = Hash[*attribs.flatten]

    return self.journalized_update_attributes attribs
  end

  def position!(params)
    if params.include?('prev')
      if params['prev'].blank?
        self.move_to_top # move after 'prev'. Meaning no prev, we go at top
      else
        self.move_after(self.class.find(params['prev']))
      end
    elsif params.include?('next')
      if params['next'].blank?
        self.move_to_bottom
      else
        self.move_before(self.class.find(params['next']))
      end
    end
  end


end
