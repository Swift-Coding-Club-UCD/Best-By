# Best-By

<div align="center">
  <img src="https://github.com/aktanazat/Best-By/raw/main/fridge/fridge/Assets.xcassets/AppIcon.appiconset/AppIcon.png" alt="Best-By Logo" width="200"/>
  <p><i>Smart Food Management & Recipe Suggestions</i></p>
</div>

## Overview

Best-By is an innovative iOS app designed to streamline food management, reduce waste, and enhance your cooking experience. By intelligently tracking the expiration dates of your food items and suggesting personalized recipes based on what you have, Best-By helps you make the most of your grocery shopping while minimizing waste.

### The Problem We're Solving

In the United States, 30-40% of food supply is wasted, with a significant portion due to mismanagement of shelf life and expiration dates ([source](https://shapiroe.com/blog/expiration-dates-and-food-waste/)). While food manufacturers label products with estimated "best by" dates, many consumers forget to check them or don't monitor their food inventory effectively.

Best-By tackles this issue by:
- **Tracking** each product's freshness
- Sending **timely reminders** before food expires
- **Suggesting recipes** so items can be used before they spoil

By helping users stay organized and informed, we're reducing waste, saving money, and promoting a more sustainable approach to everyday eating.

## Features

- **Smart Inventory Tracking**: Easily manage your food items with expiration date monitoring
- **Personalized Recipe Suggestions**: Discover recipes based on ingredients you already have
- **Dietary Preference Filters**: Customize recipe suggestions based on your dietary needs and preferences
- **Recipe Collections**: Organize favorite recipes into custom folders for easy access
- **Shopping List**: Automatically generate shopping lists from recipe ingredients
- **Profile Customization**: Set allergy information, cooking preferences, and more
- **Meal Planning**: Schedule meals for the week with suggested recipes

## Technical Details

- **Smart Inventory Tracking**: Easily manage your food items with expiration date monitoring
- **Personalized Recipe Suggestions**: Discover recipes based on ingredients you already have
- **Dietary Preference Filters**: Customize recipe suggestions based on your dietary needs and preferences
- **Recipe Collections**: Organize favorite recipes into custom folders for easy access
- **Shopping List**: Automatically generate shopping lists from recipe ingredients
- **Profile Customization**: Set allergy information, cooking preferences, and more
- **Meal Planning**: Schedule meals for the week with suggested recipes


### Technologies Used

- **Swift & SwiftUI**: Modern UI development with declarative syntax
- **Spoonacular API**: Recipe discovery and ingredient analysis
- **MVVM Architecture**: Clear separation of concerns for maintainability
- **Async/Await & Combine**: Efficient asynchronous programming
- **Core Data**: Local data persistence
- **Local Notifications**: Expiration date reminders

### Architecture

Best-By follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: Represent data structures like `FridgeItem`, `Recipe`, `UserProfile`
- **Views**: SwiftUI views for presenting the user interface
- **ViewModels**: `FridgeViewModel` manages application logic and state

## Core Features

### Inventory Management

- Add food items with categories, quantities, and expiration dates
- Visual indicators for food freshness status
- Sort and filter options for better organization
- Expiration notifications to reduce food waste

### Recipe Discovery

- Automated recipe suggestions based on available ingredients
- Recipe filtering by cooking time, difficulty, and dietary preferences
- Detailed instructions and ingredient lists
- Option to add missing ingredients to shopping list

### User Profiles

- Customizable user profiles with preferences
- Allergy and dietary restriction tracking
- Recipe complexity and cooking time preferences
- Favorite recipe management with folder organization

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/aktanazat/Best-By.git
   ```

2. Open the project in Xcode:
   ```bash
   cd Best-By
   open fridge/fridge.xcodeproj
   ```

3. Set up your Spoonacular API key:
   - Get an API key from [Spoonacular](https://spoonacular.com/food-api)
   - Replace the API key in `RecipeService.swift`

4. Build and run the app on your simulator or device

## Usage

1. **Initial Setup**: Create your profile and add any dietary preferences or allergies
2. **Add Food Items**: Add items to your inventory with their expiration dates
3. **Generate Recipes**: Browse recipe suggestions based on your available ingredients
4. **Create Shopping Lists**: Add missing ingredients to your shopping list
5. **Save Favorites**: Save and organize your favorite recipes into custom folders

## Customization

Best-By offers extensive customization options:

- **Theme Selection**: Choose between light, dark, or system theme
- **Accent Colors**: Personalize the app with your preferred accent color
- **Measurement System**: Toggle between metric and imperial units
- **Notification Settings**: Customize when you receive expiration alerts

## Contributing

We welcome contributions to Best-By! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Spoonacular API](https://spoonacular.com/food-api) for recipe data
- Icons from [SF Symbols](https://developer.apple.com/sf-symbols/)
- All contributors and testers who helped shape this app

## Team

- Aliyah Azizi
- Aktan Azat
- Amber Gonzalez
- Emily Nguyen

---

<div align="center">
  <p>Made with ❤️ by the Best-By Team</p>
</div>
