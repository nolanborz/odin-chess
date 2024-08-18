class Pawn
  attr_reader :color, :symbol
  attr_accessor :position, :has_moved
  SYMBOLS = { white: "♙", black: "♟"}
  def initialize(x, y, color)
    @position = [x, y]
    @color = color
    @symbol = SYMBOLS[@color]
    @has_moved = false
  end

  def has_moved?
    @has_moved
  end
  
  def mark_moved
    @has_moved = true
  end

  def en_passant_rank?
    (color == :white && position[0] == 4) || (color == :black && position[0] == 3)
  end
end