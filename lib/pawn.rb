require_relative 'piece'

class Pawn < Piece
  SYMBOLS = { white: "♙", black: "♟"}
  def en_passant_rank?
    (color == :white && position[0] == 4) || (color == :black && position[0] == 3)
  end
end