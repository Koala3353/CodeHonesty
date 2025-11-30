class UsersController < ApplicationController
  before_action :require_login
  before_action :set_user, only: [:show, :update]

  def show
  end

  def settings
    @user = current_user
    @api_keys = current_user.api_keys
  end

  def update
    @user = current_user
    if @user.update(user_params)
      flash[:notice] = "Settings updated successfully."
      redirect_to settings_users_path
    else
      flash.now[:alert] = "Failed to update settings."
      render :settings, status: :unprocessable_entity
    end
  end

  def create_api_key
    @api_key = current_user.api_keys.create!(name: params[:name].presence || "New API Key")
    flash[:notice] = "API key created: #{@api_key.token}"
    redirect_to settings_users_path
  rescue => e
    flash[:alert] = "Failed to create API key: #{e.message}"
    redirect_to settings_users_path
  end

  def destroy_api_key
    api_key = current_user.api_keys.find(params[:id])
    api_key.destroy!
    flash[:notice] = "API key deleted."
    redirect_to settings_users_path
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "API key not found."
    redirect_to settings_users_path
  end

  private

  def set_user
    @user = User.find_by!(username: params[:username] || params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "User not found."
    redirect_to root_path
  end

  def user_params
    params.require(:user).permit(:username, :timezone, :display_name)
  end
end
