require_relative 'board'
require 'yaml'

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
    puts "Type 'save' to save the game"
    puts "Type 'load' to load a saved game"
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
      input = get_move_input
      case input
      when 'save'
        save_game
        next
      when 'load'
        if load_game
          @board.display
          next
        else
          next
        end
      end
      
      from, to = input
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
      print "Enter move (e.g., e2 e4), 'save', 'load', or 'quit': "
      input = gets.chomp.downcase
      case input
      when 'quit', 'exit'
        puts "Thanks for playing!"
        exit
      when 'save'
        return 'save'
      when 'load'
        return 'load'
      else
        move = input.split
        if move.length == 2 && move.all? { |square| valid_square?(square) }
          return move
        else
          puts "Invalid input. Please use the format 'e2 e4' or type 'save', 'load', or 'quit'."
        end
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

  def save_game
    puts 'Saving game...'
    game_state = {
      board: @board,
      current_player_color: @current_player.color
    }
    yaml = YAML.dump(game_state)
    File.open('saved_game.yml', 'w') { |file| file.write(yaml) }
    puts 'Game saved successfully.'
  end

  def load_game
    if File.exist?('saved_game.yml')
      yaml = File.read('saved_game.yml')
      begin
        game_state = YAML.safe_load(yaml, 
          permitted_classes: [Symbol, Board, Piece, Pawn, Rook, Knight, Bishop, Queen, King],
          aliases: true
        )
        @board = game_state[:board]
        @current_player = (game_state[:current_player_color] == :white) ? @player_white : @player_black
        @board.set_current_player(@current_player.color)
        puts 'Game loaded successfully.'
        @board.display
        true
      rescue => e
        puts "Error loading game: #{e.message}"
        puts e.backtrace
        false
      end
    else
      puts "No saved game found."
      false
    end
  end
end

if __FILE__ == $0
  game = Game.new
  game.setup_game
end

nolan = Game.new
nolan.setup_game
