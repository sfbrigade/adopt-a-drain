class ThingsController < ApplicationController
  respond_to :json

  def show
    @things = Thing.find_closest(params[:lat], params[:lng], params[:limit] || 10)

    unless @things.blank?
      for t in @things
          if user_signed_in? && current_user == t.user then
            t.owned_by_you = true
          else
            t.owned_by_you = false
          end
      end
      render(:json => @things.to_json(:methods => :owned_by_you))
    else
      render(:json => {"errors" => {"address" => [t("errors.not_found", :thing => t("defaults.thing"))]}}, :status => 404)
    end
  end

  def update
    @thing = Thing.find(params[:id])
    if @thing.update_attributes(thing_params)
      ThingMailer.adopted_confirmation(@thing).deliver if @thing.adopted?

      respond_with @thing
    else
      render(json: {errors: @thing.errors}, status: 500)
    end
  end

private

  def thing_params
    params.require(:thing).permit(:name, :user_id)
  end
end
