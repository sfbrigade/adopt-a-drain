class PasswordsController < Devise::PasswordsController
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?
    if successfully_sent?(resource)
      render(json: {success: true})
    else
      render(json: {errors: resource.errors}, status: :internal_server_error)
    end
  end

  def edit
    self.resource = resource_class.new
    resource.reset_password_token = params[:reset_password_token]
    @reset_password_token = params[:reset_password_token]

    render('main/index')
  end

  def update
    self.resource = resource_class.reset_password_by_token(resource_params)

    yield resource if block_given?

    return render(json: {errors: resource.errors}, status: :internal_server_error) unless resource.errors.empty?

    resource.unlock_access! if unlockable?(resource)
    sign_in(resource_name, resource)

    flash[:notice] = 'Password updated!'
    render json: {}
  end

private

  def resource_params
    params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
  end
end
