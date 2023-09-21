---
title: "Building Liferay widgets with React"
summary: How to build a React portlet on Liferay 7.2 with widgets
date: 2023-09-16
tags: [ "React", "Node.js", "Liferay" ]
draft: true
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

# Porting to Liferay

### Configuration.json

### Build and Deploy

# Sources

Big props to my senior for guiding me because I would have probably ended up in an asylum trying to figure out the
Liferay toolkit.

- https://github.com/0xAnakin/liferay-react-demo
- https://github.com/0xAnakin/Liferay74u46-react-demo
- https://help.liferay.com/hc/en-us/articles/360029028051-Developing-a-React-Application
- https://liferay.dev/en/blogs/-/blogs/liferay-react-portlets
- https://help.liferay.com/hc/en-us/articles/360028832872-Understanding-the-npmbundlerrc-s-Structure
- https://help.liferay.com/hc/en-us/articles/360028832892-How-the-Default-Preset-Configures-the-liferay-npm-bundler
