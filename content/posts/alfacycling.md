---
title: "A naive approach to blogging"
summary: An early exploration of the web front
date: 2022-03-15
tags: ["Node.js", "Docker", "EJS", "Express.js", "MYSQL"]
author: "Haris Razis"
draft: false
---

# Introduction

Building a blog from the ground up can be quite interesting. It won’t and can’t be a match to a feature-rich blogging
engine, without any substantial effort at least, but it will help you understand topics like REST, CRUD, and many more.
A while ago I created [alfacycling.com](https://github.com/xrazis/alfacycling.com), a primitive blog to get my hands
dirty with new technologies.

# Architecture

The idea behind this project was pretty simple, have a landing page with some info about the team and two sub-routes
with all the blogging and user functions. There is no user support besides a moderator, with some basic capabilities
like creating, editing, or deleting a blog post.

This is a monolithic application design, with a MYSQL database for user authentication and data storage. The project is
built on Node.js with the help of Express for the Backend and EJS for the Frontend. Some cool libraries were used, like
Passport for authenticating users or Puppeteer and Mocha for testing.

# REST Routing

Each route is defined in its file. Take for example the `/blogs` route, where all CRUD operations regarding blogs exist.
Defining a route is simple enough with Express.js.

```js
router.get('/blogs/:id', async (req, res) => {
    res.render('blogs/show', {
        blog: await getOneFromDatabase(req.params.id),
        blog_id: req.params.id
    });
});
```

The GET route in the snippet above returns a single blog entry. Since we are using EJS we have to render each view and
pass in, if any, required parameters.

# Abstracting actions

Since a lot of code is duplicated, for example a database query, it makes sense to abstract that to a separate file and
export it as a module.

```js
module.exports = {
    getOneFromDatabase: async (id) => {
        const sql = 'SELECT * FROM blogs WHERE blogs.id = ?;';

        const foundBlog = await db.query(sql, id);

        return foundBlog;
    },
    // More actions
};
```

The action `getOneFromDatabase` returns a single blog entry that matches a given `id`. A lot cleaner now!

# Authentication

For authentication Passport was used, a middleware that supports various authentication strategies from local to
Facebook and Twitter. Take a look at the local login strategy.

```js
passport.use('login', new LocalStrategy({
    usernameField: 'username',
    passwordField: 'password'
}, async (username, password, done) => {
    const user = await findUser(username);

    bcrypt.compare(password, user[0].password, (err, result) => {
        if (err) throw err;
        if (result) {
            return done(null, user[0]);
        } else {
            const errors = [{value: 'Exists', msg: 'Wrong Password!', param: 'password', location: 'passport'}];
            return done(null, false, errors);
        }
    });
}));
```

A user is retrieved by his username and has the password he provided compared with the one saved in the database. The
comparison is done with the bcrypt library as passwords are not saved in plain text but rather hashed and salted.

# Testing

Testing is an integral part of any application, or to phrase it better, it should be. Since our application requires
signing in and we want each testing session to be clear of any remains, we have to create a user and session factory.

```js
module.exports = async () => {
    const id = crypto.randomBytes(4).toString("hex");

    const sql = 'INSERT INTO users (id) values (?)';

    await db.query(sql, id);

    return id;
}
```

We firstly create a user entry in the database. That is simple enough, we create an entry with just an id - the only
field we are going to need.

```js
module.exports = (id) => {
    const sessionObject = {
        passport: {
            user: id
        }
    };

    const session = buffer.from(JSON.stringify(sessionObject)).toString('base64');
    const sig = keygrip.sign('express:sess=' + session);

    return {session, sig};
};
```

Next, we forge a session by creating two cookies: `express:sess` and `express:sess.sig`. This will trick our server into
thinking we are an authenticated user and thus allowing us to see restricted routes. The cookies name are specific to
the cookie middleware we are using.

# Deployment

Deployment is handled by docker and docker-compose. The dockerfile for alfacycling.com is pretty straightforward. Pull
the specified node image, set the working directory, copy the `package.json` and `package-lock.json` files in the
container, run npm install, expose the server port, and run the application!

```dockerfile
FROM node:14.16.0-alpine3.10

WORKDIR /usr/src/app/alfacycling.com

COPY package*.json ./

RUN npm install

EXPOSE 8080

CMD [ "npm", "run", "dev" ]
```

In `docker-compose.yml`  we define two services: `web` which is the server behind alfacycling.com, and `mysql` a
database instance. This file is pretty explanatory, you can learn more about each key in the docker-compose
documentation. One interesting part is the volumes key, which mounts the specified host directories inside the
container, allowing you to make changes on the fly, without having you rebuild the image.

```yml
services:
  web:
    build: .
    container_name: "alfacycling.com"
    ports:
      - "8080:8080"
    volumes:
      - ./:/usr/src/app/alfacycling.com
      - /usr/src/app/alfacycling.com/node_modules
    depends_on:
      - mysql
  mysql:
    image: mysql
    container_name: "mysql"
    restart: always
    env_file:
      - mysql-variables.env
```

# Conclusion

There is a lot more going on in the repository, I analyzed just a few key points of this project, what I thought might
be more interesting.
