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
			y, z = y*cos - z*sin, y*sin + z*cos
		end
		if vec[1].to_f != 0.0
			cos = Math.cos(vec[1])
			sin = Math.sin(vec[1])
			z, x = z*cos - x*sin, z*sin + x*cos
		end
		if vec[2].to_f != 0.0
			cos = Math.cos(vec[2])
			sin = Math.sin(vec[2])
			x, y = x*cos - y*sin, x*sin + y*cos
		end
		Point3D.new(x, y, z)
	end

	def rotate_deg(vec)
		rotate(vec.to_a.map { |deg| self.class.from_degree(deg) })
	end

	def clip_z(max_z)
		self if @z <= max_z
	end

	# project to a plane sitting at screen_z, aiming for a camera at [0, 0, 0] looking at [0, 0, -1] (up [0, 1, 0])
	# should clip_z beforehand
	# may return nil (if z == camera_z)
	def project_z(screen_z)
		return if @z == 0.0
		r = screen_z/@z
		Point3D.new(r*@x, r*@y, screen_z)
	end

	# convert dot coordinates to screen coords (revert y axis, scale coords from 0 to size) after projection
	def to_screen(size)
		scale([size[1]/2.0]*3).mirror([false, true, false]).translate([size[0]/2.0, size[1]/2.0, 0.0])
	end

	def self.from_degree(angle_deg)
		angle_deg * Math::PI / 180.0
	end

	def self.to_degree(angle_rad)
		angle_rad * 180 / Math::PI
	end

	def -@
		Point3D.new(-@x, -@y, -@z)
	end

	def +(other)
		other = other.to_a
		Point3D.new(@x+other[0].to_f, @y+other[1].to_f, @z+other[2].to_f)
	end

	def -(other)
		other = other.to_a
		Point3D.new(@x-other[0].to_f, @y-other[1].to_f, @z-other[2].to_f)
	end

	def *(fact)
		scale([fact]*3)
	end

	def /(fact)
		scale([1.0/fact]*3)
	end

	def dot(other)
		other = other.to_a
		@x*other[0].to_f + @y*other[1].to_f + @z*other[2].to_f
	end

	def cross(other)
		other = other.to_a
		ox, oy, oz = other[0].to_f, other[1].to_f, other[2].to_f
		Point3D.new(@y*oz-@z*oy, @z*ox-@x*oz, @x*oy-@y*ox)
	end

	def dist(other=[0.0, 0.0, 0.0])
		delta = self - other
		Math.sqrt(delta.dot(delta))
	end

	def to_s
		"<Pt3D #{'%.03f' % @x} #{'%.03f' % @y} #{'%.03f' % @z}>"
	end
end
