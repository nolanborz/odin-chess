class Board
  require_relative 'pawn'
  require_relative 'king'
  require_relative 'queen'
  require_relative 'rook'
  require_relative 'knight'
  require_relative 'bishop'

  LIGHT_SQUARE = "\e[47m   \e[0m" # White background
  DARK_SQUARE = "\e[100m   \e[0m" # Dark gray background

  attr_reader :current_player, :columns_arr, :grid

  def initialize
    @current_player = nil
    @columns_arr = [' a', ' b', ' c', ' d', ' e', ' f', ' g', ' h']
    @grid = Array.new(8) { Array.new(8) }
    @pieces = []
    setup_board
  end

  def setup_board
    8.times do |row|
      8.times do |col|
        @grid[row][col] = (row + col).even? ? LIGHT_SQUARE : DARK_SQUARE
      end
    end

    8.times do |col|
      place_piece(Pawn.new(1, col, :white))
      place_piece(Pawn.new(6, col, :black))
    end
    [:white, :black].each do |color|
      back_rank = color == :white ? 0 : 7
      place_piece(Rook.new(back_rank, 0, color))
      place_piece(Knight.new(back_rank, 1, color))
      place_piece(Bishop.new(back_rank, 2, color))
      place_piece(Queen.new(back_rank, 3, color))
      place_piece(King.new(back_rank, 4, color))
      place_piece(Bishop.new(back_rank, 5, color))
      place_piece(Knight.new(back_rank, 6, color))
      place_piece(Rook.new(back_rank, 7, color))
  end
end

  def place_piece(piece)
    x, y = piece.position
    background_color = (x + y).even? ? 47 : 100 # 47 for light, 100 for dark
    @grid[x][y] = "\e[#{background_color}m #{piece.symbol} \e[0m"
    @pieces << piece
  end

  def display
    puts "  #{@columns_arr.join(' ')}"
    @grid.reverse.each_with_index do |row, i|
      print "#{8 - i} "
      row.each { |cell| print cell }
      puts " #{8 - i}"
    end
    puts "  #{@columns_arr.join(' ')}"
  end
end

# Example usage:
board = Board.new
board.display