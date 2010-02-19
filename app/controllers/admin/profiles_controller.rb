class Admin::ProfilesController < Admin::BaseController
  helper Admin::UsersHelper
  
  def index
    @user = current_user
    @profiles = Profile.find(:all, :order => 'id')
    @user.attributes = params[:user]
    if request.post? and @user.save
      current_user = @user
      flash[:notice] = _('User was successfully updated.')
      redirect_to :controller => '/admin', :action => 'index'
    end
  end

end
