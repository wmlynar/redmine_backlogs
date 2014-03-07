include RbCommonHelper
include RbGenericboardsHelper

class RbGenericboardsController < RbApplicationController
  unloadable

  before_filter :find_rb_genericboard, :except => [ :index ]

  def index
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
