class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include AccountLocation

  before_filter :set_time_zone

  helper :all # include all helpers, all the time

  @@colors = []

  def current_account
    return @current_account unless @current_account.nil?
    
    if impersonating?
      @current_account = current_user.account
    else
      @current_account = Account.find_by_domain(account_subdomain) unless account_subdomain.nil?
    end
    @current_account
  end
  helper_method :current_account

  protected
  def impersonating?
    !(session[:real_user_id].nil?)
  end
  
  def login_from_feed_token
    if params[:feed_token] && !logged_in? && request.format.to_s == 'application/atom+xml'
      self.current_user = User.find_by_feed_token(params[:feed_token])
      yield
      self.current_user = :false
    else
      yield
    end
  end

  def all_users
    current_account.all_users
  end
  helper_method :all_users

  def enabled_users
    current_account.enabled_users
  end
  helper_method :enabled_users

  def find_user(id)
    @indexed_users ||= all_users.group_by(&:id)
    @indexed_users[id.to_i].first
  end
  helper_method :find_user

  def domain_required
    # Impersonating a user - don't validate doman
    return if impersonating?
    
    # No subdomain - redirect to public root (scorekeepr.dk)
    redirect_to public_root_url and return false if account_subdomain.blank?
    
    # Subdomain and current account's subdomain do not match - redirect to current account's subdomain
    redirect_to account_url(current_user.account.domain) and return false if logged_in? && current_account.domain != account_subdomain
    
    # User not logged in and no domain exists with the current subdomain
    redirect_to public_root_url(:host => account_domain) and return false if !logged_in? && Account.find_by_domain(account_subdomain).nil?
    
    # We are where we're supposed to be!
    true
  end

  def current_game
    if @current_game.nil?
      return unless current_account
      @current_game ||= current_account.games.first(:conditions => { :id => session[:current_game_id] }) if session[:current_game_id]
      @current_game ||= current_account.games.first
      unless @current_game.nil?
        session[:current_game_id] ||= @current_game.id
      else
        redirect_to games_url unless %w(games sessions users accounts).include?(controller_name)
      end
    end
    @current_game
  end
  helper_method :current_game

  def current_game=(game)
    session[:current_game_id] = game.id
    @current_game = game
  end

  def current_users_games
    if @current_users_games.nil?
      current_user.cache_game_ids = '' if current_user.cache_game_ids.blank?
      @current_users_games = {:played => [], :not_played => [], :locked => []}
      current_account.all_games.each do |game|
        if game.locked?
          @current_users_games[:locked] << game
        elsif current_user.cache_game_ids.split(',').include?(game.id.to_s)
          @current_users_games[:played] << game
        else
          @current_users_games[:not_played] << game
        end
      end
    end
    @current_users_games
  end
  helper_method :current_users_games

  def time_periods
    [
     ['30 days'[], 30],
     ['90 days'[], 90],
     ['180 days'[], 180],
     ['360 days'[], 360]
    ]
  end
  helper_method :time_periods

  def setup_ranking_graph
    chart = FlashChart.new
    chart.title ' '
    chart.set_y_max y_max
    chart.set_y_min y_min
    chart.y_label_steps y_axis_steps(y_min, y_max)
    chart.set_y_legend('Ranking'[], 12, '#000000')

    chart
  end

  def colors
    if @@colors.size == 0
      [0.8, 0.4, 1.0, 0.6].each do |saturation|
        [0.6, 0.9, 0.3, 0.75].each do |light|
          [0, 0.15, 0.3, 0.5, 0.6, 0.75, 0.9, 1.0].each do |hue|
            color = ::Color::HSL.from_fraction(hue, saturation, light)
            @@colors << color.html
          end
        end
      end
    end
    @@colors
  end
  helper_method :colors

  def y_max
    max = [Membership.all_time_high(current_game).current_ranking, 2000].max
    (max / 100.0).ceil * 100 # Round up to nearest 100
  end

  def y_min
    min = [Membership.all_time_low(current_game).current_ranking, 2000].min
    (min / 100.0).floor * 100 # Round down to nearest 100
  end

  def y_axis_steps(min, max)
    (max - min) / 100
  end

  def must_be_account_admin
    redirect_to root_url unless current_user.is_account_admin? || current_user.is_admin?
  end

  def must_be_admin
    redirect_to root_url unless logged_in? && current_user.is_admin?
  end

  def impersonating?
    !session[:real_user_id].blank?
  end

  def must_be_impersonating
    redirect_to root_url unless impersonating?
  end

  private
  def set_time_zone
    Time.zone = current_user.time_zone if logged_in?
  end

  def set_language
    session[:language] = params[:language] || session[:language]
    Gibberish.use_language(session[:language]) { yield }
  end
end
