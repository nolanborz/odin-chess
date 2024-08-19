class Piece
  attr_reader :color, :symbol
  attr_accessor :position, :has_moved

  def initialize(x, y, color)
    @position = [x, y]
    @color = color
    @symbol = self.class::SYMBOLS[@color]
    @has_moved = false
  end

  def has_moved?
    @has_moved
  end
  
  def mark_moved
    @has_moved = true
  end

  def encode_with(coder)
    coder.represent_map(nil, {
      'class' => self.class.name,
      'position' => @position,
      'color' => @color,
      'has_moved' => @has_moved
    })
  end

  def init_with(coder)
    @position = coder['position']
    @color = coder['color']
    @has_moved = coder['has_moved']
    @symbol = self.class::SYMBOLS[@color]
  end

  def self.yaml_tag_read_class(name)
    name
  end
end