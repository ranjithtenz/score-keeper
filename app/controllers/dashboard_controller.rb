class DashboardController < ApplicationController
  def index
    unless read_fragment(dashboard_path) && read_fragment(dashboard_path + '_sidebar')
      @people = Person.find(:all, :order => 'ranking DESC, games_won DESC, last_name')
      @recent_games = Game.find_recent(:limit => 8)
      @games_per_day = Game.count(:group => :played_on, :limit => 10, :order => 'played_on DESC')

      # Sidebar
      @leader = @people[0]
      @game_count = Game.count
      @goals_scored = (Person.sum(:goals_for) + Person.sum(:goals_against)) / 4
    end
  end
end