---
title: "Body position tracking"
summary: Scalable IoT solution for real-time body position tracking
date: 2021-11-26
tags: [ "Web", "Frontend", "Backend", "Networking", "System" ]
draft: false
---

# Introduction

A while ago I submitted my thesis with its subject being the study of the architecture of BAN and PAN, and their
applications, with the aim of optimizing athletes performance, by enhancing personalized training practices. I was also
tasked with creating an e-sport application that would collect and analyze data on the athlete’s body position in
real-time. I named the e-sport application Icnhaea, and I will be referring to it as so for the rest of this post.

Developing Ichnaea proved a challenge for me, as it tested my knowledge and understanding of full-stack applications. I
wanted to build a resilient, multi-tenant application with scaling capabilities that would not just tick the boxes for a
thesis but be a worthwhile project that would make me a better engineer.

This post will be a rough overview of the thesis. You can find the source and
doc [here](https://github.com/xrazis/ichnaea).

# Architecture

To begin with, deployment is handled by docker and docker-compose. Abstracting the configuration to a handy yaml file,
while keeping the development environment the same across machines makes deployment a breeze. Running the project will
create the following services:

- **Client**, a Node.js app that collects and sends the data to the backend.
- **Backend**, a Node.js server that is responsible for data and user storage, client and SPA socket connection, and
  exposing an API.
- Three Databases, each for its distinct purpose:
    - **Influxdb**, used to store the bulk of data produced from the client devices.
        - A **Grafana** instance, attached to Influx.
    - **Redis**, used for publish-subscribe.
    - **MongoDB**, used as the user store.
- **Frontend**, a SPA built on Vue with Typescript.

![thesis.drawio.png](/blog/ichnaea/thesis.drawio.png#center)

As you can see, I decided to go full-on with JavaScript and TypeScript for Ichnaea, as I was already familiar with lots
of libraries and frameworks in the respective ecosystems.

# Client

The client device is an Arduino with an IMU sensor. The program can either run on the host machine or on a Raspberry Pi
that acts like a getaway for the Arduino. The client does some basic calculations with the help of Johnny-five, then the
data is then streamed to the server, and subsequently to the frontend. The frontend does the final calculations that are
needed for the model visualization. This way we avoid making any 'heavy' computations on the client device, thus
allowing for small and power efficient getaways like a Pi Zero with multiple micro-controllers attached on it.

### What is an IMU and how do you make sense of its readings?

An Inertial Measurement Unit can be found pretty much everywhere today and is a combination of accelerometers,
gyroscopes, and magnetometers. They are used in navigation systems, smartphones, fitness trackers, and many more.
Classified by Degrees Of Freedom, an IMU of 9-DOF will feature 3 degrees each of acceleration, magnetic orientation, and
angular velocity. As a rule of thumb the higher the DOF rating the more accurate an IMU will be.

To get some meaningful readings from an IMU a filter has to be used. There are many implementations from the notoriously
hard Kalman filter to the relatively newly founded Madgwick filter. I decided to go with the complementary filter, an
easy-to-understand and even easier to implement a filter. With the complementary filter we are keeping the best
attributes from each sensor, using the gyro for short-term calculations and the accelerometer for long-term
calculations. Why is that?

The accelerometer picks up even the smallest forces that are working on the object. If you observe the raw output of an
accelerometer you will notice that even the tiniest disturbance is measured. Because the accelerometer will not drift we
are going to use a low-pass filter on it.

Gyros on the other hand are not susceptible to external forces and can accurately measure angular velocity.
Unfortunately, gyroscopes have a tenancy to drift, making them less accurate over time. For this reason, we are going to
use a high-pass filter.

```math
angle = a * (angle + gyroscopeData * dt) + (1 - a) * accelerometerData
```

Variable a ranges from 95 to 98 percent. You should experiment a bit and choose a suitable percentage for your
application. This filter is also very easy on resources, so it's a true fit for low-powered gateways. The client
application was designed with extensibility in mind, meaning you can define a new file under the actions directory to
handle another type of sensor.

```js
function parseData(imu) {
    const {temperature, accelerometer, gyro} = imu;

    // Get pitch, roll, yaw from gyro
    pitch += (gyro.rate.x / gyroSens) * samplingInterval;
    roll -= (gyro.rate.y / gyroSens) * samplingInterval;
    yaw += (gyro.rate.z / gyroSens) * samplingInterval;

    // Only use accelerometer when forces are ~1g
    if (accelerometer.acceleration > -1 && accelerometer.acceleration < 2) {
        pitch =
            0.98 * pitch +
            0.02 * accelerometer.pitch;

        roll =
            0.98 * roll +
            0.02 * accelerometer.roll;
    }

    // Filter out noise (a small tremor appears with too many fraction digits)
    pitch = toFixed(pitch);
    roll = toFixed(roll);
    yaw = toFixed(yaw);

    return {
        pointName: 'IMU',
        uuid: id,
        temperature: temperature.celsius,
        pitch,
        roll,
        yaw,
        acceleration: imu.accelerometer.acceleration,
        inclination: imu.accelerometer.inclination,
        orientation: imu.accelerometer.orientation,
    }
}
```

I've set the sampling frequency to 10HZ, just enough to get frequent updates on the body position without bogging down
the gateway. Things are pretty straightforward from this point on. The client establishes a socket connection with the
backend and synchronously transfers data.

There is one got ya here. I am using a 6-DOF IMU and that means there is no reference point for the z-axis. Since I am
relying completely on the gyro for the yaw angle, a drift is introduced over time. The orange line in the following
chart depicts the slow but constant drift of the yaw angle. Here is where a magnetometer would come in handy.

![Untitled](/blog/ichnaea/influx-chart.png#center)

There is a lot more going on here. Check out Euler angles (pitch, roll, yaw), accelerometers, gyroscopes, magnetometers.

# Backend

The server for Ichnaea was built on Node.js while making use of many popular packages like celebrate for input
validation. Express was used for the creation of the API. A route definition is as simple as stating the HTTP action
with the desired endpoint and then handling the request accordingly. I am not going to dive into route implementation
details. You can find more in the Express documentation.

Ichnaea was built with consideration for multiple tenants and isolation features. It wouldn't be very smart to stream an
athlete's data to a trainer but his own. Besides offering session capabilities with distinct trainer accounts, an
adoption concept has been introduced to solve this exact problem. An athlete in the orphan state has no trainer and is
open to be adopted. You can then adopt him by entering the unique id (generated in the output of the client device) to
the respective field in the frontend. After adopting the client, the data generated is only streamed to the intended
recipient.

```js
module.exports = (server) => {
    const io = socket(server);
    io.adapter(redisAdapter({host: 'redis', port: 6379}));

    io.on('connection', socket => {
        let client;

        console.log(`Client with id: ${socket.id} just connected  with ${socket.conn.transport.name}!`);

        socket.on('disconnect', () => console.log('Client disconnected!'));

        socket.conn.on('upgrade', () => console.log(`Client with id: ${socket.id} upgraded to ${socket.conn.transport.name}!`));

        socket.on('subscribe', async room => {
            const {subscribe, id} = JSON.parse(room);
            const socketID = socket.id.toString();

            socket.join(room);
            console.log(`Client with id: ${socket.id} joined room "${subscribe}"`);

            try {
                if (subscribe === 'clients') {
                    client = await Athlete.findOne({id}).populate('_trainer');

                    sub.on('message', async (channel, msg) => {
                        if (String(client?._trainer?._id) === JSON.parse(msg))
                            client._trainer = await User.findOne({_id: client._trainer});
                    });

                    sub.subscribe('updateSocketID');

                    if (client) {
                        await Athlete.findOneAndUpdate({id}, {socketID});
                        return;
                    }

                    await saveAthlete(id, socketID);

                } else if (subscribe === 'dashboard') {
                    client = await User.findOne({id});

                    pub.publish('updateSocketID', JSON.stringify(client._id));

                    await User.findOneAndUpdate({id}, {socketID});
                }
            } catch (e) {
                console.log(e);
            }
        });

        socket.on('data', async data => {
            if (client?._trainer) {
                iWrite(data);
                io.volatile.to(client._trainer.socketID).emit('console', data);
            }
        });
    });
}
```

The aforementioned behavior is demonstrated in the code snippet above. One nasty bug that bothered me for a couple of
days was the client device sending data to an old socket id if the dashboard (frontend application) established a socket
connection after the client or if the trainer refreshed the page. That happened because the socket id of the dashboard
was now outdated since a new socket connection was established and a new id was generated. In addition to code being
block scoped in a socket.io event that made it impossible to solve with the libraries built-in functions. Hitting the
database at preset intervals was a big no. Imagine having tens of clients doing the same thing. That quickly brings the
requests to thousands per minute.

Redis pub-sub came to the rescue! By subscribing to the updateSocketID event whenever a client connects and triggering
it when a dashboard (re)connects, excess database reads are avoided. The only thing the subscriber does on that event
trigger is check if his trainer changed id and pick up the new one from the store if so.

The rest of the server is pretty basic. Field validation with celebrate, session and user management with
bcrypt/passport/cookie-session, cors and rate limiter for security reasons, and the list goes on. Check the repo for
more details.

# Databases

Ichnaea utilizes three databases, each for its distinct purpose.

### MongoDB

MongoDB was chosen for the user store. Two models were created, one for the user logging to the dashboard and one to
represent each distinct athlete. Each model has some basic identification features and the all-important socketID. This
field stores the last socket connection id, useful to stream data only to the intended recipient.

![Untitled](/blog/ichnaea/jetbrains-db-diagram.png#center)

Another important field is the _trainer, found only in the athletes model. With that we keep a reference to the trainer
of the athlete, that is the user _id. To retrieve the trainer details at the same time as the athlete's details, we can
use the .populate() function like so.

```js
client = await Athlete.findOne({id}).populate('_trainer');
```

### InfluxDB

A time-series database was a precise fit for the serial data generated from the sensors. Writing data to influx is as
easy as defining a new Point with the data you want to save. InfluxDB comes with a rich dashboard with various data
display capabilities. A Grafana instance is attached to the Influx instance, so you can squeeze out every metric from
Ichnaea.

```js
const imuPoint = new Point(pointName)
    .tag('client', uuid)
    .tag('sensor', 'IMU')
    .floatField('temperature', temperature)
    .floatField('pitch', pitch)
    .floatField('roll', roll)
    .floatField('yaw', yaw)
    .floatField('acceleration', acceleration)
    .floatField('inclination', inclination)
    .floatField('orientation', orientation);

writeApi.writePoint(imuPoint);
```

### Redis

Redis is used as a publish-subscribe mechanism in two places. The first place we make use of pubsub is updating the
socket id dynamically when the dashboard reconnects, as mentioned a couple of sections before. Secondly, it is used as a
socket.io adapter, helping when scaling up with multiple instances of the backend. This way we can broadcast a message
to multiple clients even if they are connected to a different server. You can read more about
that [here](https://socket.io/docs/v4/redis-adapter/).

# Frontend

Last but not least, the Frontend is built on Vue.js, and is a single page application that makes the dashboard of
Ichnaea. Vue is a lovely framework that is extensible with things like routing and state management. I won't go into any
details about the framework - feel free to browse the [docs](https://v3.vuejs.org/).

I tried to make the dashboard as realistic as possible. It has the following features:

- View the latest README from Github right in the app.
- Make changes to the user and athlete profile.
- Adopt or drop athletes.
- View, search, or inspect athletes and their details.
- View athlete data in a table or model in real-time.

Not something overly impressive, but some basic functionality that would form the building blocks of a real-world app.

The main point of the dashboard is the model animation. I fixed a [Mixamo](http://mixamo.com) model to a Three.js scene,
and with the help of [quaternions](https://en.wikipedia.org/wiki/Quaternion), the model animation is a breeze. I used
the build in function from Three.js for the conversion from Euler, setFromEuler(). Taking a look inside setFromEuler(),
we can see that the conversion is simple enough.

```js
const cos = Math.cos;
const sin = Math.sin;

const c1 = cos(x / 2);
const c2 = cos(y / 2);
const c3 = cos(z / 2);

const s1 = sin(x / 2);
const s2 = sin(y / 2);
const s3 = sin(z / 2);

this._x = s1 * c2 * c3 + c1 * s2 * s3;
this._y = c1 * s2 * c3 - s1 * c2 * s3;
this._z = c1 * c2 * s3 + s1 * s2 * c3;
this._w = c1 * c2 * c3 - s1 * s2 * s3;
```

I also keep a reference of body parts, and set its position as so.

```js
this.head = object.getObjectByName('mixamorig1Head');

this.head.quaternion.setFromEuler(new Euler(this.roll, this.yaw, this.pitch));
```

# Demo

Placing the micro-controller on top of the head and making three discreet movements from neutral to left, back, and
upwards right, maps with precision the physical movement and accurately depicts it on the model while testing all three
axes, roll-pitch-yaw.

![Untitled](/blog/ichnaea/testing-01.png#center)

Let's try the same but for another body part, this time the left arm. Starting from a relaxed hanging position we pull
the arm upwards making a slow circular motion and then returning to the starting point. This time due to us deliberately
making a slow movement, we can now see the drift introduced from the gyroscope in the yaw angle. That skews with all the
readings and thus placing the hand in a wrong final position.

![Untitled](/blog/ichnaea/testing-02.png#center)

# Conclusion

This was an overview of Ichnaea, what I thought were the most interesting points, and by no means the full picture. What
needs to be improved? Abstracting the sensor positioning logic to a UI where the user can drag and drop each sensor to
the respective body and not hard-coding it. Making the client device smaller and self-sufficient with a battery and
extensive connectivity options. Lastly, some ML with smart alerts and corrections would provide smart insights.
