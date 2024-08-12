class Bishop
  SYMBOLS = { white: "♗", black: "♝" }
  def initialize(x, y, color)
    @position = [x, y]
    @color = color
    @symbol = SYMBOLS[@color]
  end
end