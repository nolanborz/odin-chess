WHITE_PIECES = {
  king: "♔", queen: "♕", rook: "♖",
  bishop: "♗", knight: "♘", pawn: "♙"
}

BLACK_PIECES = {
  king: "♚", queen: "♛", rook: "♜",
  bishop: "♝", knight: "♞", pawn: "♟"
}

class Pawn
  SYMBOLS = { white: "♙", black: "♟"}
  attr_reader :position, :color
  def initialize(x, y, color)
    @position = [x, y]
    @color = color
    @symbol = SYMBOLS[color]
  end

  def inspect
    "#<#{self.class} #{@symbol} position=#{@position}, color=#{@color}>"
  end

  def forward_one
    new_y = @color == :white ? @position[1] + 1 : @position[1] - 1
    @position = [@position[0], new_y] if valid_move?(@position[0], new_y)
  end
  
  def forward_two
    return unless (@color == :white && @position[1] == 1) || (@color == :black && @position[1] == 6)
    new_y = @color == :white ? @position[1] + 2 : @position[1] - 2
    @position = [@position[0], new_y] if valid_move?(@position[0], new_y)
  end

  def take_piece(direction)
    new_x = direction == :left ? @position[0] - 1 : @position[0] + 1
    new_y = @color == :white ? @position[1] + 1 : @position[1] - 1
    @position = [new_x, new_y] if valid_move?(new_x, new_y)
  end

  private
  
  def valid_move?(x, y)
    x.between?(0, 7) && y.between?(0, 7)
  end
end

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

class Knight
  SYMBOLS = { white: "♘", black: "♞" }
  def initialize(x, y, color)
    @position = [x, y]
    @color = color
    @symbol = SYMBOLS[@color]
  end
end

class Bishop
  SYMBOLS = { white: "♗", black: "♝" }
  def initialize(x, y, color)
    @position = [x, y]
    @color = color
    @symbol = SYMBOLS[@color]
  end
end

class Queen 
  SYMBOLS = { white: "♕" , black: "♛" }
  def initialize(x, y, color)
    @position = [x, y]
    @color = color
    @symbol = SYMBOLS[@color]
  end
end

class King
  SYMBOLS = { white: "♔", black: "♚" }
  def initialize(x, y, color)
    @position = [x, y]
    @color = color
    @symbol = SYMBOLS[@color]
  end
end

pwn = Pawn.new(4, 6, :black)
pwn.forward_two
puts pwn.inspect

rk = Rook.new(0, 0, :white)
rk.move_horizontal(4)
puts rk.inspect





