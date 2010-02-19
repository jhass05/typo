# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base
  include ::LoginSystem
  protect_from_forgery :only => [:edit, :update, :delete]
  
  before_filter :reset_local_cache, :fire_triggers, :load_lang
  after_filter :reset_local_cache

  class << self
    unless self.respond_to? :template_root
      def template_root
        ActionController::Base.view_paths.last
      end
    end

    # Log all path in file path_cache in Rails.root
    # When we sweep all cache. We just need delete this file
    def cache_page_with_log_page(content, path)
      return unless perform_caching
      cache_page_without_log_page(content, path)
      CacheInformation.create(:path => page_cache_file(path))
    end
    alias_method_chain :cache_page, :log_page
  end

  protected

  def setup_themer
    # Ick!
    self.view_paths = ::ActionController::Base.view_paths.dup.unshift("#{RAILS_ROOT}/themes/#{this_blog.theme}/views")
  end

  def error(message = "Record not found...", options = { })
    @message = message.to_s
    render :template => 'articles/error', :status => options[:status] || 404
  end

  def fire_triggers
    Trigger.fire
  end

  def load_lang
    Localization.lang = this_blog.lang
    # _("Localization.rtl") 
  end

  def reset_local_cache
    if !session
      session :session => new
    end
    @current_user = nil
  end

  # Helper method to get the blog object.
  def this_blog
    @blog ||= Blog.default
  end

  helper_method :this_blog

  # The base URL for this request, calculated by looking up the URL for the main
  # blog index page.
  def blog_base_url
    url_for(:controller => '/articles').gsub(%r{/$},'')
  end

  def add_to_cookies(name, value, path=nil, expires=nil)
    cookies[name] = { :value => value, :path => path || "/#{controller_name}",
                       :expires => 6.weeks.from_now }
  end
end

