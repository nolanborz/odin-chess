require_relative 'board'

class Player
  attr_reader :color

  def initialize(color)
    @color = color
  end
end

class Game
  def initialize
    @board = Board.new
    @player_white = Player.new(:white)
    @player_black = Player.new(:black)
    @current_player = @player_white
    @board.set_current_player(@current_player.color)
  end

  def setup_game
    puts "Welcome to Ruby Chess!"
    puts "Enter moves in the format 'e2 e4'"
    puts "Type 'quit' or 'exit' to end the game"
    puts "-------------------------"
    @board.display
    play_game
  end

  def play_game
    loop do
      make_move
      break if game_over?
      switch_players
    end
    announce_result
  end

  def make_move
    loop do
      puts "#{@current_player.color.capitalize}'s turn"
      from, to = get_move_input
      from_x, from_y = convert_notation(from)
      to_x, to_y = convert_notation(to)
      
      if @board.move_piece(from_x, from_y, to_x, to_y)
        @board.display
        break
      else
        puts "Invalid move. Try again."
      end
    end
  end

  def get_move_input
    loop do
      print "Enter move (e.g., e2 e4): "
      input = gets.chomp.downcase
      if input == 'quit' || input == 'exit'
        puts "Thanks for playing!"
        exit
      elsif input == 'save' || input == 'save game'
        puts "Saving game, you can continue this later."
        exit
      end
      
      move = input.split
      if move.length == 2 && move.all? { |square| valid_square?(square) }
        return move
      else
        puts "Invalid input. Please use the format 'e2 e4' or type 'quit' to exit."
      end
    end
  end

  def switch_players
    @current_player = (@current_player == @player_white) ? @player_black : @player_white
    @board.set_current_player(@current_player.color)
  end

  def game_over?
    [:white, :black].each do |color|
      if @board.is_checkmate?(color)
        puts "Checkmate! #{color.capitalize} loses."
        return true
      elsif @board.is_stalemate?(color)
        puts "Stalemate! The game is a draw."
        return true
      end
    end
    false
  end

  def announce_result
    # Implement game result announcement here
    puts "Game Over!"
  end

  def valid_square?(square)
    square.match?(/^[a-h][1-8]$/)
  end

  def convert_notation(square)
    col = square[0].ord - 'a'.ord
    row = square[1].to_i - 1
    [row, col]
  end
end

nolan = Game.new
nolan.setup_game
