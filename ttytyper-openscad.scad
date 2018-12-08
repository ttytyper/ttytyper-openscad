/***** 2D modules *****/
/** 2D profile for fillet operations
 *
 * Positive r gives convex rounds (90 degree "pizza slices"), suitable for
 * outer corners.
 *
 * Negative r gives concave fillets, suitable for inner corners
 */
module filletProfile(r) {
	ar=abs(r);

	// Concave
	if(r<0) {
		translate([ar,ar])
			polygon(concat([[-ar,-ar]],
				arc(r=ar,a1=180,a2=270),
				[[-ar,-ar]]));
	}
	// Convex
	else if(r>0) {
		polygon(concat([[0,0]],
			arc(r=ar,a1=0,a2=90),
			[[0,0]]));
	}
	// Intentionally left blank, as r=0 should result in nothing
	else {
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
 * @param size Size of the rectangle. Can be a single number or a vector [x,y]
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
				rotate(corner[0]) filletProfile(r=corner[2]);
			}
		}
	}
}

/***** 3D modules *****/

/** Extrudes given object around a square/cube outline
 *
 * Note: $fn should be divisible by 4 to ensure that the extruded corners line up with the extruded walls.
 *
 * Note: It may be necessary to use render() to render cubeExtrude() correctly in preview mode
 *
 * @param size Size of the virtual square/cube to wrap the object around. The z dimension is only used if center=true
 * @param fill Fill the cube. Default: False
 * @param center Bool. If true, the result is centered around origin
 * @param e Enlarge certain dimensions by this much to help create a valid 2-manifold object
 *
 * Example:
 *   cubeExtrude([60,50],$fn=fn4(r=5+30))
 *     translate([5,0]) roundedSquare(30,[0,2,4,8]);
 *
 */
module cubeExtrude(size,fill=false,center=false,e=0.0001) {
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
		translate([size.x-e, size.y])
			rotate([90,0,90]) translate([0,0,-size.x])
				linear_extrude(height=size.x+e*2) children();

		// Lower side
		translate([e,0])
			rotate([90,0,270]) translate([0,0,-size.x])
				linear_extrude(height=size.x+e*2) children();

		// Left side
		translate([0, -e])
			rotate([90,0,180])
				linear_extrude(height=size.y+e*2) children();

		// Right side
		translate([size.x, size.y+e])
			rotate([90,0,0])
				linear_extrude(height=size.y+e*2) children();
		if(fill==true) {
			translate([-e,-e])
				cube(size+[e,e,0]*2);
		}
	}

	module corner() {
		// rotate_extrude(angle=90) would be a nice touch and might let us
		// forget about handling $fn. But unfortunately it has only been
		// available since 2016.XX, which is too modern for Debian Stretch
		// (stable at the point of writing this). So instead we muck around
		// with intersecting the full rotation with an infinitely-ish large
		// cube.
		intersection() {
			rotate_extrude()
				children();
			for(m=[0,1]) mirror([0,0,m]) // Catch both +z and -z vertices
				cube(pinf);
		}
	}
}

/**
 * Cylinder with rounded end caps
 *
 * @param r  Radius of the cylinder
 * @param h  Height of the cylinder
 * @param f  Fillet radius of both ends
 * @param f1 Bottom fillet radius only
 * @param f2 Top fillet radius only
 * @param center Boolean. Center cylinder around origin. Default: false
 *
 * TODO: Support different radii for top and bottom, just like cylinder(r1=foo, r2=bar, h=baz);
 */
module roundedCylinder(r,h,f=0,f1,f2,center=false) {
	f1=(f1!=undef?f1:f);
	f2=(f2!=undef?f2:f);

	// Bottom center
	c1=[r-f1,f1];
	// Top center
	c2=[r-f2,h-f2];

	translate([0,0,center?-h/2:0])
	rotate_extrude()
	polygon(
		concat(
			[[0,0]],
			[[0,h]],
			arc(r=f2,a2=0,a1=90,tr=c2),
			arc(r=f1,a2=90,a1=180,tr=c1),
			[[0,0]]
		)
	);
}

/***** Meassuring tools  *****/

/**
 * Shows the distance between two points in 2D or 3D space
 *
 * A meassuring rod is rendered between the two points, labelled with the distance between them. The distance is also echoed to the console.
 *
 * The tool is rendered using '%'. It is only rendered in previews, not in the final product.
 *
 * @param p1 First meassuring point [x,y] or [x,y,z]
 * @param p2 Second meassuring point [x,y] or [x,y,z]
 * @param label Optional label
 * @param valign Vertical align of the label. "top" and "bottom" are good options. Default: "bottom"
 * @param color Color of the caliper. Default: "white"
 * @param alpha Alpha (opacity/transparency) of the caliper. Default: 1
 */
module caliper(p1,p2,label="",valign="bottom",color="white",alpha=1) {
	// Ensure that all three dimensions are set
	p1=[
		p1.x!=undef?p1.x:0,
		p1.y!=undef?p1.y:0,
		p1.z!=undef?p1.z:0,
	];
	p2=[
		p2.x!=undef?p2.x:0,
		p2.y!=undef?p2.y:0,
		p2.z!=undef?p2.z:0,
	];
	distance=norm(p1-p2);

	distanceStr=str(label,distance);
	echo(str("Caliper meassured: ",distanceStr));

	// https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Transformations#Rotation_rule_help
	inclination=acos(abs(p1.z-p2.z)/distance);
	azimuth=atan2(abs(p1.y-p2.y),abs(p1.x-p2.x));

	// Visual aid sizes
	rodRadius=distance*0.005;
	pointerRadius=distance*0.02;
	pointerLength=distance*0.02;
	fontSize=distance*0.1;
	fontMargin=rodRadius;

	%color(color,alpha=alpha) translate(p1) rotate([0,inclination,azimuth]) {
		// Text
		rotate([90,270,270])
			translate([distance/2,(rodRadius+fontMargin)*(valign=="bottom"?1:valign=="top"?-1:0),0]) 
				text(distanceStr,size=fontSize,valign=valign,halign="center");
		// Meassuring rod
		translate([0,0,pointerLength])
			cylinder(r=rodRadius,h=distance-pointerLength*2);
		// p1 pointer
		cylinder(r1=0,r2=pointerRadius,h=pointerLength);
		// p2 pointer
		translate([0,0,distance-pointerLength])
			cylinder(r2=0,r1=pointerRadius,h=pointerLength);
	}
}

/***** Functions  *****/

/** Calculate $fn based on $fs, $fa and radius
 *
 * Ported from:
 * https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/The_OpenSCAD_Language (get_fragments_from_r)
 */
function fn(r,a=360) = ceil(max(min(360.0 / $fa, r*2*PI / $fs), 5)*(a/360));

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
 * There are $fn+1 vectors distributed evenly along the length of the arc. This
 * function returns any one of them by their index number.
 *
 * @param r  Radius of the arc
 * @param a1 Start angle of the arc (default 0)
 * @param a2 End angle of the arc (default 360)
 * @param i  Index of the vector (default 0)
 * @param tr Translate (move) by [x,y]
 */
function arcPoint(r,a1=0,a2=360,i=0,tr=[0,0]) =
	let($fn=($fn>0?$fn:fn(r,abs(a1-a2))))
	let(deg=(a2-a1)/$fn*i+a1)
	[r*sin(deg), r*cos(deg)]+tr;

/**
 * Returns a series of vectors forming an arc
 *
 * @param r Radius of the arc
 * @param a1 Start angle of the arc
 * @param a2 End angle of the arc
 * @param tr Translate (move) by [x,y]
 */
function arc(r,a1,a2,tr=[0,0],_i=0,_v=[]) =
	let($fn=($fn>0?$fn:fn(r,abs(a1-a2))))
	(_i>$fn?_v:concat(arc(r,a1,a2,tr,_i+1,_v),[arcPoint(r=r,a1=a1,a2=a2,i=_i,tr=tr,$fn=$fn)]));

/***** Variables  *****/
inf = 1e200 * 1e200;
// Practical infinity. Apparently the largest number accepted by e.g. intersection() { cube(pinf); whatever(); }
pinf = 1e12;
