/***** 2D modules *****/
/** 2D profile for fillet operations
 *
 * Positive r gives convex rounds (90 degree "pizza slices"), suitable for
 * outer corners.
 *
 * Negative r gives concave fillets, suitable for inner corners
 */
module filletProfile(r) {
	$fn=fn4(abs(r));
	ar=abs(r);

	if(r<0) {
		translate([ar,ar]) mirror([1,1]) difference() {
			square(ar);
			circle(r=ar);
		}
	}
	else if(r>0) {
		intersection() {
			square(ar);
			circle(ar);
		}
	}
	else {
		// Intentionally left blank, as r=0 should result in nothing
	}
}

/** Creates a rectangle, optionally with rounded corners.
 *
 * The name roundedSquare is actually a misnomer, following OpenSCAD module
 * naming. Just like square(), it can indeed produce rectangles.
 *
 * The radius of all four corners can be controlled collectively or
 * individually.
 *
 * Note: This module overrides $fn to line up the rounded corners perfectly.
 * Use $fa and $fs to control the level of detail.
 *
 * Examples:
 *
 * Ordinary rectangle:
 *   roundedSquare([20,30]);
 *
 * Rectangle with radius 2 on all corners:
 *   roundedSquare(size=[20,30], r=2];
 *
 * Rectangle with different radii on every corner:
 *   roundedSquare(size=[20,30], r=[0,2,4,8]);
 *
 * Same, centered:
 *   roundedSquare(size=[20,30], r=[0,2,4,8], center=true);
 *
 * Square with different radii on every corner:
 *   roundedSquare(size=20, r=[0,2,4,8]);
 *
 * Same, short call:
 *   roundedSquare(20,[0,2,4,8]);
 *
 * Todo:
 *   Support negative radii for inset corners. Already supported by filletProfile()
 *
 * @param size Size of the rectange. Can be a single number or a vector [x,y]
 * @param r Number. Corner radius or radii (clockwise starting at lower left)
 * @param center Bool. Center the rectangle around origin. Default: false
 */
module roundedSquare(size,r=0,center=false) {
	// If a single value was given, turn it into an array
	r=(len(r)==undef?[r,r,r,r]:r);
	s=(len(size)==undef?[size,size]:size);

	points=[
		// X,      Y
		[r[0],     r[0]      ], 
		[r[1],     s[1]-r[1] ], 
		[s[0]-r[2],s[1]-r[2] ], 
		[s[0]-r[3],r[3]      ], 
	];

	translate([
		center?-s[0]/2:0,
		center?-s[1]/2:0
	])
	hull() {
		// All the hard corners
		polygon(points);
		
		// All the round corners
		for(corner=[
			// A, center,    R,
			[180, points[0], r[0] ], // Lower left
			[ 90, points[1], r[1] ], // Upper left
			[  0, points[2], r[2] ], // Upper right
			[270, points[3], r[3] ]  // Lower right
		]) {
			translate(corner[1]) {
				if(corner[2]*2 > min(s[0],s[1]))
					echo("<font color=red>roundedSquare: Corner diameter ", corner[2]*2, " is larger than the smallest width or height of the rectangle ",min(s[0],s[1]), ". This will probably give undesired results</font>");
				rotate(corner[0]) filletProfile(r=corner[2],$fn=corner[2]);
			}
		}
	}
}

/***** 3D modules *****/

/** Extrudes given object around a square/cube outline
 *
 * Note: $fn should be divisible by 4 to ensure that the extruded corners line up with the extruded walls.
 *
 * @param size Size of the virtual square/cube to wrap the object around. The z dimension is only used if center=true
 * @param center Bool. If true, the result is centered around origin
 *
 * Example:
 *   boxExtrude([60,50],$fn=fn4(r=5+30))
 *     translate([5,0]) roundedSquare(30,[0,2,4,8]);
 *
 */
module cubeExtrude(size,center=false) {
	translate([center?-size.x/2:0, center?-size.y/2:0, center?-size.z/2:0]) {
		// Lower left corner
		rotate(180) corner() children();

		// Upper left corner
		translate([0,size.y])
			rotate(90) corner() children();

		// Lower right corner
		translate([size.x,0])
			rotate(270) corner() children();

		// Upper right corner
		translate([size.x,size.y])
			corner() children();

		// Upper side
		translate([size.x, size.y])
			rotate([90,0,90]) translate([0,0,-size.x])
				linear_extrude(height=size.x) children();

		// Lower side
		rotate([90,0,270]) translate([0,0,-size.x])
			linear_extrude(height=size.x) children();

		// Left size
		rotate([90,0,180])
			linear_extrude(height=size.y) children();

		// Right size
		translate([size.x, size.y])
			rotate([90,0,0])
				linear_extrude(height=size.y) children();
	}
	module corner() {
		intersection() {
			rotate_extrude()
				children();
			for(m=[0,1]) mirror([0,0,m])
				cube(pinf);
		}
	}
}

/***** Functions  *****/

/** Calculate $fn based on $fs, $fa and radius
 *
 * Ported from:
 * https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/The_OpenSCAD_Language (get_fragments_from_r)
 */
function fn(r) = ceil(max(min(360.0 / $fa, r*2*PI / $fs), 5));

/** Force $fn to be divisible by n
 *
 * Particularly useful with n=4 to guarantee that the "corners" of circles line
 * up with walls
 */
function fndivby(r,n) = ceil(fn(r)/n)*n;
// Shorthand
function fn4(r) = fndivby(r,4);

/** Helpers for making circular objects the correct size
 *
 * https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/undersized_circular_objects
 */
function outerFudge(r) = r * (1/cos(180/($fn>0?$fn:fn(r))));
function midFudge(r) = r * (1+1/cos(180/($fn>0?$fn:fn(r)))/2);

/**
 * Returns the vector [x,y] of a point along an imagined arc
 *
 * There are $fn vectors distributed evenly along the length of the arc. This
 * function returns any one of them by their index number.
 *
 * @param r  Radius of the arc
 * @param a1 Start angle of the arc (default 0)
 * @param a2 End angle of the arc (default 360)
 * @param i  Index of the vector (default 0)
 */
function arcPoint(r,a1=0,a2=360,i=0) =
	let($fn=($fn>0?$fn:fn(r)))
	let(deg=(a2-a1)/$fn*i)
	[r*sin(deg+a1), r*cos(deg+a1)];

/**
 * Returns a series of vectors forming an arc
 *
 * @param r Radius of the arc
 * @param a1 Start angle of the arc
 * @param a2 End angle of the arc
 */
function arc(r,a1,a2,_i=0,_v=[]) =
	let($fn=($fn>0?$fn:fn(r)))
	(_i>$fn?_v:concat(arc(r,a1,a2,_i+1,_v),[arcPoint(r=r,a1=a1,a2=a2,i=_i,$fn=$fn)]));

/***** Variables  *****/
inf = 1e200 * 1e200;
// Practical infinity. Apparently the largest number accepted by e.g. intersection() { cube(pinf); whatever(); }
pinf = 1e12;
