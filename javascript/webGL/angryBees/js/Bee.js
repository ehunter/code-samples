var Bee = function(id) {
	this.stepId = 0;
	this.id = id;
	this.pi = Math.PI;
	this.path = [];

if (this.id < particleGroup.initCount) {
	this.addCurve();
} else {
	particleGroup.particleGeometry.vertices.push(this.getPointOffScreen());
}
};

Bee.prototype.getPointOffScreen = function() {
	return new THREE.Vector3(window.innerWidth * 1000, window.innerHeight * 1000, window.innerWidth * 1000);
}

Bee.prototype.getRandCircularPoint = function() {
	var vectors = new THREE.Vector2(2 * this.pi * Math.random(), 2 * this.pi * Math.random());
	var radius = ((Math.random()*250)+150);
	return new THREE.Vector3(radius * Math.sin(vectors.y) * Math.cos(vectors.x),
		                     radius * Math.sin(vectors.y) * Math.sin(vectors.x),
                             radius * Math.cos(vectors.y));
}

Bee.prototype.update = function() {

	// we only want to create a curve for an 'active' bee
	// all other bees will live way off screen
	if (this.id < particleGroup.activeParticles.length - 1) {
		this.stepId += 0.003
		if (this.stepId >= 1) {
		 	// create a new curve with a starting point of our last point on the curve
		 	// this will make the curves continue seamlessly
		 	//console.log(this.path.getPointAt(1));
		 	this.addCurve(this.path.getPointAt(1));
		 	this.stepId = 0.1;
		 }

		 particleGroup.particleGeometry.vertices[this.id] = this.path.getPointAt(this.stepId);
	} else {
		// get a point waaaaaaay off screen. This 'hides' the bee until we create a curve for it
		particleGroup.particleGeometry.vertices[this.id] = this.getPointOffScreen();
	}
}

Bee.prototype.addCurve = function(startingPoint) {
	if (!startingPoint) startingPoint = this.getRandCircularPoint();
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