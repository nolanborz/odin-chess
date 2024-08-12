class Board
  require_relative 'king'
  attr_reader :current_player, :columns_arr
  def initialize
    @current_player = nil
    @columns_arr = [1, 2, 3, 4, 5, 6, 7, 8]
  end
end

roger = Board.new
dog = King.new(1, 1, :black)