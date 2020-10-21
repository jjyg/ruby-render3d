require File.expand_path('../point3d', __FILE__)

# collection of connected Point3D (wireframe)
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
