include RbCommonHelper

class RbGenericboardsController < RbApplicationController
  unloadable

  #skip_before_filter :load_project

  def show
    respond_to do |format|
      format.html { render :layout => "rb" }
    end
  end
end
