# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include GDocs4Ruby
  
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
   filter_parameter_logging :password
  
  def authenticate
    if not session[:username] or not session[:password]
      redirect_to :action => :login and return
    end
    @account = Service.new()
    @account.debug = true
    @account.authenticate(session[:username], session[:password])
  end
end
