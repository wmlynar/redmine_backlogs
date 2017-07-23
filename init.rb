require 'redmine'

if Rails::VERSION::MAJOR < 3
  require 'dispatcher'
  object_to_prepare = Dispatcher
else
  object_to_prepare = Rails.configuration
  # if redmine plugins were railties:
  # object_to_prepare = config
end
object_to_prepare.to_prepare do
  require_dependency 'backlogs_redmine3nestedset_mixin'
  require_dependency 'backlogs_activerecord_mixin'
  require_dependency 'backlogs_setup'
  require_dependency 'issue'

  if Issue.const_defined? "SAFE_ATTRIBUTES"
    Issue::SAFE_ATTRIBUTES << "story_points"
    Issue::SAFE_ATTRIBUTES << "position"
    Issue::SAFE_ATTRIBUTES << "remaining_hours"
  else
    Issue.safe_attributes "story_points", "position", "remaining_hours"
  end

  if (Redmine::VERSION::MAJOR > 2) || (Redmine::VERSION::MAJOR == 2 && Redmine::VERSION::MINOR >= 3)
    require_dependency 'backlogs_time_report_patch'
  end
  require_dependency 'backlogs_issue_query_patch'
  require_dependency 'backlogs_issue_patch'
  require_dependency 'backlogs_issue_status_patch'
  require_dependency 'backlogs_tracker_patch'
  require_dependency 'backlogs_version_patch'
  require_dependency 'backlogs_project_patch'
  require_dependency 'backlogs_user_patch'
  require_dependency 'backlogs_custom_field_patch'

  require_dependency 'backlogs_my_controller_patch'
  require_dependency 'backlogs_issues_controller_patch'
  require_dependency 'backlogs_projects_helper_patch'

  require_dependency 'backlogs_hooks'

  require_dependency 'backlogs_merged_array'

  require_dependency 'backlogs_printable_cards'
  require_dependency 'linear_regression'

  Redmine::AccessControl.permission(:manage_versions).actions << "rb_sprints/close_completed"
end


Redmine::Plugin.register :redmine_backlogs do
  name 'Redmine Backlogs Fork'
  author "friflaj, Mark Maglana, John Yani, mikoto20000, Frank Blendinger, Bo Hansen, stevel, Patrick Atamaniuk, TheMagician1"
  description 'A plugin for agile teams'
  version 'v2.0.2'

  settings :default => {
                         :epic_trackers             => nil,
                         :story_trackers            => nil,
                         :default_story_tracker     => nil,
                         :task_tracker              => nil,
                         :card_spec                 => nil,
                         :story_close_status_id     => '0',
                         :taskboard_card_order      => 'story_follows_tasks',
                         :story_points              => "1,2,3,5,8",
                         :story_points_are_integer  => 'enabled',
                         :show_burndown_in_sidebar  => 'enabled',
                         :show_project_name         => nil,
                         :scrum_stats_menu_position => 'top',
                         :show_redmine_std_header   => 'enabled',
                         :show_priority             => nil,
                         :use_one_product_backlog   => nil,
                         :always_allow_time_fields  => nil,
                         :show_sprint_as_roadmap    => 'enabled',
                         :hide_roadmap              => nil,
                         :use_remaining_hours       => 'enabled'
                       },
           :partial => 'backlogs/settings'

  project_module :backlogs do
    # SYNTAX: permission :name_of_permission, { :controller_name => [:action1, :action2] }

    # Master backlog permissions
    permission :reset_sprint,         {
                                        :rb_sprints           => :reset
                                      }
    permission :configure_backlogs,   { :rb_project_settings => :project_settings }
    permission :view_master_backlog,  {
                                        :rb_master_backlogs  => [:show, :menu, :closed_sprints],
                                        :rb_sprints          => [:index, :show, :download],
                                        :rb_sprints_roadmap  => [:index, :show, :download],
                                        :rb_hooks_render     => [:view_issues_sidebar],
                                        :rb_wikis            => :show,
                                        :rb_stories          => [:index, :show, :tooltip],
                                        :rb_queries          => [:show, :impediments],
                                        :rb_server_variables => [:project, :sprint, :index],
                                        :rb_burndown_charts  => [:embedded, :show, :print],
                                        :rb_updated_items    => :show
                                      }

    permission :manage_generic_boards, {
                                        :rb_genericboards_admin => [ :index, :new, :create, :edit, :update, :destroy ],
                                      }

    permission :view_epicboards,      {
                                        :rb_epicboards       => :show
                                      }

    permission :view_releases,        {
                                        :rb_releases         => [:index, :show],
                                        :rb_sprints          => [:index, :show, :download],
                                        :rb_sprints_roadmap  => [:index, :show],
                                        :rb_wikis            => :show,
                                        :rb_stories          => [:index, :show, :tooltip],
                                        :rb_server_variables => [:project, :sprint, :index],
                                        :rb_burndown_charts  => [:embedded, :show, :print],
                                        :rb_updated_items    => :show
                                      }

    permission :view_taskboards,      {
                                        :rb_genericboards    => [ :show, :index, :update, :create ],
                                        :rb_taskboards       => [:current, :show],
                                        :rb_sprints          => :show,
                                        :rb_sprints_roadmap  => [:index, :show],
                                        :rb_stories          => [:index, :show, :tooltip],
                                        :rb_tasks            => [:index, :show],
                                        :rb_impediments      => [:index, :show],
                                        :rb_wikis            => :show,
                                        :rb_server_variables => [:project, :sprint, :index],
                                        :rb_hooks_render     => [:view_issues_sidebar],
                                        :rb_burndown_charts  => [:embedded, :show, :print],
                                        :rb_updated_items    => :show
                                      }

    # Release permissions
    permission :modify_releases,      {
                                        :rb_releases => [:new, :create, :edit, :update, :snapshot, :destroy],
                                        :rb_releases_multiview => [:new, :show, :edit, :destroy]
                                      }

    # Sprint permissions
    # :show_sprints and :list_sprints are implicit in :view_master_backlog permission
    permission :create_sprints,      {
                                        :rb_sprints => [:new, :create],
                                        :rb_sprints_roadmap => [:new, :create]
                                     }
    permission :update_sprints,      {
                                        :rb_sprints => [:edit, :update, :close],
                                        :rb_sprints_roadmap => [:edit, :update, :close],
                                        :rb_wikis   => [:edit, :update]
                                     }

    # Epic permissions
    permission :create_epics,         { :rb_epics => :create }
    permission :update_epics,         { :rb_epics => :update }

    # Story permissions
    # :show_stories and :list_stories are implicit in :view_master_backlog permission
    permission :create_stories,         { :rb_stories => :create }
    permission :update_stories,         { :rb_stories => :update }

    # Task permissions
    # :show_tasks and :list_tasks are implicit in :view_sprints
    permission :create_tasks,           { :rb_tasks => [:new, :create] }
    permission :update_tasks,           { :rb_tasks => [:edit, :update] }

    permission :update_remaining_hours, { :rb_tasks => [:edit, :update] }

    # Impediment permissions
    # :show_impediments and :list_impediments are implicit in :view_sprints
    permission :create_impediments,     { :rb_impediments => [:new, :create]  }
    permission :update_impediments,     { :rb_impediments => [:edit, :update] }

    permission :subscribe_to_calendars,  { :rb_calendars  => :ical }
    permission :view_scrum_statistics,   { :rb_all_projects => :statistics }
  end

  # http://www.redmine.org/boards/3/topics/16587
  delete_menu_item :project_menu, :roadmap
  menu :project_menu, :roadmap, { :controller => 'versions', :action => 'index' }, :after => :activity, :param => :project_id,
              :if => Proc.new { |p| p.shared_versions.any? && (!Backlogs.configured? || (Backlogs.configured? && !Backlogs.setting[:hide_roadmap])) }

  menu :project_menu, :rb_sprints, { :controller => :rb_sprints_roadmap, :action => :index }, :caption => :label_sprints, :after => :roadmap, :param => :project_id, :if => Proc.new { Backlogs.configured? && Backlogs.setting[:show_sprint_as_roadmap] }
  menu :project_menu, :rb_master_backlogs, { :controller => :rb_master_backlogs, :action => :show }, :caption => :label_backlogs, :after => :rb_sprints, :param => :project_id, :if => Proc.new { Backlogs.configured? }
  menu :project_menu, :rb_epicboards, { :controller => :rb_epicboards, :action => :show }, :caption => :label_epics, :after => :rb_master_backlogs, :param => :project_id, :if => Proc.new { Backlogs.configured? }
  menu :project_menu, :rb_taskboards, { :controller => :rb_taskboards, :action => :current }, :caption => :label_task_board, :after => :rb_epicboards, :param => :project_id, :if => Proc.new {|project| Backlogs.configured? && project && project.active_sprint }
  menu :project_menu, :rb_releases, { :controller => :rb_releases, :action => :index }, :caption => :label_release_plural, :after => :rb_taskboards, :param => :project_id, :if => Proc.new { Backlogs.configured? }
  menu :project_menu, :rb_genericboards, { :controller => :rb_genericboards, :action => :index },
    :caption => :label_rb_genericboard_plural, :after => :rb_releases, :param => :project_id,
    :if => Proc.new { Backlogs.configured? && Backlogs.setting[:scaled_agile_enabled] && RbGenericboard.count > 0 }

  menu :top_menu, :rb_statistics, { :controller => :rb_all_projects, :action => :statistics}, :caption => :label_scrum_statistics,
    :if => Proc.new {
      Backlogs.configured? &&
      User.current.allowed_to?({:controller => :rb_all_projects, :action => :statistics}, nil, :global => true) &&
      (Backlogs.setting[:scrum_stats_menu_position].nil? || Backlogs.setting[:scrum_stats_menu_position] == 'top')
    }
  menu :application_menu, :rb_statistics, { :controller => :rb_all_projects, :action => :statistics}, :caption => :label_scrum_statistics,
    :if => Proc.new {
      Backlogs.configured? &&
      User.current.allowed_to?({:controller => :rb_all_projects, :action => :statistics}, nil, :global => true) &&
      Backlogs.setting[:scrum_stats_menu_position] == 'application'
    }

  menu :admin_menu, :rb_genericboards_admin, { :controller => :rb_genericboards_admin, :action => :index },
    :caption => :label_configure_genericboards, :if => Proc.new { Backlogs.configured? }
end
