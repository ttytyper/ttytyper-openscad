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
