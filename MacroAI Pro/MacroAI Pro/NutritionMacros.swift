// NutritionMacros.swift
// Core nutrition data structure used throughout the app

import Foundation

struct NutritionMacros {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    
    init(calories: Double, protein: Double, carbs: Double, fat: Double) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
} 