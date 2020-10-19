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

	# copy the mesh with updated dots/lines, same attr
	def dup(dots=@dots, lines_idx=@lines_idx)
		Mesh3D.new(@attr, dots, lines_idx)
	end

	# return an array of couples of Point3D
	def lines
		@lines_idx.map { |i1, i2| [@dots[i1], @dots[i2]] }
	end

	def translate(vec)
		dup(@dots.map { |d| d.translate(vec) if d })
	end

	def scale_xyz(vec)
		dup(@dots.map { |d| d.scale(vec) if d })
	end

	def scale(fact)
		scale_xyz([fact, fact, fact])
	end

	def rotate(vec)
		dup(@dots.map { |d| d.rotate(vec) if d })
	end

	def mirror(vec)
		dup(@dots.map { |d| d.mirror(vec) if d })
	end

	def mirror_x
		mirror([true, false, false])
	end

	def mirror_y
		mirror([false, true, false])
	end

	def mirror_z
		mirror([false, false, true])
	end

	# clip dots with z > max_z
	# split lines crossing max_z
	def clip_z(max_z=-0.1)
		# filter dots
		dots = @dots.map { |d| d.clip_z(max_z) if d }

		# find the intersection of the line with the clip plane
		# append it to dots
		# return the new dot idx
		new_dot = lambda { |d1, d2|
			r = (max_z - d2.z) / (d1.z - d2.z)
			x = d2.x + (d1.x - d2.x) * r
			y = d2.y + (d1.y - d2.y) * r
			dots << Point3D.new(x, y, max_z)
			dots.length-1
		}

		# split lines
		lines_idx = @lines_idx.map { |i1, i2|
			next if not dots[i1] and not dots[i2]
			if not dots[i1]
				next if not @dots[i1]
				i1 = new_dot[@dots[i1], dots[i2]]
			elsif not dots[i2]
				next if not @dots[i2]
				i2 = new_dot[dots[i1], @dots[i2]]
			end
			[i1, i2]
		}.compact

		dup(dots, lines_idx)
	end

	# project the dots coordinates to a 2d plane at z=screen_z, camera sitting at [0, 0, 0] pointing to [0, 0, -1]
	# returns a new Mesh with all points having z=screen_z
	# should have called clip_z beforehand
	def project_z(screen_z=-2.0)
		dup(@dots.map { |d| d.project_z(screen_z) if d })
	end

	# convert dot coordinates to screen coords (revert y axis, scale coords from 0 to size) after projection
	def to_screen(size)
		scale(size[1]/2.0).mirror_y.translate([size[0]/2.0, size[1]/2.0, 0.0])
	end

	def self.cube(attr={})
		dots = [[-1, -1, -1], [-1,  1, -1], [ 1,  1, -1], [ 1, -1, -1], # front face
			[-1, -1,  1], [-1,  1,  1], [ 1,  1,  1], [ 1, -1,  1]] # back face

		lines = [[0, 1], [1, 2], [2, 3], [3, 0], # front face
			 [4, 5], [5, 6], [6, 7], [7, 4], # back face
			 [0, 4], [1, 5], [2, 6], [3, 7]] # front to back

		new(attr, dots.map { |d| Point3D.new(*d) }, lines)
	end

	def self.line(p_end, attr={})
		new(attr, [Point3D.new(0, 0, 0), p_end], [[0, 1]])
	end

	def self.sphere(attr={}, npoints=16, n_neigh=8)
		dots = []
		npoints.times { |i|
			i += 0.5
			y = Math.cos(Math::PI*i/npoints)
			radius = Math.sin(Math::PI*i/npoints)
			ncirc = (2.0*npoints*radius).ceil
			ncirc.times { |j|
				dots << Point3D.new(radius*Math.cos(2*Math::PI*j/ncirc), y, radius*Math.sin(2*Math::PI*j/ncirc))
			}
		}

		lines = []
		dots.each_with_index { |d, i|
			dists = dots.map { |dd| d.dist(dd) }
			dists_sorted = dists.sort
			n_neigh.times { |ii|
				i2 = dists.index(dists_sorted[1+ii])
				lines << [i, i2]
			}
		}
		lines.delete_if { |i1, i2| i1 > i2 and lines.index([i2, i1]) }
		new(attr, dots, lines)
	end
end

class Camera3D
	attr_accessor :pos, :lookv, :upv, :screen_dist, :clip_dist
	def initialize(pos=Point3D.new(0, 0, 3), lookv=Point3D.new(0, 0, -1), upv=Point3D.new(0, 1, 0), screen_dist=2.0, clip_dist=0.1)
		# position
		@pos = pos
		# look (front) vector
		@lookv = lookv
		# up vector
		@upv = upv
		# screen distance (for projection), at @pos + screen_dist*@lookv
		@screen_dist = screen_dist
		# clip distance (similar to screen_dist, clip stuff behind this)
		@clip_dist = clip_dist
	end

	def rightv
		@lookv.cross(@upv)
	end

	def rotate!(vec)
		@lookv = @lookv.rotate(vec)
		@upv = @upv.rotate(vec)
	end

	def translate!(vec)
		@pos = @pos.translate(vec)
	end

	def angle_to_norm
		# return the vector to rotate by, so that lookv and up have their default value
		l = @lookv
		# make y == 0 && z <= 0
		if l.z > 0.0
			x = Math::PI + Math.atan(l.y/l.z)
		elsif l.z == 0.0
			x = l.y > 0 ? -Math::PI/2 : Math::PI/2
		else
			x = Math.atan(l.y/l.z)
		end
		l = l.rotate([x, 0.0, 0.0])

		# make x == 0
		if l.z == 0.0
			y = l.x > 0 ? Math::PI/2 : -Math::PI/2
		else
			y = -Math.atan(l.x/l.z)
		end

		u = @upv.rotate([x, y, 0.0])
		# make up == y
		if u.y < 0.0
			z = Math::PI + Math.atan(u.x/u.y)
		elsif u.y == 0.0
			z = l.x > 0 ? Math::PI/2 : -Math::PI/2
		else
			z = Math.atan(u.x/u.y)
		end

		Point3D.new(x, y, z)
	end

	# project the <what> on the camera's screen
	def project(what)
		what.translate(-@pos).rotate(angle_to_norm).clip_z(-@clip_dist).project_z(-@screen_dist)
	end
end
