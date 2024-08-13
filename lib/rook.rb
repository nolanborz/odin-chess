class Rook
  attr_reader :color, :symbol
  attr_accessor :position
  SYMBOLS = { white: "♖", black: "♜"}
  attr_reader :position, :color
  def initialize(x, y, color)
    @position = [x, y]
    @color = color
    @symbol = SYMBOLS[color]
  end

  def inspect
    "#<#{self.class} #{@symbol} position=#{@position}, color=#{@color}>"
  end
end