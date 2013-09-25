if(!Detector.webgl)
	Detector.addGetWebGLMessage();

var mouseX = 0,
	mouseY = 0,
    camera,
    scene,
    renderer,
    container,
    particleGroup,
    beeHive,
    mouse = {x: 0, y:0},
    projector;

init();

function init() {
	container = document.createElement('div');
	document.body.appendChild(container);

	// create camera
	camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 1, 10000);
	camera.position.z = 400;

	// create scene
	scene = new THREE.Scene();
	scene.add(camera);
	renderer = new THREE.WebGLRenderer({
		antialias : true,
		sortObjects : false
	});
	renderer.setSize(window.innerWidth, window.innerHeight);

	// projector is used for detecting mouse events
	projector = new THREE.Projector();

	container.appendChild(renderer.domElement);
	
	// stop the user getting a text cursor
	document.onselectStart = function() {
		return false;
	};

	particleGroup = new ParticleGroup();
	particleGroup.init();

	beeHive = new BeeHive();
	beeHive.init();

	document.addEventListener('mousemove', onDocumentMouseMove, false);
	document.addEventListener('click', onMouseClick);
	window.addEventListener('resize', onWindowResize, false);
	onWindowResize(null);
	animate();
}

function onMouseClick(event) {
    event.preventDefault();
    // update the mouse variable
    mouse.x = ( event.clientX / window.innerWidth ) * 2 - 1;
    mouse.y = - ( event.clientY / window.innerHeight ) * 2 + 1;

    // create a Ray with origin at the mouse position and direction into the scene (camera direction)
    var vector = new THREE.Vector3( mouse.x, mouse.y, 1);
    projector.unprojectVector(vector, camera);
    var ray = new THREE.Raycaster(camera.position, vector.sub( camera.position ).normalize());

    // create an array containing all the hive frames where the ray intersects
    var intersects = ray.intersectObjects( beeHive.hiveObjects );
    
    // if there is one (or more) intersections of the frame objects
    if ( intersects.length > 0 )
    {
        console.log("Hive was clicked. Add more bees to the particle system");
        particleGroup.makeAngry();
        // how to access the faces of the hive
        //intersects[ 0 ].face.color.setRGB( 0.8 * Math.random() + 0.2, 0, 0 ); 
        //intersects[ 0 ].object.geometry.colorsNeedUpdate = true;
    }
}

function onDocumentMouseMove(event) {
	mouseX = event.clientX - (window.innerWidth / 2);
	mouseY = event.clientY - (window.innerHeight / 2);
}

function onWindowResize(event) {
	camera.aspect = window.innerWidth / window.innerHeight;
	camera.updateProjectionMatrix();
	renderer.setSize(window.innerWidth, window.innerHeight);
}

function animate() {
	requestAnimationFrame(animate);
	render();
}

function render() {
	particleGroup.update();
	camera.position.x += (mouseX - camera.position.x ) * .1;
	camera.position.y += (-mouseY - camera.position.y ) * .1;
	camera.lookAt(scene.position);
	renderer.render(scene, camera);
}

$(window).mousewheel(function(event, delta) {
	//set camera Z
	camera.position.z -= delta * 50;
});