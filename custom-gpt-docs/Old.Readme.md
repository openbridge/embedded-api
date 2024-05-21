# Openbridge GPT (probably have tom write something here current 4 paragraphs are placeholder from 3rd party site make sure to change.)
At Openbridge, we are convinced that the true productivity of teams can only be unlocked through the flexibility of our product. Thus, we provide our API endpoints in expert mode to ensure maximum flexibility.

In contrast to Openbridge's GPT in standard mode, where you have limited control over the output, in expert mode, you customize your GPT configuration and utilize Openbridge's endpoints for specific actions. You are not just limited to utilize Openbridge for actions; you can also integrate other powerful actions too, such as Zapier.

This enpowers you to transform your GPT into a highly efficient chatbot that

Is equipped with comprehensive background knowledge and context, such as your sales, inventory, and out-of-home advertising data.
Operates based on your custom instructions.
Automates your daily tasks and routines through a variety of actions.
Is shareable among coworkers in your organization or publicly.

## Getting Started

### Step 1: Create a GPT
To create a custom GPT you will need to have a paid OpenAI account which will give you access to create a GPT.

Log into ChatGPT, and in the left menu choose "Explore GPTs".  Then in the right main window in the upper right corner click the "Create" button.

** Screen Shot goes here **

### Step 2: Configure Your GPT
In the left window of the page, click on `Configure`.  Give a name for your GPT and a brief description.

The `Instructions` section will vary based on what the purpose of the GPT is.

We will described 2 use cases.  As a [Helper for Openbridge Account](#helper-for-openbridge-account) and as a [helper for querying data](#helper-for-querying-data). 

** Screen Shot goes here **

## Helper for Openbridge Account
Openbridge uses multiple micro-service APIs for account access, and because of this in order to use a GPT effectively you will need to create multiple actions for each of the different APIs that you want the GPT to interact with.

### Step 3 Create an action for pipeline count.

At the bottom of the configuration page in the lower left you will find the "Create new action" button.  Click on this button to create our new action.  This will create a new action and open a new the Add Actions panel

** Screen Shot goes here **

For the moment ignore the `Authentication` we will come back to that afterwards.  Click on the import button and add the following URL.  This will populate the Schema for the pipeline count API. 

|API | Config URL|
|-|-|
| Pipeline Count API | [api-pipeline-count.yaml](./configurations/api-pipeline-count.yaml) |

### Step 4 Repeat creating an action for other APIs

Now that you created your first action back out back to the configure page and repeat the create action step with the following URLs to configure other APIs.

|API | Config URL|
|-|-|
| Subscription API | [api-subscriptions.yaml](./api-subscriptions.yaml) |
| Remote Identity API | [api-remote-identity.yaml](./configurations/api-remote-identity.yaml) |
| Service API | [api-service-helper-account.yaml](./configurations/api-service-helper-account.yaml) |

Once you have created these proceed to the [Authentication](#authentication)

## Helper for Querying Data
Openbridge uses multiple micro-service APIs to query schema you only need a subsection of the service API.  We have provided a service API config file for just this niche purpose.

### Step 3 Create an action for the Service API

At the bottom of the configuration page in the lower left you will find the "Create new action" button.  Click on this button to create our new action.  This will create a new action and open a new the Add Actions panel

** Screen Shot goes here **

For the moment ignore the `Authentication` we will come back to that afterwards.  Click on the import button and add the following URL.  This will populate the Schema for the pipeline count API. 

|API | Config URL|
|-|-|
| Service API | [api-service-helper-data.yaml](./configurations/api-service-helper-data.yaml) |


## Combined types.
If you want your GPT to both be a Helper for your openbridge account and a helper for querying data, you will have to make all of the actions for the Helper for Openbridge Account but instead of using the configuration file for the Service API from that step you should use this configuration for the Service API.

|API | Config URL|
|-|-|
| Service API | [api-service-combined.yaml](./configurations/api-service-combined.yaml) |


## Authentication
Authentication to the Openbridge APIs for GPT is done through a long lived API token that is valid for 1 year.  You are allowed 1 long lived token at a time and therefore must be used on all GPT actions.

** Screen Shot goes here **

(add instructions for getting token here once we have UI for it.)

Open up your first action and click on the gear wheel in the `Authentication` field and select `API Key`.  Then select `Bearer` as the `Auth Type`.  Paste the long lived token you retrieved above into the API Key field.  Do this for every action you created inside your GPT.

** Screen Shot goes here **


## Giving Instructions to your GPT.

Lastly it is important to give your GPT instructions on how to use the actions.  Things they should do when accessing specific APIs and how to present the data.  We have provided some starter instructions for you, but it is recommended that you build upon them to better instruct your GPT on your specific use cases.


| GPT Type | Instruction Document|
|-|-|
| Helper for Openbridge Account | [instructions-helper-account.md](./instructions/instructions-helper-account.md) |
| Helper for querying data | [instructions-helper-data.md](./instructions/instructions-helper-data.md) |
| Combined | [instructions-combined.md](./instructions/instructions-combined.md) |


## FAQ

FAQ  here...


