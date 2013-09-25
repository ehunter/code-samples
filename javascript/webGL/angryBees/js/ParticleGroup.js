var ParticleGroup = function() {
	this.PARTICLECOUNT = 1000;
	this.particles = [];
	this.activeParticles = [];
	this.initCount = 2;
	this.angerLevel = 1;
	this.particleGeometry = new THREE.Geometry();
	this.particlePositions = [];
	var texture = THREE.ImageUtils.loadTexture("bee.png");
    this.particleMaterial = new THREE.ParticleBasicMaterial({
        map: texture,
        depthTest: false,
        blending: THREE.AdditiveBlending,
        size: 30,
        opacity: 1,
        transparent: true
    });
	
};

ParticleGroup.prototype.init = function() {
	// push only the active particles onto a sub array at first
	// as the hive becomes more angry, we'll add more particles to this activeParticles array
	for (var i = 0; i < this.initCount; i++) {
		this.activeParticles.push(new Bee(i));
		this.particles.push(this.activeParticles[i]);
		console.log("stoping at " + i);
	}
	//initially push all the particles onto a 'master' array
	for(var j = this.initCount; j < this.PARTICLECOUNT - this.initCount; j++) {
		console.log("starting at " + j);
		this.particles.push(new Bee(j));
	}

	this.particleSystem = new THREE.ParticleSystem(this.particleGeometry, this.particleMaterial);
    this.particleSystem.sortParticles = true;
    this.particleSystem.dynamic = true;
    scene.add(this.particleSystem);
}

ParticleGroup.prototype.update = function() {
	for(var i = 0; i < this.activeParticles.length; i++) {
		this.activeParticles[i].update();
	}
}

ParticleGroup.prototype.makeAngry = function() {
	this.angerLevel = (this.angerLevel + 1);

	var length = this.activeParticles.length;
	var newLength = length + this.angerLevel;

	console.log("particles length is " + this.activeParticles.length);
	console.log("newLength is " + newLength);

	for (var i = length; i < newLength-1; i++) {
		console.log(i);
		this.particles[i].addCurve();
		this.activeParticles.push(this.particles[i]);
	}

 this.particleSystem.geometry.__dirtyVertices = true;
 this.particleSystem.geometry.verticesNeedUpdate = true;
}

