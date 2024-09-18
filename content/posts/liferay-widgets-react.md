---
title: "Liferay widgets and React"
summary: How to build a React Portlet on Liferay 7.2 with widgets
date: 2023-09-25
tags: [ "Web", "Liferay", "Frontend" ]
draft: false
---

# Introduction

At my day job we decided to rewrite a Liferay portlet to React, it displays draws and results data from different
numeric games (the client is a betting company slowly porting many of their games online). This particular portlet has
been a pain in the ass to maintain, port new CRs, and was horrible performance wise, and that is because:

1. The code was inherited from another company and was written a long time ago with questionable structure/logic. There
   was never enough time to do a proper cleanup or rewrite.
2. It tries to handle many different numeric games and in turn the code ends up being incomprehensible and bug prone.
3. It has many expensive DOM operations.

# React Application

Developing the React application standalone and outside of Liferay is a huge boost of productivity as you can take
advantage of features like live reloading and your IDE's debugger. This particular project is based on a monolithic
architecture with no direct communication to the server from the client (ex websockets). It is tightly coupled with
third party vendors and much of the information displayed comes from APIs that other teams use as well (ex mobile
vendor). Some of the API calls happen at the backend at a predefined interval, this way the endpoint does not get
bottled down from requests. That information is exposed to a window variable so that specific context can be
accessible from different parts of the application.

The majority of data displayed in the portlet are fed in from the aforementioned window variable. On some user actions
an endpoint is queried and the data displayed is updated. That is done with a `useState` hook that lets us add state to
our components. The `useState` hook is particularly useful as React takes care of what to update in the UI - you only
have to declaratively program the UI. You should definitely have a look at the
[docs](https://react.dev/reference/react/useState) as state management can get tricky without the right knowledge.

```jsx
// Declare the data state
const [data, setData] = useState(window.contextContributor);

const fetchData = (drawId) => {
    fetch(`${apiEndpoint}/draws/v3.0/5104/${drawId}`)
        .then(response => response.json())
        .then(data => {
            // Update the state with the new data. React will take care of updating the UI
            setData(data);
        })
        .catch((error) => console.debug(`[DRAWS && RESULTS DRAWS ERROR]: ${error}`));
};

// ...

// Display some repeative nested field of data using Array.prototype.map()
<div className='balls-row'>
    {data.winningNumbers.list.sort().map(number => {
        return (<GameBall ballColor='blue-ball'
                          number={number}
                          key={number}
        />);
    })}
</div>

// Add the click listener 
<button className='btn draw-btn-left'
        onClick={() => handleDrawClick(data.drawId - 1)}>
</button>
```

Another helpful hook is `useEffect` which is used to synchronize the component with an external system. In our
particular case we are going to use it to populate a html select with data from an API. This select displays the draw
id's for a given month. The same action is also triggered when the user selects a different month.

![img.webp](/blog/20230929-01.webp)

When a month is changed three actions need to take place:

1. Find the month in calendar format (1-12) using the monthTuple (see i18next down bellow for month tuple) and
   `Array.prototype.findIndex()`. For example, given September the variable `monthInDateFormat` is going to be 9.
2. Set the new month in state.
3. Correctly format the date for the endpoint, then fetch the new draw id's and update the respective state.

```jsx
const fetchDraws = (monthInDateFormat) => {
    const formattedMonth = monthInDateFormat >= 10 ? monthInDateFormat : `0${monthInDateFormat}`;
    const daysInMonth = new Date(year, monthInDateFormat, 0).getDate();

    fetch(`${apiEndpoint}/draws/v3.0/5104/draw-date/${year}-${formattedMonth}-01/${year}-${formattedMonth}-${daysInMonth}/draw-id`)
        .then(response => response.json())
        .then(data => setDraws(data))
        .catch((error) => console.debug(`[DRAWS && RESULTS DRAW DATE ERROR]: ${error}`));
};

const changeMonth = (newMonth) => {
    const monthInDateFormat = monthTuple.findIndex(e => e === newMonth) + 1;
    setMonth(newMonth);

    // New draws need to be fetched every time the month changes
    fetchDraws(monthInDateFormat);
};

useEffect(() => {
    changeMonth(monthTuple[thisMonth]);
}, []);
```

By passing an empty dependency array to the `useEffect` hook we are telling React that it uses no reactive values,
and it can be run after the initial render. This way we won't wait on an API call for a UI element that is not critical
to appear on render time.

As far as localization goes I've chosen to use [react-i18next](https://react.i18next.com/) for two reasons. Firstly I
was already familiar with i18next from some personal projects, and secondly I didn't want to be depended on Liferay's
inbuilt localization features because I was developing it as a standalone application. Setting it up is a breeze - I
decided to install the base package and the browser-languagedetector. The configuration lives in a standalone file, as
do the translations.

```jsx
import i18n from 'i18next';
import {initReactI18next} from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

import el from './locales/el/translation.json'
import en from './locales/en/translation.json'

i18n
    .use(LanguageDetector)
    .use(initReactI18next)
    .init({
        fallbackLng: 'el',
        resources: {
            el: {common: el},
            en: {common: en}
        },
        detection: {
            order: ['htmlTag'],
            convertDetectedLanguage: (lng) => lng === 'el-GR' ? 'el' : 'en'
        }
    });

export default i18n;
```

It is now ready to be imported to your application, just remember to use the correct namespace like so:

```jsx
const {t} = useTranslation('common');
// ...
<h2 className='title'>{t('title')}</h2>
```

One neat option you can pass to the translation component is `returnObjects`, which returns an object. This way we can
localize things like dates and avoid using a third party plugin like moment.js. We can take advantage of the javascript
Date object and grab the date we want.

```json
{
  "monthTuple": {
    "0": "January",
    "1": "February",
    "2": "March",
    "3": "April",
    "4": "May",
    "5": "June",
    "6": "July",
    "7": "August",
    "8": "September",
    "9": "October",
    "10": "November",
    "11": "December"
  }
}
```

```jsx
const date = new Date();
const thisMonth = date.getMonth();
const monthTuple = Object.values(t('monthTuple', {returnObjects: true}));
const [month, setMonth] = useState(monthTuple[thisMonth]);
```

# Porting to Liferay

There are two ways to create a React widget:

- Use Blade to create a liferay-js module.
- Use Yeoman generator to create or adapt an existing React application.

I found that creating a standalone React application with `npx create-react-app` and then porting it with `yeoman`
proved useful, as I developed the module much faster outside of Liferay and only made some finishing touches once
ported.

Deploying was definitely not a breeze. We use Jenkins to build and deploy to a remote server but the module would fail
and thus ruin the whole pipeline. I found no quick solution to that, so I resulted to rename the build scripts (so
they wouldn't get picked up by Gradle), build the module locally, and then deploy it to the remote server.

# Conclusion

This was the first React application and Liferay widget I had to develop. Despite some early hiccups, especially when
trying to figure out how the Liferay widget works, I do believe that developer experience is boosted, performance is
improved, and maintenance is made easier - in sort **React 💕**.

# Sources

Big props to my [senior](https://github.com/0xAnakin) for guiding me because I would have probably ended up in an asylum
trying to figure out the Liferay toolkit.

- https://github.com/0xAnakin/liferay-react-demo
- https://github.com/0xAnakin/Liferay74u46-react-demo
- https://help.liferay.com/hc/en-us/articles/360029028051-Developing-a-React-Application
- https://liferay.dev/en/blogs/-/blogs/liferay-react-portlets
- https://help.liferay.com/hc/en-us/articles/360028832872-Understanding-the-npmbundlerrc-s-Structure
- https://help.liferay.com/hc/en-us/articles/360028832892-How-the-Default-Preset-Configures-the-liferay-npm-bundler
