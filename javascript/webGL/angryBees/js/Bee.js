var Bee = function(id) {
	this.pts = [];
	this.curves = [];
	this.stepId = 0;
	this.vertices = [];
	this.id = id;
	this.sphereR = 200;
	this.pVectors = [];
	this.vVectors = [];
	this.pi = Math.PI;
	this.path = [];

if (this.id < particleGroup.initCount) {
	this.addCurve();
} else {
	particleGroup.particleGeometry.vertices.push(this.getPointOffScreen());
}
};

Bee.prototype.toggleWireframe = function(){
	
	//this.material.wireframe = !this.material.wireframe;
}

Bee.prototype.getPointOffScreen = function() {
	return new THREE.Vector3(window.innerWidth * 1000, window.innerHeight * 1000, window.innerWidth * 1000);
}

Bee.prototype.getRandCircularPoint = function() {
	var vectors = new THREE.Vector2(2 * this.pi * Math.random(), 2 * this.pi * Math.random());
	var radius = Math.floor((Math.random()*250)+150);
	var num = Math.floor(Math.random()*500) + 1; // this will get a number between 1 and 99;
	num *= Math.floor(Math.random()*2) == 1 ? 1 : -1;
	return new THREE.Vector3(radius * Math.sin(vectors.y) * Math.cos(vectors.x),
		                     radius * Math.sin(vectors.y) * Math.sin(vectors.x),
                             radius * Math.cos(vectors.y));
}

Bee.prototype.update = function() {

	// we only want to create a curve for an 'active' particle
	// all other particles will live way off screen
	if (this.id < particleGroup.activeParticles.length - 1) {
		this.stepId = (this.stepId + 0.003);
		if (this.stepId >= 1) {
		 	// create a new curve with a starting point of our last point on the curve
		 	// this will make the curves continue seamlessly
		 	//console.log(this.path.getPointAt(1));
		 	this.addCurve(this.path.getPointAt(1));
		 	this.stepId = 0.1;
		 }

		 particleGroup.particleGeometry.vertices[this.id] = this.path.getPointAt(this.stepId);
	} else {
		// get a point waaaaaaay off screen
		particleGroup.particleGeometry.vertices[this.id] = this.getPointOffScreen();
	}
}

Bee.prototype.addCurve = function(startingPoint) {
	if (!startingPoint) startingPoint = this.getRandCircularPoint();
	var start = new THREE.Vector3(startingPoint.x, startingPoint.y, startingPoint.z); 
	if (this.path.length > 0) {
		this.path = new THREE.SplineCurve3([startingPoint,
		                           this.getRandCircularPoint(),
		                           this.getRandCircularPoint(),
		                           this.getRandCircularPoint(),
		                           this.getRandCircularPoint(),
		                           this.getRandCircularPoint(),
		                           this.getRandCircularPoint()]);
		particleGroup.particleGeometry.vertices.push(this.path.getPointAt(0));
	} else {
		//this.path = [];
		//particleGroup.particleGeometry.vertices[this.id] = [];
		this.path = new THREE.SplineCurve3([startingPoint,
		                           this.getRandCircularPoint(),
		                           this.getRandCircularPoint(),
		                           this.getRandCircularPoint(),
		                           this.getRandCircularPoint(),
		                           this.getRandCircularPoint(),
		                           this.getRandCircularPoint()]);
		particleGroup.particleGeometry.vertices[this.id] = this.path.getPointAt(0);
	}

	particleGroup.particleGeometry.verticesNeedUpdate = true;
}