use <shapes.scad>

// roundedSquare()
linear_extrude(height=2)
	translate([5,0]) roundedSquare(30,[0,2,4,8]);

// cubeExtrude()
render() cubeExtrude([70,50,30],$fn=fn4(r=5+30))
	translate([5,0]) roundedSquare(30,[0,2,4,8]);

// arc()
// Pacman, or a very inviting pie
linear_extrude(height=2) translate([-80,0])
	polygon(concat([[0,0]],arc(30,a1=65,a2=-240),[[0,0]]));

// Animated pacman (View -> Animate)
linear_extrude(height=2) translate([-80,65])
	polygon(concat([[0,0]],arc(30,a1=(90-10)+10*sin($t*360),a2=-270+25-25*sin($t*360)),[[0,0]]));
