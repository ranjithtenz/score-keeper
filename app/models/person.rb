class Person < ActiveRecord::Base
  has_many :memberships
  belongs_to :mugshot
  
  before_destroy :remove_games

  def initials
    self.full_name.split(' ').collect{ |n| n.first }.join
  end
  
  def full_name
    [self.first_name, self.last_name].compact.join(' ')
  end

  def self.find_all
    find(:all, :order => 'first_name, last_name, display_name')
  end

  def winning_percentage
    return 0.0 if memberships_count == 0
    ((games_won.to_f / memberships_count.to_f) * 1000).to_i / 10.to_f
  end
  
  def difference
    goals_for - goals_against
  end
  
  def difference_average
    return 0.0 if memberships_count == 0
    ((10 * difference) / memberships_count) / 10.0
  end
  
  protected
  def remove_games
    self.memberships.each do |membership|
      game = membership.team.game
      game.postpone_ranking_update = true
      game.destroy
    end
    
    # Fix stats
    Game.reset_rankings
  end
end
