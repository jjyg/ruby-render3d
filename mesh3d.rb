# single point in 3D space, can be transformed into a new point
class Point3D
	attr_accessor :x, :y, :z
	def initialize(x=0.0, y=0.0, z=0.0)
		@x = x.to_f
		@y = y.to_f
		@z = z.to_f
	end

	def to_a
		[@x, @y, @z]
	end

	def translate(vec)
		vec = vec.to_a
		Point3D.new(@x+vec[0].to_f, @y+vec[1].to_f, @z+vec[2].to_f)
	end

	def scale(vec)
		vec = vec.to_a
		Point3D.new(@x*vec[0].to_f, @y*vec[1].to_f, @z*vec[2].to_f)
	end

	# vec is an array of bool true/false
	def mirror(vec)
		vec = vec.to_a
		Point3D.new((vec[0] ? -@x : @x), (vec[1] ? -@y : @y), (vec[2] ? -@z : @z))
	end

	# rotate around the axes in order
	# angles in radians
	# +x right, +y up, +z back
	def rotate(vec)
		vec = vec.to_a
		x, y, z = @x, @y, @z
		if vec[0].to_f != 0.0
			cos = Math.cos(vec[0])
			sin = Math.sin(vec[0])
			y, z = y*cos + z*sin, z*cos - y*sin
		end
		if vec[1].to_f != 0.0
			cos = Math.cos(vec[1])
			sin = Math.sin(vec[1])
			z, x = z*cos + x*sin, x*cos - z*sin
		end
		if vec[2].to_f != 0.0
			cos = Math.cos(vec[2])
			sin = Math.sin(vec[2])
			x, y = x*cos + y*sin, y*cos - x*sin
		end
		Point3D.new(x, y, z)
	end

	def rotate_deg(vec)
		rotate(vec.to_a.map { |deg| self.class.from_degree(deg) })
	end

	def self.from_degree(angle_deg)
		angle_deg * Math::PI / 180.0
	end

	def self.to_degree(angle_rad)
		angle_rad * 180 / Math::PI
	end
end

# collection of connected Point3D
class Mesh3D
	attr_accessor :attr, :dots, :lines_idx
	def initialize(attr={}, dots=[], lines_idx=[])
		# arbitrary attributes
		@attr = attr
		# array of Point3D
		@dots = dots
		# array of couple of dots indexes to join with a line
		@lines_idx = lines_idx
	end

	# copy the mesh with updated dots, same attr/lines
	def dup(dots=@dots)
		Mesh3D.new(@attr, dots, @lines_idx)
	end

	# return an array of couples of Point3D
	def lines
		@lines_idx.map { |i1, i2| [@dots[i1], @dots[i2]] }
	end

	def translate(vec)
		dup(@dots.map { |d| d.translate(vec) })
	end

	def scale_xyz(vec)
		dup(@dots.map { |d| d.scale(vec) })
	end

	def scale(fact)
		scale_xyz([fact, fact, fact])
	end

	def rotate(vec)
		dup(@dots.map { |d| d.rotate(vec) })
	end

	def mirror_x
		dup(@dots.map { |d| d.mirror([true, false, false]) })
	end

	def mirror_y
		dup(@dots.map { |d| d.mirror([false, true, false]) })
	end

	def mirror_z
		dup(@dots.map { |d| d.mirror([false, false, true]) })
	end

	# project the dots coordinates to a 2d plane at z=1, camera points to [0, 0, 0]
	# projected image covers height from y=-1 to y=+1
	# returns a new Mesh3D with all points having z=screen_z
	def project(camera_z=3.0, screen_z=1.0)
		dup(@dots.map { |d|
			if d.z >= camera_z
				# TODO clipping ? need to work on lines
				Point3D.new(0, 0, camera_z)
			else
				r = (camera_z-screen_z)/(camera_z-d.z)
				Point3D.new(r*d.x, r*d.y, camera_z)
			end
		})
	end

	# project and convert dot coordinates to screen coords (revert y axis, scale coords from 0 to size)
	def to_screen(size, *project_args)
		project(*project_args).scale(size[1]/2.0).mirror_y.translate([size[0]/2.0, size[1]/2.0, 0.0])
	end

	def self.cube(attr={})
		dots = [[-1, -1, -1], [-1,  1, -1], [ 1,  1, -1], [ 1, -1, -1], # front face
			[-1, -1,  1], [-1,  1,  1], [ 1,  1,  1], [ 1, -1,  1]] # back face

		lines = [[0, 1], [1, 2], [2, 3], [3, 0], # front face
			 [4, 5], [5, 6], [6, 7], [7, 4], # back face
			 [0, 4], [1, 5], [2, 6], [3, 7]] # front to back

		new(attr, dots.map { |d| Point3D.new(*d) }, lines)
	end
end
