# Best By
by: Aliyah Azizi, Aktan Azat, Amber Gonzalez, Emily Nguyen
## Problem Statement:
- In the United States, 30-40% of food supply is wasted, and a huge part of this number can be contributed to shelf life and expiration dates ([source](https://shapiroe.com/blog/expiration-dates-and-food-waste/)).
- Currently, the only solutions food manufacturers have to prevent food waste from happening is by labeling products with an estimated "best by" or "expiration" date. However, many people forget expiration dates or simply do not check them at all. They go to eat food and see it has spoiled. This causes problems for users because they waste their money on food that remains uneaten. 
- The goal of our app is to **limit food waste** and provide **healthy recipes**.
  - Our app tackles this issue by **tracking** each **product’s freshness**, sending **timely reminders**, and **suggesting recipes** so items can be used before they spoil. By helping our users stay organized and informed, we’re reducing waste, saving money, and promoting a more sustainable approach to everyday eating.

## Technical Stack
- We are currently developing for the following platforms: **iOS** and **iPadOS**
- Programming language(s): **Swift**
- Third-party libraries and Apple frameworks:
  - **SceneKit**: In order to create a 3D interactive "map" of the user's fridge
  - **AVFoundation**: For product scanning, we require access to the user's camera
  - **Some API**: For fetching recipes from the internet
  - **CloudKit**: In order to store user data and allow it to sync across devices in the Apple ecosystem
