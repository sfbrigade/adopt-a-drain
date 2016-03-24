class EditWindowController < ApplicationController
  def index
    @thing = Thing.find_by_id(params[:thing_id])
    render 'things/rename'
  end
end
