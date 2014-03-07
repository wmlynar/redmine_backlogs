include RbCommonHelper
include RbGenericboardsHelper

class RbGenericboardsController < RbApplicationController
  unloadable

  before_filter :find_rb_genericboard, :except => [:index, :new, :create, :show_first]
  before_filter :authorize_global, :except => [:show, :data, :show_first]
  skip_before_filter :load_project, :except => [:show, :data, :show_first]
  skip_before_filter :authorize, :except => [:show, :data, :show_first]

  def show_first
    puts "XXXXXX"
    board = RbGenericboard.all.first
    puts board
    if board
      redirect_to :controller => 'rb_genericboards', :action => 'show', :id => board
      return
    end
    respond_to do |format|
      format.html { redirect_back_or_default(project_url(@project)) }
    end
  end
  def index
    @rb_genericboards = RbGenericboard.all
  end

  def new
    @rb_genericboard = RbGenericboard.new
  end

  def create
    @rb_genericboard = RbGenericboard.new
    @rb_genericboard.safe_attributes = params[:rb_genericboard]
    respond_to do |format|
      if @rb_genericboard.save
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to(params[:continue] ? new_rb_genericboard_path : rb_genericboards_path)
        }
      else
        format.html { render :action => "new" }
      end
    end

  end

  def edit
  end

  def update
    @rb_genericboard.safe_attributes = params[:rb_genericboard]

    respond_to do |format|
      if @rb_genericboard.save
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to(rb_genericboards_path) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @rb_genericboard.destroy

    respond_to do |format|
      format.html { redirect_to(rb_genericboards_url) }
    end
  end

  def show
    @rows = @rb_genericboard.rows(@project).to_a
    @rows.append(RbFakeGeneric.new("No #{@rb_genericboard.row_type_name}"))
    @columns = @rb_genericboard.columns(@project).to_a
    @elements_by_cell = @rb_genericboard.elements_by_cell(@project)
    respond_to do |format|
      format.html { render :layout => "rb" }
    end
  end

  def data
    data = {
      :row_type_name => @rb_genericboard.row_type_name,
      :col_type_name => @rb_genericboard.col_type_name,
      :rows => @rb_genericboard.rows(@project).to_a,
      :columns => @rb_genericboard.columns(@project).to_a,
      :elements_by_cell => @rb_genericboard.elements_by_cell(@project)
    }
    respond_to do |format|
      format.html { render :json => data }
    end
  end

  def find_rb_genericboard
    @rb_genericboard = RbGenericboard.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
