class Knight
  attr_reader :color, :symbol
  attr_accessor :position
  SYMBOLS = { white: "♘", black: "♞" }
  def initialize(x, y, color)
    @position = [x, y]
    @color = color
    @symbol = SYMBOLS[@color]
  end
end