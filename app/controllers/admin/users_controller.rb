module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update, :destroy, :convict]

    def index
      @users = User.order(created_at: :desc).page(params[:page]).per(25)
    end

    def show
      @heartbeats_count = @user.heartbeats.count
      @recent_heartbeats = @user.heartbeats.order(time: :desc).limit(10)
    end

    def edit
    end

    def update
      if @user.update(user_params)
        flash[:notice] = "User updated successfully."
        redirect_to admin_user_path(@user)
      else
        flash.now[:alert] = "Failed to update user."
        render :edit, status: :unprocessable_entity
      end
    end

    def convict
      old_trust_level = @user.trust_level_before_type_cast
      new_trust_level = User.trust_levels[params[:trust_level]]

      if @user.update(trust_level: params[:trust_level])
        TrustLevelAuditLog.create!(
          user: @user,
          admin: current_user,
          old_trust_level: old_trust_level,
          new_trust_level: new_trust_level,
          reason: params[:reason]
        )
        flash[:notice] = "Trust level updated to #{params[:trust_level]}."
      else
        flash[:alert] = "Failed to update trust level."
      end

      redirect_to admin_user_path(@user)
    end

    def destroy
      @user.destroy!
      flash[:notice] = "User deleted."
      redirect_to admin_users_path
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:username, :email, :display_name, :timezone, :admin_level, :trust_level)
    end
  end
end
