# DrinKUp 💧

A Flutter Wear OS app for Samsung Galaxy Watch 6 that helps users stay hydrated throughout the day.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![WearOS](https://img.shields.io/badge/WearOS-Supported-green)
![Android](https://img.shields.io/badge/Android-API%2030%2B-orange)

## 🚀 Features
- Dynamic hydration goal
- Rotary dial input to declare water intake
- Confirmation button to subtract intake from goal
- Lottie animation background for visual engagement

## 🎨 Lottie Background
Uses this animation:  
[View Animation](https://lottie.host/embed/471612cd-a65c-4ef2-ac30-74ea0f66cd82/P9llGuJ6h1.lottie)

## 🛠 Setup

### 1. Configure Gradle
```kotlin
allprojects {
    repositories {
        mavenCentral()
        maven(url = "https://jitpack.io")
    }
}
