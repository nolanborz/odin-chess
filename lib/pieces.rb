WHITE_PIECES = {
  king: "♔", queen: "♕", rook: "♖",
  bishop: "♗", knight: "♘", pawn: "♙"
}

BLACK_PIECES = {
  king: "♚", queen: "♛", rook: "♜",
  bishop: "♝", knight: "♞", pawn: "♟"
}



class Rook
  SYMBOLS = { white: "♖", black: "♜" }
  attr_reader :position, :color
  def initialize(x, y, color)
    @position = [x, y]
    @color = color
    @symbol = SYMBOLS[@color]
  end

  def inspect
    "#<#{self.class} position=#{@position}, color=#{@color}>"
  end

  def move_vertical(new_pos)
    @position = [@position[0], new_pos]
  end

  def move_horizontal(new_pos)
    @position = [new_pos, @position[1]]
  end

  def valid_move?
    x.between?(0, 7) && y.between?(0, 7)
  end
end

pwn = Pawn.new(4, 6, :black)
pwn.forward_two
puts pwn.inspect

rk = Rook.new(0, 0, :white)
rk.move_horizontal(4)
puts rk.inspect





