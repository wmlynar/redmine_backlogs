include RbCommonHelper

#rb_boards GET      /rb/boards(.:format)                                                              boards#index
# POST     /rb/boards(.:format)                                                              boards#create
# new_rb_board GET      /rb/boards/new(.:format)                                                          boards#new
# edit_rb_board GET      /rb/boards/:id/edit(.:format)                                                     boards#edit
# rb_board GET      /rb/boards/:id(.:format)                                                          boards#show
# PUT      /rb/boards/:id(.:format)                                                          boards#update
# DELETE   /rb/boards/:id(.:format)                                                          boards#destroy

class RbGenericboardsController < ApplicationController
  unloadable

  before_filter :authorize_global
  def index
    respond_to do |format|
      format.html { render :layout => "rb" }
    end
  end

  def show
    respond_to do |format|
      format.html { render :layout => "rb" }
    end
  end
end
