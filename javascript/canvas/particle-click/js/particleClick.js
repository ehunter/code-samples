var canvas,
    c,
    particles = [],
    gravity = -0.1, 
    shrink = 0.99;

$(document).ready(function() {
  canvas = document.getElementById('canvas');
  c = canvas.getContext('2d');

  makeParticles(550, canvas.width/2, canvas.height/2);

  // on mouseDown create 50 particles based on the mouseX and mouseY
  $('canvas').mousedown(function(e){
    makeParticles(randomInteger(10, 99), e.clientX, e.clientY);
  });
});

function draw() { 
  c.clearRect(0,0, canvas.width, canvas.height);

  // set a max of 100 particles in our array at a time
  while(particles.length > 100) { 
    particles.shift();
  }

  for(var i = 0; i<particles.length; i++) { 
    var p = particles[i];
    // add speed to the position
    p.x+=p.xVel; 
    p.y+=p.yVel;
    p.hue+=5;
    // add gravity
    p.yVel += gravity;
    // make particle shrink; 
    p.size *= shrink - (0.05 + (0.02-0.05)*Math.random()); 

    if(p.y+p.size >= canvas.height) {
      p.y = canvas.height - p.size;
      p.yVel *= -0.7; 
    }

    c.fillStyle = hsla(p.hue, 100, 50, randomInteger(50, 99));
    c.fillCircle(p.x,p.y,p.size); 
 }
}

function makeParticles(numParticles, x, y) { 
 // make numParticles particles
 for(var i = 0; i<numParticles; i++) { 
   var p = { x : x, 
             y : y, 
             xVel : random(-5,5), 
             yVel : random(-5,5), 
             size : random(14,25),
             hue  : randomInteger(1, 320)}; 
   particles.push(p); 
 } 
}

function drawCircle(circ) {
  c.strokeStyle = hsl(angleCount, angleCount, 50);
  c.beginPath();
  c.arc(circ.x, circ.y, circ.radius, 0, Math.PI * 2, false);
  c.stroke();
}
