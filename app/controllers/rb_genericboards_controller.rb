include RbCommonHelper
include RbGenericboardsHelper

class RbGenericboardsController < RbApplicationController
  unloadable

  before_filter :find_rb_genericboard, :except => [ :index ]

  def index
    board = RbGenericboard.order(:name).first
    if board
      redirect_to :controller => 'rb_genericboards', :action => 'show', :id => board
      return
    end
    respond_to do |format|
      format.html { redirect_back_or_default(project_url(@project)) }
    end
  end


  def show
    @rows = @rb_genericboard.rows(@project).to_a
    @rows.append(RbFakeGeneric.new("No #{@rb_genericboard.row_type_name}"))
    @columns = @rb_genericboard.columns(@project).to_a
    @elements_by_cell = @rb_genericboard.elements_by_cell(@project)
    @all_boards = RbGenericboard.all
    respond_to do |format|
      format.html { render :layout => "rb" }
    end
  end

  def create

  end

  def update
    story = RbGeneric.find(params[:id])
    row_id = params[:row_id]
    col_id = params[:col_id]
    puts "Genericboard update #{story} #{row_id} #{col_id} #{params} #{@rb_genericboard}"
    begin
      result = story.update_and_position!(params)
    rescue => e
      render :text => e.message.blank? ? e.to_s : e.message, :status => 400
      return
    end

    status = (result ? 200 : 400)
    puts "rendering updated story #{story}"
    respond_to do |format|
      format.html { render :partial => "generic", :object => story, :status => status }
    end
  end

  def find_rb_genericboard
    @rb_genericboard = RbGenericboard.find(params[:genericboard_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
