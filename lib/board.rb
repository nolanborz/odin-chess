require_relative 'pawn'
require_relative 'king'
require_relative 'queen'
require_relative 'rook'
require_relative 'knight'
require_relative 'bishop'
require_relative 'piece'

class Board
  LIGHT_SQUARE = "\e[47m   \e[0m" # White background
  DARK_SQUARE = "\e[100m   \e[0m" # Dark gray background

  attr_reader :current_player, :columns_arr, :grid, :captured_pieces_black, :captured_pieces_white, :pieces

  def initialize
    @current_player = :white
    @columns_arr = [' a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
    @grid = Array.new(8) { Array.new(8) }
    @pieces = []
    @captured_pieces_white = []
    @captured_pieces_black = []
    @white_castle_queenside = false
    @white_castle_kingside = false
    @black_castle_queenside = false
    @black_castle_kingside = false
    @last_move = nil
    @en_passant_target = nil
    setup_board
  end
  def to_yaml_properties
    ['@grid', '@pieces', '@current_player', '@captured_pieces_white', '@captured_pieces_black', '@en_passant_target']
  end
  def to_yaml
    YAML.dump(self)
  end

  def self.from_yaml(yaml)
    YAML.load(yaml)
  end

  def encode_with(coder)
    to_yaml_properties.each do |prop|
      coder[prop.to_s.sub('@', '')] = instance_variable_get(prop)
    end
  end

  def init_with(coder)
    @grid = coder['grid'].map do |row|
      row.map do |piece|
        if piece.is_a?(Hash) && piece['class']
          Object.const_get(piece['class']).new(piece['position'][0], piece['position'][1], piece['color'])
        else
          piece
        end
      end
    end
    @pieces = coder['pieces'].map do |piece|
      if piece.is_a?(Hash) && piece['class']
        Object.const_get(piece['class']).new(piece['position'][0], piece['position'][1], piece['color'])
      else
        piece
      end
    end
    @current_player = coder['current_player']
    @captured_pieces_white = coder['captured_pieces_white']
    @captured_pieces_black = coder['captured_pieces_black']
    @en_passant_target = coder['en_passant_target']
    @columns_arr = [' a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
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

  def set_current_player(player)
    @current_player = player
  end

  def move_piece(from_x, from_y, to_x, to_y)
    piece = @grid[from_x][from_y]
    puts "Attempting to move #{piece.class} from [#{from_x}, #{from_y}] to [#{to_x}, #{to_y}]"
  
    unless piece
      puts "No piece at [#{from_x}, #{from_y}]"
      return false
    end
  
    if piece.color != @current_player
      puts "It's not #{piece.color}'s turn."
      return false
    end

    if valid_move?(piece, from_x, from_y, to_x, to_y)
      perform_move(piece, from_x, from_y, to_x, to_y)
      update_last_move(piece, from_x, from_y, to_x, to_y)
      update_en_passant_target(piece, from_x, from_y, to_x, to_y)
      puts "Move performed successfully"
      true
    else
      puts "Invalid move for #{piece.color} #{piece.class}"
      false
    end
  end

  def update_last_move(piece, from_x, from_y, to_x, to_y)
    @last_move = {
      piece: piece,
      from: [from_x, from_y],
      to: [to_x, to_y]
    }
  end

  def update_en_passant_target(piece, from_x, from_y, to_x, to_y)
    if piece.is_a?(Pawn) && (to_x - from_x).abs == 2
      @en_passant_target = [to_x, to_y]
      puts "Updated en passant target: #{@en_passant_target.inspect}"
    else
      @en_passant_target = nil
      puts "Cleared en passant target"
    end
  end

  def move_resolves_check?(piece, from_x, from_y, to_x, to_y)
    target_piece = @grid[to_x][to_y]
    old_position = piece.position

    make_temp_move(piece, to_x, to_y)
    check_resolved = !king_in_check?(piece.color)
    undo_temp_move(piece, old_position, target_piece)

    check_resolved
  end

  def king_position(color)
    @pieces.find { |p| p.is_a?(King) && p.color == color }.position
  end

  def is_square_attacked?(x, y, attacker_color)
    @pieces.any? do |piece|
      piece.color == attacker_color && valid_move?(piece, *piece.position, x, y, check_only: true)
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

  def perform_move(piece, from_x, from_y, to_x, to_y)
    @grid[from_x][from_y] = nil
  
    # Handle en passant capture
    if piece.is_a?(Pawn) && en_passant_move?(piece, from_x, from_y, to_x, to_y)
      capture_x, capture_y = @en_passant_target
      captured_piece = @grid[capture_x][capture_y]
      if captured_piece
        capture_piece(captured_piece)
        @grid[capture_x][capture_y] = nil
        puts "En passant capture performed!"
      else
        puts "Warning: Expected to find a piece for en passant capture at [#{capture_x}, #{capture_y}], but found none."
      end
    else
      captured_piece = @grid[to_x][to_y]
      capture_piece(captured_piece) if captured_piece
    end
  
    @grid[to_x][to_y] = piece
    piece.position = [to_x, to_y]
    piece.mark_moved
    
    if piece.is_a?(Pawn) && (to_x == 7 || to_x == 0)
      promote_piece(piece, to_x)
    end
  end

  def find_king(color)
    @pieces.find { |piece| piece.is_a?(King) && piece.color == color }&.position
  end

  def king_in_check?(color, ignore_move: nil)
    king_pos = find_king(color)
    return false unless king_pos # If king is not found, assume it's not in check

    opposite_color_pieces(color).any? do |piece|
      next if piece.position == ignore_move
      valid_move?(piece, *piece.position, *king_pos, check_only: true, ignore_castling: true)
    end
  end

  def opposite_color(color)
    color == :white ? :black : :white
  end

  def opposite_color_pieces(color)
    @pieces.select { |p| p.color != color }
  end

  def valid_move?(piece, from_x, from_y, to_x, to_y, check_only: false, ignore_castling: false)
    return false if !check_only && @grid[to_x][to_y] && @grid[to_x][to_y].color == piece.color
    
    move_valid = case piece
    when Pawn
      valid_pawn_move?(piece, from_x, from_y, to_x, to_y, check_only: check_only)
    when Rook
      valid_rook_move?(from_x, from_y, to_x, to_y, check_only: check_only)
    when Knight
      valid_knight_move?(from_x, from_y, to_x, to_y, check_only: check_only)
    when Bishop
      valid_bishop_move?(from_x, from_y, to_x, to_y, check_only: check_only)
    when Queen
      valid_queen_move?(from_x, from_y, to_x, to_y, check_only: check_only)
    when King
      valid_king_move?(from_x, from_y, to_x, to_y, check_only: check_only, ignore_castling: ignore_castling)
    else
      false
    end
  
    #puts "Move for #{piece.class} from [#{from_x}, #{from_y}] to [#{to_x}, #{to_y}] is #{move_valid ? 'valid' : 'invalid'}"
    if move_valid && !check_only
      !move_results_in_check?(from_x, from_y, to_x, to_y)
    else
      move_valid
    end
  end

  def valid_pawn_move?(pawn, from_x, from_y, to_x, to_y, check_only: false)
    #puts "Checking pawn move validity:"
    #puts "  From: [#{from_x}, #{from_y}]"
    #puts "  To: [#{to_x}, #{to_y}]"

    direction = pawn.color == :white ? 1 : -1
    
    # Normal pawn moves
    if from_y == to_y # Moving forward
      if from_x + direction == to_x
        return piece_at(to_x, to_y).nil?
      elsif from_x + 2 * direction == to_x && !pawn.has_moved?
        return piece_at(from_x + direction, from_y).nil? && piece_at(to_x, to_y).nil?
      end
    elsif (from_y - to_y).abs == 1 && from_x + direction == to_x # Capturing diagonally
      return true if en_passant_move?(pawn, from_x, from_y, to_x, to_y)
      return check_only || (piece_at(to_x, to_y) && piece_at(to_x, to_y).color != pawn.color)
    end

    #puts "  Invalid pawn move"
    false
  end

  def en_passant_move?(pawn, from_x, from_y, to_x, to_y)
    return false unless @en_passant_target
  
    target_x, target_y = @en_passant_target
    direction = pawn.color == :white ? 1 : -1
  
    #puts "Checking en passant move:"
    #puts "  Pawn color: #{pawn.color}"
    #puts "  From: [#{from_x}, #{from_y}]"
    #puts "  To: [#{to_x}, #{to_y}]"
    #puts "  En passant target: #{@en_passant_target.inspect}"
    #puts "  Pawn on en passant rank? #{pawn.en_passant_rank?}"
    #puts "  Is pawn moving one square forward? #{from_x + direction == to_x}"
    #puts "  Is pawn moving diagonally? #{(from_y - to_y).abs == 1}"
    #puts "  Is pawn moving to the correct file? #{to_y == target_y}"
    #puts "  Is pawn capturing the correct rank? #{to_x == target_x + direction}"
  
    valid = pawn.en_passant_rank? &&
            from_x + direction == to_x &&
            (from_y - to_y).abs == 1 &&
            to_y == target_y &&
            to_x == target_x + direction
  
    puts "  En passant move valid? #{valid}"
    valid
  end

  def valid_rook_move?(from_x, from_y, to_x, to_y, check_only: false)
    return false unless from_x == to_x || from_y == to_y
    path_clear?(from_x, from_y, to_x, to_y)
  end

  def valid_knight_move?(from_x, from_y, to_x, to_y, check_only: false)
    (from_x - to_x).abs * (from_y - to_y).abs == 2
  end

  def valid_bishop_move?(from_x, from_y, to_x, to_y, check_only: false)
    return false unless (from_x - to_x).abs == (from_y - to_y).abs
    path_clear?(from_x, from_y, to_x, to_y)
  end

  def valid_queen_move?(from_x, from_y, to_x, to_y, check_only: false)
    dx = (to_x - from_x).abs
    dy = (to_y - from_y).abs
    is_valid = (from_x == to_x || from_y == to_y || dx == dy) && path_clear?(from_x, from_y, to_x, to_y)
    #puts "Queen move from [#{from_x}, #{from_y}] to [#{to_x}, #{to_y}] is #{is_valid ? 'valid' : 'invalid'}. dx: #{dx}, dy: #{dy}"
    is_valid
  end

  def valid_king_move?(from_x, from_y, to_x, to_y, check_only: false, ignore_castling: false)
    dx = (to_x - from_x).abs
    dy = (to_y - from_y).abs

    return true if dx <= 1 && dy <= 1 # Normal king move

    if !ignore_castling && dx == 0 && dy == 2 # Potential castling move
      color = piece_at(from_x, from_y).color
      side = to_y > from_y ? :kingside : :queenside
      return can_castle?(color, side, check_only: check_only)
    end

    false
  end

  def path_clear?(from_x, from_y, to_x, to_y)
    dx = to_x <=> from_x
    dy = to_y <=> from_y
    x, y = from_x + dx, from_y + dy

    while x != to_x || y != to_y
      if piece_at(x, y)
        #puts "Path blocked at [#{x}, #{y}]"
        return false
      end
      x += dx
      y += dy
    end

    #puts "Path is clear from [#{from_x}, #{from_y}] to [#{to_x}, #{to_y}]"
    true
  end

  def capture_piece(piece)
    return unless piece # Add this guard clause
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
    return nil if x < 0 || x >= 8 || y < 0 || y >= 8
    @grid[x][y]
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

  def is_checkmate?(color)
    puts "Checking checkmate for #{color}"
    unless king_in_check?(color)
      puts "#{color} king is not in check, so it's not checkmate"
      return false
    end
    
    king = @pieces.find { |p| p.is_a?(King) && p.color == color }
    king_x, king_y = king.position
    puts "King position: [#{king_x}, #{king_y}]"
  
    # Check if the king can move to any adjacent square
    [-1, 0, 1].each do |dx|
      [-1, 0, 1].each do |dy|
        next if dx == 0 && dy == 0
        new_x, new_y = king_x + dx, king_y + dy
        if valid_position?(new_x, new_y) && 
           valid_move?(king, king_x, king_y, new_x, new_y) &&
           !move_results_in_check?(king_x, king_y, new_x, new_y)
          puts "King can move to [#{new_x}, #{new_y}], so it's not checkmate"
          return false
        end
      end
    end

  
    # Check if any piece can block the check or capture the attacking piece
    attacking_pieces = find_attacking_pieces(color)
    puts "Attacking pieces: #{attacking_pieces.map { |p| "#{p.class} at #{p.position}" }.join(', ')}"
    if can_block_or_capture?(color, attacking_pieces)
      puts "A piece can block or capture, so it's not checkmate"
      return false
    end
  
    puts "It's checkmate for #{color}"
    true
  end

  def valid_position?(x, y)
    x.between?(0, 7) && y.between?(0, 7)
  end

  def can_block_or_capture?(color, attacking_pieces)
    @pieces.select { |p| p.color == color }.each do |piece|
      piece_x, piece_y = piece.position
      (0..7).each do |to_x|
        (0..7).each do |to_y|
          next if [piece_x, piece_y] == [to_x, to_y]
          if valid_move?(piece, piece_x, piece_y, to_x, to_y) &&
             !move_results_in_check?(piece_x, piece_y, to_x, to_y) &&
             (attacking_pieces.any? { |ap| ap.position == [to_x, to_y] } ||
              is_blocking_move?(piece, to_x, to_y, attacking_pieces))
            puts "#{piece.class} at [#{piece_x}, #{piece_y}] can move to [#{to_x}, #{to_y}] to block or capture"
            return true
          end
        end
      end
    end
    false
  end

  def is_blocking_move?(piece, to_x, to_y, attacking_pieces)
    king = @pieces.find { |p| p.is_a?(King) && p.color == piece.color }
    attacking_pieces.any? do |ap|
      between_positions(ap.position, king.position).include?([to_x, to_y])
    end
  end

  def between_positions(pos1, pos2)
    x1, y1 = pos1
    x2, y2 = pos2
    dx = (x2 - x1).nonzero? ? (x2 - x1) / (x2 - x1).abs : 0
    dy = (y2 - y1).nonzero? ? (y2 - y1) / (y2 - y1).abs : 0
    positions = []
    x, y = x1 + dx, y1 + dy
    while [x, y] != [x2, y2]
      positions << [x, y]
      x, y = x + dx, y + dy
    end
    positions
  end

  def find_attacking_pieces(color)
    king = @pieces.find { |p| p.is_a?(King) && p.color == color }
    king_x, king_y = king.position
    
    @pieces.select do |piece|
      piece.color != color &&
      valid_move?(piece, *piece.position, king_x, king_y)
    end
  end

  def move_results_in_check?(from_x, from_y, to_x, to_y)
    piece = @grid[from_x][from_y]
    return false unless piece
  
    # Store the current state
    old_to_piece = @grid[to_x][to_y]
    
    # Simulate the move
    @grid[to_x][to_y] = piece
    @grid[from_x][from_y] = nil
    old_position = piece.position
    piece.position = [to_x, to_y]
  
    # Check if the move results in check
    result = king_in_check?(piece.color, ignore_move: [to_x, to_y])
  
    # Restore the original state
    @grid[from_x][from_y] = piece
    @grid[to_x][to_y] = old_to_piece
    piece.position = old_position
  
    result
  end

  def spaces_empty?(start_pos, end_pos)
    x = start_pos[0]
    ((start_pos[1] + 1)...end_pos[1]).all? { |y| piece_at(x, y).nil? }
  end


  def can_castle?(color, side, check_only: false)
    king = @pieces.find { |piece| piece.is_a?(King) && piece.color == color }
    rook = find_castling_rook(color, side)
  
    return false if king.nil? || rook.nil? || king.has_moved? || rook.has_moved?
  
    rank = color == :white ? 0 : 7
    king_file = 4
    rook_file = side == :kingside ? 7 : 0
  
    # Check if spaces between king and rook are empty
    return false unless spaces_empty?([rank, king_file], [rank, rook_file])
  
    # Check if king is in check
    return false if king_in_check?(color, ignore_move: [rank, king_file])
  
    # Check if king passes through attacked square
    intermediate_file = side == :kingside ? 5 : 3
    !is_square_attacked?(rank, intermediate_file, opposite_color(color))
  end

  def find_castling_rook(color, side)
    rank = color == :white ? 0 : 7
    file = side == :kingside ? 7 : 0
    piece = piece_at(rank, file)
    piece.is_a?(Rook) && piece.color == color ? piece : nil
  end

  def perform_castling(color, side)
    rank = color == :white ? 0 : 7
    king = piece_at(rank, 4)
    
    if side == :kingside
      rook = piece_at(rank, 7)
      king_to_file = 6
      rook_to_file = 5
    else # queenside
      rook = piece_at(rank, 0)
      king_to_file = 2
      rook_to_file = 3
    end
  
    # Move king
    @grid[rank][4] = nil
    @grid[rank][king_to_file] = king
    king.position = [rank, king_to_file]
    king.mark_moved
  
    # Move rook
    @grid[rank][rook.position[1]] = nil
    @grid[rank][rook_to_file] = rook
    rook.position = [rank, rook_to_file]
    rook.mark_moved
  
    puts "Castling performed for #{color} on #{side} side"
  end

  def get_promotion_class(piece_name)
    case piece_name.downcase
    when 'queen' then Queen
    when 'rook' then Rook
    when 'bishop' then Bishop
    when 'knight' then Knight
    else
      raise ArgumentError, "Invalid promotion piece: #{piece_name}"
    end
  end

  def promotion_input
    puts "Which piece would you like to promote to?"
    piece_arr = ['Queen', 'Rook', 'Bishop', 'Knight']
    loop do
      promotion = gets.chomp.capitalize
      return promotion if piece_arr.include?(promotion)
      puts "Please enter one of the following: #{piece_arr.join(', ')}"
    end
  end

  def promote_piece(piece, to_x)
    promotion_class = get_promotion_class(promotion_input)
    promoted_piece = promotion_class.new(piece.position[0], piece.position[1], piece.color)
    remove_piece(piece.position[0], piece.position[1])
    place_piece(promoted_piece)
    puts "Pawn promoted to #{promoted_piece.class} at position #{promoted_piece.position}"
    check_game_state_after_promotion(promoted_piece)
  end

  def check_game_state_after_promotion(promoted_piece)
    if king_in_check?(opposite_color(promoted_piece.color))
      puts "Check!"
      if is_checkmate?(opposite_color(promoted_piece.color))
        puts "Checkmate!"
      end
    end
  end

  def is_stalemate?(color)
    return false if king_in_check?(color)
    
    @pieces.select { |p| p.color == color }.each do |piece|
      piece_x, piece_y = piece.position
      (0..7).each do |to_x|
        (0..7).each do |to_y|
          next if [piece_x, piece_y] == [to_x, to_y]
          if valid_move?(piece, piece_x, piece_y, to_x, to_y) &&
             !move_results_in_check?(piece_x, piece_y, to_x, to_y)
            return false
          end
        end
      end
    end
    
    true
  end

end
