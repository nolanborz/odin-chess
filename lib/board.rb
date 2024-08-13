class Board
  require_relative 'pawn'
  require_relative 'king'
  require_relative 'queen'
  require_relative 'rook'
  require_relative 'knight'
  require_relative 'bishop'

  LIGHT_SQUARE = "\e[47m   \e[0m" # White background
  DARK_SQUARE = "\e[100m   \e[0m" # Dark gray background

  attr_reader :current_player, :columns_arr, :grid, :captured_pieces_black, :captured_pieces_white, :pieces

  def initialize
    @current_player = :whiteg
    @columns_arr = [' a', ' b', ' c', ' d', ' e', ' f', ' g', ' h']
    @grid = Array.new(8) { Array.new(8) }
    @pieces = []
    @captured_pieces_white = []
    @captured_pieces_black = []
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

  def move_piece(from_x, from_y, to_x, to_y)
    piece = piece_at(from_x, from_y)
    return false unless piece

    if piece.color != @current_player
      puts "It's not #{piece.color}'s turn."
      return false
    end

    unless valid_move?(piece, from_x, from_y, to_x, to_y)
      puts "Invalid move for #{piece.color} #{piece.class}"
      return false
    end

    captured_piece = piece_at(to_x, to_y)
    old_position = piece.position
    make_temp_move(piece, to_x, to_y)


    if king_in_check?(piece.color)
      undo_temp_move(piece, old_position, captured_piece)
      puts "Invalid move: This would put or leave your king in check."
      return false
    end

    undo_temp_move(piece, old_position, captured_piece)
    perform_move(piece, to_x, to_y)

    if king_in_check?(opposite_color(piece.color))
      puts "Check!"
    end
    true
  end

  def king_position(color)
    @pieces.find { |p| p.is_a?(King) && p.color == color }.position
  end

  def is_square_attacked?(x, y, attacker_color)
    @pieces.any? do |piece|
      piece.color == attacker_color && valid_move?(piece, *piece.position, x, y)
    end
  end

  def king_in_check?(color)
    king_x, king_y = king_position(color)
    is_square_attacked?(king_x, king_y, opposite_color(color))
  end

  def make_temp_move(piece, to_x, to_y)
    @grid[piece.position[0]][piece.position[1]] = (piece.position[0] + piece.position[1]).even? ? LIGHT_SQUARE : DARK_SQUARE
    piece.position = [to_x, to_y]
    @grid[to_x][to_y] = "#{piece.symbol}"
  end

  def undo_temp_move(piece, old_position, captured_piece)
    current_x, current_y = piece.position
    @grid[current_x][current_y] = captured_piece ? "#{captured_piece.symbol}" : ((current_x + current_y).even? ? LIGHT_SQUARE : DARK_SQUARE)
    piece.position = old_position
    @grid[old_position[0]][old_position[1]] = "#{piece.symbol}"
  end

  def perform_move(piece, to_x, to_y)
    remove_piece(*piece.position)
    remove_piece(to_x, to_y)  # Remove any piece at the destination (capture)
    piece.position = [to_x, to_y]
    place_piece(piece)
  end

  def opposite_color(color)
    color == :white ? :black : :white
  end
  
  def set_current_player(player)
    @current_player = player
  end

  def valid_move?(piece, from_x, from_y, to_x, to_y)
    case piece
    when Pawn
      valid_pawn_move?(piece, from_x, from_y, to_x, to_y)
    when Rook
      valid_rook_move?(from_x, from_y, to_x, to_y)
    when Knight
      valid_knight_move?(from_x, from_y, to_x, to_y)
    when Bishop
      valid_bishop_move?(from_x, from_y, to_x, to_y)
    when Queen
      valid_queen_move?(from_x, from_y, to_x, to_y)
    when King
      valid_king_move?(from_x, from_y, to_x, to_y)
    else
      false
    end
  end

  def valid_pawn_move?(pawn, from_x, from_y, to_x, to_y)
    direction = pawn.color == :white ? 1 : -1
    if from_y == to_y # Moving forward
      if from_x + direction == to_x
        return piece_at(to_x, to_y).nil?
      elsif from_x + 2 * direction == to_x && (pawn.color == :white ? from_x == 1 : from_x == 6)
        return piece_at(from_x + direction, from_y).nil? && piece_at(to_x, to_y).nil?
      end
    elsif (from_y - to_y).abs == 1 && from_x + direction == to_x # Capturing diagonally
      return piece_at(to_x, to_y) && piece_at(to_x, to_y).color != pawn.color
    end
    false
  end

  def valid_rook_move?(from_x, from_y, to_x, to_y)
    return false unless from_x == to_x || from_y == to_y
    path_clear?(from_x, from_y, to_x, to_y)
  end

  def valid_knight_move?(from_x, from_y, to_x, to_y)
    (from_x - to_x).abs * (from_y - to_y).abs == 2
  end

  def valid_bishop_move?(from_x, from_y, to_x, to_y)
    return false unless (from_x - to_x).abs == (from_y - to_y).abs
    path_clear?(from_x, from_y, to_x, to_y)
  end

  def valid_queen_move?(from_x, from_y, to_x, to_y)
    valid_rook_move?(from_x, from_y, to_x, to_y) || valid_bishop_move?(from_x, from_y, to_x, to_y)
  end

  def valid_king_move?(from_x, from_y, to_x, to_y)
    (from_x - to_x).abs <= 1 && (from_y - to_y).abs <= 1
  end

  def path_clear?(from_x, from_y, to_x, to_y)
    dx = to_x <=> from_x
    dy = to_y <=> from_y
    x, y = from_x + dx, from_y + dy

    while x != to_x || y != to_y
      return false if piece_at(x, y)
      x += dx
      y += dy
    end

    true
  end

  def capture_piece?(from_x, from_y, to_x, to_y)
    attacker = piece_at(from_x, from_y)
    defender = piece_at(to_x, to_y)
    
    return false unless defender

    if attacker.color == defender.color
      puts "Invalid move: cannot capture your own piece."
      return false
    end

    if defender.color == :white
      @captured_pieces_white << defender
    else
      @captured_pieces_black << defender
    end

    puts "#{attacker.color.capitalize} #{attacker.class} captures #{defender.color.capitalize} #{defender.class}!"
    true
  end

  def remove_piece(x, y)
    piece = piece_at(x, y)
    @pieces.delete(piece) if piece
    @grid[x][y] = (x + y).even? ? LIGHT_SQUARE : DARK_SQUARE
  end

  def captured_pieces
    puts "Captured White Pieces: #{@captured_pieces_white.map(&:symbol).join(' ')}"
    puts "Captured Black Pieces: #{@captured_pieces_black.map(&:symbol).join(' ')}"
  end

  def piece_at(x, y)
    @pieces.find { |piece| piece.position == [x, y] }
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
#board = Board.new
#board.display
#board.move_piece(1, 1, 7, 7)
#board.display
#board.captured_pieces