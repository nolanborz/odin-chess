class Pawn
  attr_reader :position, :color
  def initialize(x, y, color)
    @position = [x, y]
    @color = color
  end

  def inspect
    "#<#{self.class} position=#{@position}, color=#{@color}>"
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

pwn = Pawn.new(4, 6, :black)
pwn.forward_two
pwn.forward_one
puts pwn.inspect

