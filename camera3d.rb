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
