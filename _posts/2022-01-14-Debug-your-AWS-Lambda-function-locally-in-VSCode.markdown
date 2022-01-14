---
layout: post
tags: ["AWS", "Lambda"]
title:  "Debug your AWS Lambda function locally in VSCode"
date:   2022-01-14 20:57:28 +0100
categories: AWS
---
***
**TOC**

* TOC
{:toc}

***

We use CI/CD to build, test, and deploy almost every Lambda we made in my work. It's all fine and glorious until you have to spend half time waiting for the pipeline to complete only to find that you forgot to configure some policy or used the wrong layer version. 

As a newbie who does not have much patience, I thought how nice it would be if there's a way to run my Lambda locally? And not surprisingly, there is! A convenient CLI tool `sam local invoke`, that also provides excellent integration to VSCode. 

## Prerequisite
Be sure to follow [AWS official document](https://docs.aws.amazon.com/toolkit-for-vscode/latest/userguide/serverless-apps.html) to install all the required components and set up your environment. 

TL;DR
* Install `AWS Toolkit` extension in your VSCode
* Install `AWS SAM cli` 
* Make sure you have correct credentials setup in your `.aws/config`
* you can use `aws cli` to aid you set up your credentials

## Debugger Configuration
As debugging any local projects in VSCode, all the configurations are done in the `launch.json` file. First, head to you template.yaml file. Then, you can either use the command palette by pressing `command + shift + p` and typing `Open launch.json`, or you can simply click `AWS: Add Debug Configuration` floating above your function's logical Id in Resource section.

{% include image.html url="../assets/images/2022-01-14/add_debug_configuration.png" description="" %}

For all available configurations, please head to the [official document](https://docs.aws.amazon.com/toolkit-for-vscode/latest/userguide/serverless-apps-run-debug-config-ref.html#example-code). Here is an example `launch.json` that covers the most common settings.

```json
{
    "configurations": [
        {
            "type": "aws-sam",
            "request": "direct-invoke",
            "name": "example_function", // to distinguish this config with others
            "invokeTarget": {
                "target": "template",
                "templatePath": "${workspaceFolder}/example_function/template.yaml", // path to your template.yaml
                "logicalId": "ExampleFunction" // the logical Id of your function resource
            },
            "lambda": {
                "runtime": "python3.9", // runtime version
                "payload": {},
                "environmentVariables": {},
                "timeoutSec": 900 // Lambda timeout
            },
            "sam": {
                "localArguments": [ // you can choose to specify any amount of local arguments to SAM
                    "--region",
                    "eu-central-1",
                    "--parameter-overrides",
                    "ExampleParameter=someValue"
                ]
            },
            "aws": {
                "credentials": "profile-to-use", // choose a profile in your config
                "region": "eu-central-1" // default region for the profile
            }
        }
    ]
}
```

Under the hood, `sam local invoke` is triggered, and the VSCode debugger is attached to the container. (If you are interested in how everything works, please head to this [excellent blog pose](https://aws.plainenglish.io/aws-lambda-testing-and-debugging-using-visual-studio-code-aws-sam-and-docker-cbd095c2db74)). You can pass arguments to `sam local invoke` as you would do in cli by adding values in the `localArguments` list. For all supported arguments, see the [official document](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-local-invoke.html).

## Launch the Lambda in VSCode
After doing the configuration, you can go to `Run and Debug` and hit the green play button on the top left. And the rest is the same as debugging a regular python code. You can add breakpoints, step in or step over a statement, etc. However, here I want to point out two things that annoy you.

### Unable to open xxx.py: Unable to read file"
When I first launched the Lambda in VSCode, this error notification kept popping up on the bottom right corner. This is caused by the debugger can not correctly find the modules. 

{% include image.html url="../assets/images/2022-01-14/unable_to_open_file.png" description="" %}

There is a workaround in this issue [https://github.com/aws/aws-sam-cli/issues/3347](https://github.com/aws/aws-sam-cli/issues/3347), which is to downgrade the debugpy to version 1.4.3 by adding `debugpy==1.4.3` to your `requirements.txt`

### SAM local token times out shortly after you launch the Lambda
Even though I have set my Lambda `timeoutSec` to 900 seconds in both the template and the `launch.json`, it kept timeout on me after slightly more than 1 min which is really annoying. Eventually, I find out that this has something to do with the setting of AWS Toolkit.  

{% include image.html url="../assets/images/2022-01-14/toolkit_setting.png" description="" %}

The `Lambda:Timeout` setting defaults to 90000 milliseconds(90s) which is not enough to finish debugging. Change it to a longer value will keep your Lambda alive and give you more time to find the bug. 


You should be able to debug your Lambda without having to wait for the pipeline now. Since this is also quite new to me, I'll keep updating this post if I found something interesting about `sam local`. 
