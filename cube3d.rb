require 'gosu'
require './mesh3d'

class Cube3DWindow < Gosu::Window
	def initialize
		@win_size = [640, 480]
		super(*@win_size)
		@cube_rot_x = Math::PI/8
		@cube_rot_y = 0.0
		@cube_rot_z = 0.0
		@cam = Camera3D.new
		@start_time = Gosu.milliseconds
		self.caption = "Cube 3D"
		@cube = Mesh3D.cube(:color => Gosu::Color::WHITE).scale(0.5)
		@keys = {}
	end

	def update
		handle_keys
		@cube_rot_y = (Gosu.milliseconds - @start_time) / 1000.0
	end

	def draw
		cube = @cube.rotate([@cube_rot_x, @cube_rot_y, @cube_rot_z])
		draw_mesh(cube)
		#draw_mesh(Camera3D.new.project(cube).translate([0, 0, 3]))
	end

	def draw_mesh(mesh)
		col = mesh.attr[:color]
		@cam.project(mesh).to_screen(@win_size).lines.each { |src, dst|
			next if not src or not dst
			Gosu.draw_line(src.x, src.y, col, dst.x, dst.y, col, 0)
		}
	end

	def button_down(id)
		@keys[id] = [Gosu.milliseconds, mouse_x, mouse_y]
	end

	def button_up(id)
		handle_keys
		@keys.delete(id)
	end

	def handle_keys
		cur_ts = cur_mx = cur_my = nil
		@keys.dup.each { |k, (ts, mx, my)|
			cur_ts ||= Gosu.milliseconds
			cur_mx ||= mouse_x
			cur_my ||= mouse_y
			d_ts = (cur_ts - ts)/1000.0

			case k
			# cam translate
			when Gosu::KB_A
				@cam.translate!(-@cam.rightv * d_ts)
			when Gosu::KB_D
				@cam.translate!(@cam.rightv * d_ts)
			when Gosu::KB_S
				@cam.translate!(-@cam.lookv * d_ts)
			when Gosu::KB_W
				@cam.translate!(@cam.lookv * d_ts)
			when Gosu::KB_C
				@cam.translate!(-@cam.upv * d_ts)
			when Gosu::KB_SPACE
				@cam.translate!(@cam.upv * d_ts)

			# cam rotate
			when Gosu::KB_UP
				@cam.rotate!(@cam.rightv * d_ts)
			when Gosu::KB_DOWN
				@cam.rotate!(-@cam.rightv * d_ts)
			when Gosu::KB_LEFT
				@cam.rotate!(@cam.upv * d_ts)
			when Gosu::KB_RIGHT
				@cam.rotate!(-@cam.upv * d_ts)
			when Gosu::KB_PAGE_UP
				@cam.rotate!(-@cam.lookv * d_ts)
			when Gosu::KB_PAGE_DOWN
				@cam.rotate!(@cam.lookv * d_ts)

			# reset camera
			when Gosu::KB_R
				@cam = Camera3D.new

			else
				id_to_name = Gosu.constants.find { |k| Gosu.const_get(k) == id }
				puts "unk key #{id_to_name || k}"

				@keys.delete(k)
				next
			end
			@keys[k] = [cur_ts, cur_mx, cur_my]
		}
	end
end

Cube3DWindow.new.show
