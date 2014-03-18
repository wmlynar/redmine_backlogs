include RbCommonHelper
include RbGenericboardsHelper

class RbGenericboardsController < RbApplicationController
  unloadable

  before_filter :find_rb_genericboard, :except => [ :index ]

  private

  def process_params(params)
    row_id = params.delete(:row_id)
    col_id = params.delete(:col_id)

    #determine issue tracker to use
    if col_id == 'rowelement'
      cls_hint = 'rowelement'
      object_type = @rb_genericboard.row_type
      rowelement = true
    else
      cls_hint = 'task'
      object_type = @rb_genericboard.element_type
      rowelement = false
    end
    if object_type.start_with? '__'
      render :text => e.message.blank? ? e.to_s : e.message, :status => 400
    end
    params[:tracker_id] = object_type.to_i
    #puts "Determined tracker to #{params[:tracker_id]}"
    #puts "Which is #{Tracker.find(params[:tracker_id])}"


    #determine project
    # 1. take project of parent (the row element)
    row_id = row_id.to_i
    row_object = @rb_genericboard.row_object(row_id)
    puts "Row object #{row_object}"
    col_id = col_id.to_i
    col_object = @rb_genericboard.col_object(col_id)
    puts "Col object #{col_object}"

    if (row_id > 0 && row_object.respond_to?(:project))
      project_id = row_object.project.id
      puts "Using row for project"
    elsif (col_id > 0 && col_object.respond_to?(:project))
      # 2. take project or column if applicable
      project_id = col_object.project.id
      puts "Using col for project"
    else
      # 3. fall back to current project
      project_id = @project.id
      puts "Using default project"
    end
    puts "Determined project to be #{project_id}"

    #determine parent, release and sprint
    parent_id = nil
    sprint_id = nil
    release_id = nil
    rbteam_id = nil
    if (row_object && !rowelement)
      if row_object.is_a? RbGeneric
        parent_id = row_object.id
        project_id = row_object.project.id
        release_id = row_object.release_id
        sprint_id = row_object.fixed_version_id
        #FIXME determine release/sprint/project from row parent unless specified by column
      elsif row_object.is_a? RbSprint
        sprint_id = row_object.id
        #FIXME it seems that sharing scope is not obeyed, we might drag stories from non-shared project into sprints resulting in an error
      elsif row_object.is_a? RbRelease
        release_id = row_object.id
      elsif row_object.is_a? Group
        rbteam_id = row_object.id
        puts "Set rbteam_id from row #{rbteam_id}"
      end
    end
    if (col_object && !rowelement)
      if col_object.is_a? RbGeneric
        parent_id = col_object.id
        project_id = col_object.project.id
        release_id = col_object.release_id
        sprint_id = col_object.fixed_version_id
      elsif col_object.is_a? RbSprint
        sprint_id = col_object.id
      elsif col_object.is_a? RbRelease
        release_id = col_object.id
      elsif col_object.is_a? Group
        rbteam_id = col_object.id
        puts "Set rbteam_id from col #{rbteam_id}"
      end
    end
    puts "Determined parent #{parent_id}, sprint #{sprint_id}, release #{release_id}, team #{rbteam_id}, project #{project_id}"
    params[:parent_issue_id] = parent_id if parent_id
    params[:fixed_version_id] = sprint_id if sprint_id
    params[:release_id] = release_id if release_id
    params[:rbteam_id] = rbteam_id if rbteam_id
    params[:project_id] = project_id

    return params, cls_hint
  end

  public

  def index
    board = RbGenericboard.order(:name).first
    if board
      redirect_to :controller => 'rb_genericboards', :action => 'show', :genericboard_id => board, :project_id => @project
      return
    end
    respond_to do |format|
      format.html { redirect_back_or_default(project_url(@project)) }
    end
  end


  def show
    @filteroptions = params.select{|k,v| k.starts_with?('__')}
    @rows = @rb_genericboard.rows(@project, @filteroptions).to_a
    @rows.append(RbFakeGeneric.new("No #{@rb_genericboard.row_type_name}"))
    @columns = @rb_genericboard.columns(@project, @filteroptions).to_a
    @elements_by_cell = @rb_genericboard.elements_by_cell(@project, @filteroptions)
    @all_boards = RbGenericboard.all
    respond_to do |format|
      format.html { render :layout => "rb" }
    end
  end

  def create
    params['author_id'] = User.current.id
    attrs, cls_hint = process_params(params)

    puts "Creating generic with attrs #{attrs}"
    begin
      story = RbGeneric.create_and_position(attrs)
    rescue => e
      render :text => e.message.blank? ? e.to_s : e.message, :status => 400
      return
    end

    if attrs[:parent_issue_id]
      story.parent_issue_id = attrs[:parent_issue_id]
      story.save!
    end


    status = (story.id ? 200 : 400)

    respond_to do |format|
      format.html { render :partial => "generic", :object => story, :status => status, :locals => {:cls => cls_hint} }
    end
  end

  def update
    story = RbGeneric.find(params[:id])
    attrs, cls_hint = process_params(params)

    puts "Genericboard update #{story} #{attrs} #{cls_hint} #{@rb_genericboard}"
    begin
      result = story.update_and_position!(attrs)
    rescue => e
      render :text => e.message.blank? ? e.to_s : e.message, :status => 400
      return
    end
    if attrs[:parent_issue_id]
      story.parent_issue_id = attrs[:parent_issue_id]
      story.save!
    end

    status = (result ? 200 : 400)
    respond_to do |format|
      format.html { render :partial => "generic", :object => story, :status => status, :locals => {:cls => cls_hint} }
    end
  end

  def find_rb_genericboard
    @rb_genericboard = RbGenericboard.find(params[:genericboard_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
