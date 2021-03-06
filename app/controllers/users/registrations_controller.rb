class Users::RegistrationsController < Devise::RegistrationsController
  def update
    return super if current_user.provider.nil? || current_user.password.present?

    if current_user.update_without_password(user_params)
      return redirect_to root_path, notice: "You have updated your profile"
    end

    render :edit
  end

  protected

  def after_sign_up_path_for(resource)
    new_user_session_path
  end

  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end

  private

  def user_params
    params.require(:user).permit(:address)
  end
end
