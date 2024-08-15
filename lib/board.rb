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
    @columns_arr = [' a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
    @grid = Array.new(8) { Array.new(8) }
    @pieces = []
    @captured_pieces_white = []
    @captured_pieces_black = []
    setup_board
  end

  def setup_board
    setup_pawns
    setup_back_rank(:white)
    setup_back_rank(:black)
  end

  def setup_pawns
    8.times do |col|
      place_piece(Pawn.new(1, col, :white))
      place_piece(Pawn.new(6, col, :black))
    end
  end

  def setup_back_rank(color)
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

  def place_piece(piece)
    x, y = piece.position
    @grid[x][y] = piece
    @pieces << piece
  end

  def move_piece(from_x, from_y, to_x, to_y)
    piece = @grid[from_x][from_y]
    return false unless piece

    if piece.color != @current_player
      puts "It's not #{piece.color}'s turn."
      return false
    end

    unless valid_move?(piece, from_x, from_y, to_x, to_y)
      puts "Invalid move for #{piece.color} #{piece.class}"
      return false
    end

    captured_piece = @grid[to_x][to_y]
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
    king_pos = find_king(color)
    opposite_color_pieces.any? do |piece|
      valid_move?(piece, *piece.position, *king_pos, check_only: true)
    end
  end

  def make_temp_move(piece, to_x, to_y)
    @grid[piece.position[0]][piece.position[1]] = nil
    @grid[to_x][to_y] = piece
    piece.position = [to_x, to_y]
  end

  def undo_temp_move(piece, old_position, captured_piece)
    current_x, current_y = piece.position
    @grid[current_x][current_y] = captured_piece
    @grid[old_position[0]][old_position[1]] = piece
    piece.position = old_position
  end

  def perform_move(piece, to_x, to_y)
    from_x, from_y = piece.position
    @grid[from_x][from_y] = nil
    captured_piece = @grid[to_x][to_y]
    capture_piece(captured_piece) if captured_piece
    @grid[to_x][to_y] = piece
    piece.position = [to_x, to_y]
  end

  def find_king(color)
    @grid.each_with_index do |row, x|
      row.each_with_index do |piece, y|
        return [x, y] if piece.is_a?(King) && piece.color == color
      end
    end
  end

  def opposite_color(color)
    color == :white ? :black : :white
  end
  
  def set_current_player(player)
    @current_player = player
  end

  def opposite_color_pieces
    @pieces.select { |p| p.color != @current_player }
  end

  def valid_move?(piece, from_x, from_y, to_x, to_y, check_only: false)
    return false if !check_only && @grid[to_x][to_y] && @grid[to_x][to_y].color == piece.color
    
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

  def capture_piece(piece)
    @pieces.delete(piece)
    if piece.color == :white
      @captured_pieces_white << piece
    else
      @captured_pieces_black << piece
    end
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
    puts "  #{@columns_arr.join('  ')}"
    8.downto(1) do |row|
      print "#{row} "
      8.times do |col|
        piece = @grid[row - 1][col]
        background_color = (row + col).even? ? 47 : 100
        if piece
          print "\e[#{background_color}m #{piece.symbol} \e[0m"
        else
          print (row + col).even? ? LIGHT_SQUARE : DARK_SQUARE
        end
      end
      puts " #{row}"
    end
    puts "  #{@columns_arr.join('  ')}"
  end
end

# Example usage:
#board = Board.new
#board.display
#board.move_piece(1, 1, 7, 7)
#board.display
#board.captured_pieces