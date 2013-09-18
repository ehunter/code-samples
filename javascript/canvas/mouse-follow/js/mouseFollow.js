var canvas,
    c,
    mouseXPositions = [],
    mouseYPositions = [],
    hue = 0;

$(document).ready(function() {
  canvas = document.getElementById('canvas');
  c = canvas.getContext('2d');
});

function draw() {
  
  c. clearRect(0,0,640,480);
  
  mouseXPositions.push(mouseX);
  mouseYPositions.push(mouseY);
  
  if (mouseXPositions.length > 100) {
    mouseXPositions.shift();
    mouseYPositions.shift();
  }
  
  for (var i = 0; i < mouseXPositions.length; i++) {
    c.lineWidth = 4;
    c.strokeStyle = hsla(hue+1, 100, 50, 0.05);
    c.strokeCircle(mouseXPositions[i], mouseYPositions[i], map(i,0,100,50,0));
  }
  hue++;
}