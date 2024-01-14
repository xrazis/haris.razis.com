---
title: "Creating Falling Objects Animation Using Canvas"
summary: Building a Canvas to animate falling objects in the background
date: 2023-11-24
tags: [ "Canvas" ]
draft: true
---

# Introduction

The Canvas API is used to draw graphics with Javascript. It can be utilized to make browser games, animations, visualize
data, and many more. We will create a really basic Canvas implementation that is fed a configuration file and draws the
falling items animation.

# Particle Class

The `Particle` class represents a single falling object. It is initialized with the same config object as the `Effect`
class, as it needs many of the same parameters for correctly placing a particle inside the viewport. The constructor
is where the majority of the logic is placed. After randomly picking the canvas position the image will appear we set
the size and speed with `Math.random()` so we get an effect of depth and different weight for each object.

```javascript
this.size = Math.Random() * 60 + 20;
this.speed = Math.random() * 0.5 + 0.2;
```

Then we need to randomly select an object from the sprite sheet and set the correct width/height. In order to reduce the
config options required, we set the frame size for the X and Y axis by assuming the elements in the sprite are equally
distanced on both axis.

```javascript
this.frameX = Math.floor(Math.random() * this.config.spriteElementsX);
this.frameY = Math.floor(Math.random() * this.config.spriteElementsY);
this.frameSizeX = this.config.image.width / this.config.spriteElementsX;
this.frameSizeY = this.config.image.height / this.config.spriteElementsY;
```

The draw function is responsible for

```javascript
function draw(canvas) {
  const ctx = canvas.getContext('2d');

  ctx.drawImage(this.config.image, this.frameX * this.frameSizeX, this.frameY * this.frameSizeY,
    this.frameSizeX, this.frameSizeY, this.x, this.y, this.size, this.size);
}
```

The draw function is responsible for

```javascript
function draw(canvas) {
  const ctx = canvas.getContext('2d');
  ctx.drawImage(this.config.image, this.frameX * this.frameSizeX, this.frameY * this.frameSizeY,
    this.frameSizeX, this.frameSizeY, this.x, this.y, this.size, this.size);
}
```

{{<details "Click for the complete `Particle` class">}}

```javascript
class Particle {
  constructor(config) {
    this.config = config;
    this.x = Math.random() * this.config.canvasWidth;
    this.y = Math.random() * this.config.canvasHeight;
    this.size = 100;
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

  draw(canvas) {
    const ctx = canvas.getContext('2d');
    ctx.drawImage(this.config.image, this.frameX * this.frameSizeX, this.frameY * this.frameSizeY,
      this.frameSizeX, this.frameSizeY, this.x, this.y, this.size, this.size);
  }
}
```

{{< /details >}}

# Effect Class

//TODO Analyze class and in that
// - Talk about the image on load event and the bug that will occur without using .onload()
// - Talk about requestAnimationFrame()

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
    for (let i = 0; i < this.particlesArray.length; i++) {
      this.particlesArray[i].canvasWidth = window.innerWidth;
      this.particlesArray[i].canvasHeight = window.innerHeight;
    }
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
    for (let i = 0; i < this.particlesArray.length; i++) {
      this.particlesArray[i].update();
      this.particlesArray[i].draw(this.canvas);
    }
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
- `spriteElementsX`: The images in the X axis in the sprite sheet.
- `spriteElementsY`: The images in the Y axis in the sprite sheet.

```javascript
const config = {
  canvas: 'canvas-animation',
  spriteUrl: './falling-items-sprite.png',
  particlesCount: 30,
  spriteElementsX: 3,
  spriteElementsY: 1,
};

const effect = new Effect(config);
```

![img.png](/blog/20230114-01.png)

# Sources

- [MDN Web Docs - Canvas API](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API)
- 