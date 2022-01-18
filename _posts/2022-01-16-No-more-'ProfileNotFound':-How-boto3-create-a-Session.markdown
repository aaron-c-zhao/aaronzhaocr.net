---
layout: post
tags: ["AWS", "Python", "underTheHood"]
title:  "No more 'ProfileNotFound': How boto3 create a Session"
date:   2022-01-16 12:49:51 +0100
categories: Python
---
# WIP
While debugging a simple script, I encountered this `ProfileNotFound` exception thrown by `botocore`. After attempted some unsuccessful solution from StackOverFlow, I decided to learn how `boto3` create a Session under the hood and hoping maybe to pick up some python programming tricks along the way. This post is actually my learning note, so it will be lengthy and self-centred. Just a warning :)

## Introduction

The Session object is the core of `boto3` library. 