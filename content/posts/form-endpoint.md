---
title: "Handling emails for statically generated sites"
summary: Minimal Express.js server to post emails from static sites build with tools like Hugo
date: 2023-09-08
tags: [ "Web", "Frontend", "Backend" ]
draft: false
---

# Introduction

Statically generated sites are fast and flexible but don't have the ability to send _**contact us**_ emails due to the
lack of a backend. A simple solution would be using a service like Airform, Mailgun, or Formspree, but where's the fun
in that? Instead, we can build a simple Express.js API that will handle POST requests from a form and will in turn
forward that email to a mailbox.

# Frontend

First of all make sure you have a working form. Create the fields you need, give a descriptive id to all the
elements, and omit any `action` or `method` attributes.

```html

<form id="contactForm">
    <div class="mb-6">
        <label class="form-label" for="name">
            Όνομα <span class="text-red-500">*</span>
        </label>
        <input
                class="form-input"
                id="name"
                name="name"
                placeholder="Frida Kahlo"
                type="text"/>
    </div>
    ...
</form>
```

Then for the scripting part we are going to set an Event Listener on the form and listen for any submit events. Make
sure to include `mode: "cors"` as we will be filtering request on the server side based on the origin of the request.

```javascript
const endpoint = '{{ site.Params.contact_form_action }}';
const contactForm = document.getElementById('contactForm');

contactForm.addEventListener('submit', event => {
    event.preventDefault();

    const data = new FormData(contactForm);
    data.set('serverEmail', 'info@antamacollective.gr');

    fetch(endpoint, {
        method: "POST",
        mode: "cors",
        body: data,
    }).then(response => {
        if (response.status === 200) {
            document.getElementById('successful-email').classList.remove('hidden');
        } else {
            document.getElementById('failed-email').classList.remove('hidden');
        }
        document.getElementById('submitterButton').setAttribute('disabled', '');
    });
});
```

# Backend

The backend is a simple Node.js server with Express.js. One integral part is CORS, which only allows
specific domains to access the POST path. In sort, [CORS is an HTTP-header based mechanism that allows a server to
indicate any origins other than its own from which a browser should permit loading resources](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS).
This is simply done in Express with the cors middleware. The configuration is simple enough, as seen in the code snippet
bellow, you just have to define the allowed origins. The default configuration is adequate for most cases.

```javascript
const corsOptions = {
    origin: ['https://antamacollective.gr'],
}

app.get('/send-email', cors(corsOptions), (req, res) => {
    res.status(200).send('This route is only visible from CORS allowed origin.');
});
```

The `/send-email` route is responsible for posting the email. There are two middleware, multer which decodes
`multipart/form-data` and cors which was explained in the section above. Within the function the fields are validated
against a Joi schema and then the email is sent with Nodemailer.

```javascript
app.post('/send-email', cors(corsOptions), multer().none(), async (req, res) => {
    try {
        const {name, email, message, serverEmail} = req.body;
        const host = req.hostname;

        //Validate against our schema
        await emailSchema.validateAsync({name, email, message});

        const mail = {
            from: email_user,
            replyTo: email,
            to: serverEmail,
            subject: `Email from ${host} - inquiry from: ${name}`,
            text: message
        };

        transporter.sendMail(mail, (err, info) => {
            if (err) {
                res.sendStatus(500);
                return;
            }

            res.sendStatus(200);
        });
    } catch (err) {
        res.sendStatus(400);
    }
});
```

# Repositories

- https://github.com/xrazis/form-endpoint/
- https://github.com/xrazis/antamacollective.gr