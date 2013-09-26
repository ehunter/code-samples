var BeeHive = function() {

	this.bottomHiveGeometry;
	this.bottomHiveMaterial;
	this.bottomHiveCube;

	this.middleHiveGeometry;
	this.middleHiveMaterial;
	this.middleHiveCube;

	this.topHiveGeometry;
	this.topHiveMaterial;
	this.topHiveCube;

	this.hiveLidGeometry;
	this.hiveLidMaterial;
	this.hiveLidCube;

	this.hiveHandleGeometry;
	this.hiveHandleMaterial;
	this.hiveHandleCube;

	this.hiveHandle2Geometry;
	this.hiveHandle2Material;
	this.hiveHandle2Cube;

	this.hiveHandle3Geometry;
	this.hiveHandle3Material;
	this.hiveHandle3Cube;

	this.hiveOpeningGeometry;
	this.hiveOpeningMaterial;
	this.hiveOpeningCube;

	// mouse interaction vars
	//this.mouse = {x: 0, y: 0};
	//this.projector;
	this.hiveObjects = [];

    this.shakeTween = function(item, repeatCount)
    {
        var originalX = item.position.x;
        var originalY = item.position.y;
        var originalScale = item.position.scale;
        TweenLite.to(item.position, .1, {x:item.position.x + ((Math.random()*12)+5), ease:RoughEase.ease.config({strength:3, points:20, template:Elastic.easeIn, randomize:true}) });
        TweenLite.to(item.position, .1, {x:originalX, ease:RoughEase.ease.config({strength:3, points:20, template:Elastic.easeInOut, randomize:true}), delay:.1 });
    }
};

BeeHive.prototype.init = function() {
	var wireframeOn = false;

 //    ////////////////  HIVES
    var hiveOpacity = 0.95;
    //// create  bee hive boxes
    // bottom
    this.bottomHiveGeometry = new THREE.CubeGeometry(80,50,75);
    this.bottomHiveMaterial = new THREE.MeshBasicMaterial({ 
    	color:0xDEB887,
    	wireframe: wireframeOn,
    	wireframeLinewidth: 4,
    	transparent: true,
    	opacity: hiveOpacity
    });
    this.bottomHiveCube = new THREE.Mesh( this.bottomHiveGeometry, this.bottomHiveMaterial);
    //scene.add(this.bottomHiveCube);
    // opening
    this.hiveOpeningGeometry = new THREE.CubeGeometry(50,5,2);
    this.hiveOpeningMaterial = new THREE.MeshBasicMaterial({ 
        color:0x000000,
        wireframe: wireframeOn,
        wireframeLinewidth: 4,
        transparent: true,
        opacity: 0.75
    });
    this.hiveOpeningCube = new THREE.Mesh(this.hiveOpeningGeometry, this.hiveOpeningMaterial);
    // handle 3
    this.hiveHandle3Geometry = new THREE.CubeGeometry(30,5,2);
    this.hiveHandle3Material = new THREE.MeshBasicMaterial({ 
        color:0x000000,
        wireframe: wireframeOn,
        wireframeLinewidth: 4,
        transparent: true,
        opacity: 0.05
    });
    this.hiveHandle3Cube = new THREE.Mesh( this.hiveHandle3Geometry, this.hiveHandle3Material);
  
    // handle 2
    this.hiveHandle2Geometry = new THREE.CubeGeometry(30,5,2);
    this.hiveHandle2Material = new THREE.MeshBasicMaterial({ 
        color:0x000000,
        wireframe: wireframeOn,
        wireframeLinewidth: 4,
        transparent: true,
        opacity: 0.05
    });
    this.hiveHandle2Cube = new THREE.Mesh( this.hiveHandle2Geometry, this.hiveHandle2Material);

    // handle
    this.hiveHandleGeometry = new THREE.CubeGeometry(30,5,2);
    this.hiveHandleMaterial = new THREE.MeshBasicMaterial({ 
        color:0x000000,
        wireframe: wireframeOn,
        wireframeLinewidth: 4,
        transparent: true,
        opacity: 0.05
    });
    this.hiveHandleCube = new THREE.Mesh( this.hiveHandleGeometry, this.hiveHandleMaterial);

    // middle hive
    this.middleHiveGeometry = new THREE.CubeGeometry(80,35,75);
    this.middleHiveMaterial = new THREE.MeshBasicMaterial({ 
    	color:0xEEC591,
    	wireframe: wireframeOn,
    	wireframeLinewidth: 4,
    	transparent: true,
    	opacity: hiveOpacity
    });
    this.middleHiveCube = new THREE.Mesh( this.middleHiveGeometry, this.middleHiveMaterial);

    // top hive
    this.topHiveGeometry = new THREE.CubeGeometry(80,60,75);
    this.topHiveMaterial = new THREE.MeshBasicMaterial({ 
    	color:0xFFD39B,
    	wireframe: wireframeOn,
    	wireframeLinewidth: 4,
    	transparent: true,
    	opacity: hiveOpacity
    });
    this.topHiveCube = new THREE.Mesh( this.topHiveGeometry, this.topHiveMaterial);

    // hive lid
    this.hiveLidGeometry = new THREE.CubeGeometry(88, 17, 88);
    this.hiveLidMaterial = new THREE.MeshBasicMaterial({ 
        color:0xFFD39B,
        wireframe: wireframeOn,
        wireframeLinewidth: 4,
        transparent: true,
        opacity: hiveOpacity
    });
    this.hiveLidCube = new THREE.Mesh( this.hiveLidGeometry, this.hiveLidMaterial);

    scene.add(this.bottomHiveCube);
    scene.add(this.hiveOpeningCube);
    scene.add(this.hiveHandle3Cube);
    scene.add(this.hiveHandle2Cube);
    scene.add(this.hiveHandleCube);
    scene.add(this.middleHiveCube);
    scene.add(this.topHiveCube);
    scene.add(this.hiveLidCube);
    //positions
    this.bottomHiveCube.position.y = -49;

    this.hiveOpeningCube.position.y = -68;
    this.hiveOpeningCube.position.z = 44;
    //
    this.hiveHandle3Cube.position.y = 50;
    this.hiveHandle3Cube.position.z = 50;
    //
    this.hiveHandle2Cube.position.y = -6;
    this.hiveHandle2Cube.position.z = 50;
    //
    this.hiveHandleCube.position.y = -40;
    this.hiveHandleCube.position.z = 50;
    //
    this.middleHiveCube.position.y = -7;

    this.topHiveCube.position.y = 40;

    this.hiveLidCube.position.y = 78;

    //add all of these to an array for detecting mouse events on the objects themselves
    this.hiveObjects.push(this.bottomHiveCube, this.middleHiveCube, this.topHiveCube);
    ////////////////  END HIVES
}

BeeHive.prototype.getHiveObjects = function() {
	return this.hiveObjects;
}

BeeHive.prototype.shake = function() {
    this.shakeTween(this.middleHiveCube, 7);
    this.shakeTween(this.topHiveCube, 2);
    this.shakeTween(this.bottomHiveCube, 2);
    this.shakeTween(this.hiveLidCube, 2);
}