use <shapes.scad>

linear_extrude(height=2)
	translate([5,0]) roundedSquare(30,[0,2,4,8]);

render() cubeExtrude([70,50,30],$fn=fn4(r=5+30))
	translate([5,0]) roundedSquare(30,[0,2,4,8]);
