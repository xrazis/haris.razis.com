---
title: "Creating Falling Objects Animation Using Canvas"
summary: Building a basic Canvas library to animate falling objects in the background (snowfall effect)
date: 2024-01-18
tags: [ "Canvas" ]
draft: false
---

# Introduction

The Canvas API is used to draw graphics with Javascript. It can be utilized to make browser games, animations, visualize
data, and much more. We will create a really basic Canvas library that receives input from a configuration file and
draws the falling items animation.

# Particle Class

The `Particle` class represents a single falling object. It is initialized with the same config object as the `Effect`
class, as it needs many of the same parameters for correctly placing a particle inside the viewport. The constructor
is where the majority of the logic is placed. After randomly picking the position in the canvas, we set the size and
speed with `Math.random()` so we get an effect of depth and different weight for each object.

```javascript
this.x = Math.random() * this.config.canvasWidth;
this.y = Math.random() * this.config.canvasHeight;
this.size = Math.random() * 60 + 20;
this.speed = Math.random() * 0.5 + 0.2;
```

Then we need to randomly select an object from the sprite sheet and set the correct width/height. In order to reduce the
initial config options required, we set the frame size for the X and Y axis by assuming the elements in the sprite are
equally distanced on both axis.

```javascript
this.frameX = Math.floor(Math.random() * this.config.spriteElementsX);
this.frameY = Math.floor(Math.random() * this.config.spriteElementsY);
this.frameSizeX = this.config.image.width / this.config.spriteElementsX;
this.frameSizeY = this.config.image.height / this.config.spriteElementsY;
```

The draw function is responsible for drawing the image on the canvas. The input parameters are best explained
on [MDN](https://developer.mozilla.org/en-US/docs/web/api/canvasrenderingcontext2d/drawimage).

```javascript
function draw(ctx) {
  ctx.drawImage(this.config.image, this.frameX * this.frameSizeX, this.frameY * this.frameSizeY,
    this.frameSizeX, this.frameSizeY, this.x, this.y, this.size, this.size);
}
```

Lastly, the update function moves the particle down the Y axis, thus providing the snowfall animation. The speed config
option determines the speed of the particle falling. It is important to reset the particle position to the top of the
canvas once it has surpassed the canvas height - that way the animation will continue running indefinitely.

```javascript
function update() {
  this.y += this.speed;
  if (this.y - this.size > this.config.canvasHeight) {
    this.y = 0 - this.size;
  }
}
```

{{<details "Click for the complete `Particle` class">}}

```javascript
class Particle {
  constructor(config) {
    this.config = config;
    this.x = Math.random() * this.config.canvasWidth;
    this.y = Math.random() * this.config.canvasHeight;
    this.size = Math.random() * 60 + 20;
    this.speed = Math.random() * 0.5 + 0.2;
    this.frameX = Math.floor(Math.random() * this.config.spriteElementsX);
    this.frameY = Math.floor(Math.random() * this.config.spriteElementsY);
    this.frameSizeX = this.config.image.width / this.config.spriteElementsX;
    this.frameSizeY = this.config.image.height / this.config.spriteElementsY;
  }

  get canvasWidth() {
    return this.config.canvasWidth;
  }

  set canvasWidth(width) {
    this.config.canvasWidth = width;
  }

  get canvasHeight() {
    return this.config.canvasHeight;
  }

  set canvasHeight(height) {
    this.config.canvasHeight = height;
  }

  update() {
    this.y += this.speed;
    if (this.y - this.size > this.config.canvasHeight) {
      this.y = 0 - this.size;
    }
  }

  draw(ctx) {
    ctx.drawImage(this.config.image, this.frameX * this.frameSizeX, this.frameY * this.frameSizeY,
      this.frameSizeX, this.frameSizeY, this.x, this.y, this.size, this.size);
  }
}
```

{{< /details >}}

# Effect Class

The `Effect` class is used to create and manipulate `Particle` classes. In the constructor the config object is set,
then the sprite is loaded, and only when loaded is the rest of the code allowed to run. If you try to execute
any code that needs the image prior to that you are not guaranteed that the image will be loaded.

```javascript
this.config = config;
this.image = new Image();
this.image.onload = () => {
  this.config.image = this.image;
  this.canvas = document.getElementById(this.config.canvas);
  this.ctx = this.canvas.getContext('2d');
  this.particlesArray = [];
  this.setCanvasDimensions();
  this.initParticlesArray();
  this.handleParticles();
  this.startAnimation();
  this.registerListeners();
}
this.image.src = this.config.spriteUrl;
```

Once the image is loaded, the canvas is created, and a drawing context is set - a 2d rendering context in our case. Then
we set the window dimensions both in the canvas and the config object.

```javascript
function setCanvasDimensions() {
  this.canvas.width = window.innerWidth;
  this.canvas.height = window.innerHeight;
  this.config.canvasWidth = window.innerWidth;
  this.config.canvasHeight = window.innerHeight;
}
```

This is done for a very specific reason. The `Particle` needs to know the canvas width and height. In this case it is
the window width and height, but in other cases it may as well be different. This way we can choose the `Particle`
position randomly somewhere inside that canvas. Keep in mind that we also need to accommodate for any resize events, an
expensive but necessary operation.

```javascript
function setParticleDimensions() {
  this.particlesArray.forEach(particle => {
    particle.canvasWidth = this.config.canvasWidth;
    particle.canvasHeight = this.config.canvasHeight;
  });
}

function onResize() {
  this.setCanvasDimensions();
  this.setParticleDimensions();
}

function registerListeners() {
  window.addEventListener('resize', () => this.onResize());
}
```

Then, the `Particles` are created, and the animation is started. I have used the `requestAnimationFrame` and not
a `setInterval`. That is because setting an interval is not a reliable way to animate things - in the case the function
provided takes longer than 16ms (1/60 sec - 60FPS) that will cause blocking and result in dropped frames.
The `requestAnimationFrame` invokes the callback function at each repaint. This is typically every 1/60th of a second,
thus providing the wanted frame rate of 60FPS.

{{<details "Click for the complete `Effect` class">}}

```javascript
class Effect {
  constructor(config) {
    this.config = config;
    this.image = new Image();
    this.image.onload = () => {
      this.config.image = this.image;
      this.canvas = document.getElementById(this.config.canvas);
      this.ctx = this.canvas.getContext('2d');
      this.particlesArray = [];
      this.setCanvasDimensions();
      this.initParticlesArray();
      this.handleParticles();
      this.startAnimation();
      this.registerListeners();
    }
    this.image.src = this.config.spriteUrl;
  }

  setCanvasDimensions() {
    this.canvas.width = window.innerWidth;
    this.canvas.height = window.innerHeight;
    this.config.canvasWidth = window.innerWidth;
    this.config.canvasHeight = window.innerHeight;
  }

  setParticleDimensions() {
    this.particlesArray.forEach(particle => {
      particle.canvasWidth = this.config.canvasWidth;
      particle.canvasHeight = this.config.canvasHeight;
    });
  }

  initParticlesArray() {
    for (let i = 0; i < this.config.particlesCount; i++) {
      this.particlesArray.push(new Particle(this.config));
    }
  }

  clearRect() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
  }

  handleParticles() {
    this.clearRect();
    this.particlesArray.forEach(particle => {
      particle.update();
      particle.draw(this.ctx);
    });
  }

  onResize() {
    this.setCanvasDimensions();
    this.setParticleDimensions();
  }

  startAnimation() {
    const render = () => {
      this.handleParticles();
      requestAnimationFrame(render);
    }
    render();
  }

  registerListeners() {
    window.addEventListener('resize', (e) => this.onResize());
  }
}
```

{{< /details >}}

# Initialization of the effect

The following script is the initialization code for the Effect class. The input is a
config object with the following options:

- `canvas`: The id of the Canvas HTML element.
- `spriteUrl`: The image (in the form of a sprite) to be used for the falling objects.
- `particlesCount`: The items count to be created - they are randomly selected from the sprite.
- `spriteElementsX`: The images in the X axis of the sprite sheet.
- `spriteElementsY`: The images in the Y axis of the sprite sheet.

```javascript
const config = {
  canvas: 'canvas-animation',
  particlesCount: 10,
  spriteUrl: "https://haris.razis.com/blog/20240114-cat.png",
  spriteElementsX: 5,
  spriteElementsY: 2,
};

new Effect(config);
```

You can observe the code running in the following CodePen, voilà!

{{< codepen "oNVBgMP">}}

# Sources

- [MDN Web Docs - Canvas API](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API)