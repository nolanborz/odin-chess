class King
  attr_reader :color, :symbol
  attr_accessor :position, :has_moved
  SYMBOLS = { white: "♔", black: "♚" }
  def initialize(x, y, color)
    @position = [x, y]
    @color = color
    @symbol = SYMBOLS[@color]
    @has_moved = false
  end

  def has_moved?
    @has_moved ||= false
  end
  
  def mark_moved
    @has_moved = true
  end
end