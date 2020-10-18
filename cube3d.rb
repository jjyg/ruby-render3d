require 'gosu'
require './mesh3d'

class Cube3DWindow < Gosu::Window
	def initialize
		@win_size = [640, 480]
		super(*@win_size)
		@rot_x = Math::PI/8
		@rot_y = 0.0
		@rot_z = 0.0
		@start_time = Gosu.milliseconds
		self.caption = "Cube 3D"
		@cube = Mesh3D.cube(:color => Gosu::Color::WHITE)
	end

	def update
		@rot_y = (Gosu.milliseconds - @start_time) / 1000.0
	end

	def draw
		@cube.rotate([@rot_x, @rot_y, @rot_z]).scale(0.5).to_screen(@win_size).lines.each { |src, dst|
			Gosu.draw_line(src.x, src.y, @cube.attr[:color], dst.x, dst.y, @cube.attr[:color], 0)
		}
	end
end

Cube3DWindow.new.show
