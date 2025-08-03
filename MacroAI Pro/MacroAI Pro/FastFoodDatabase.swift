import Foundation

// MARK: - Fast Food Database
struct FastFoodItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let brand: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let servingSize: String
    let category: FastFoodCategory
    let keywords: [String] // For matching user input
    let imageKeywords: [String] // For visual recognition
}

enum FastFoodCategory: String, Codable, CaseIterable {
    case burger = "Burger"
    case chicken = "Chicken"
    case taco = "Taco"
    case pizza = "Pizza"
    case sandwich = "Sandwich"
    case salad = "Salad"
    case side = "Side"
    case drink = "Drink"
    case dessert = "Dessert"
    case breakfast = "Breakfast"
    
    var icon: String {
        switch self {
        case .burger: return "🍔"
        case .chicken: return "🍗"
        case .taco: return "🌮"
        case .pizza: return "🍕"
        case .sandwich: return "🥪"
        case .salad: return "🥗"
        case .side: return "🍟"
        case .drink: return "🥤"
        case .dessert: return "🍦"
        case .breakfast: return "🥞"
        }
    }
}

class FastFoodDatabase {
    static let shared = FastFoodDatabase()
    
    var fastFoodItems: [FastFoodItem] = []
    
    private init() {
        loadFastFoodData()
    }
    
    // MARK: - Fast Food Data
    
    private func loadFastFoodData() {
                    fastFoodItems = [
                // McDonald's
                FastFoodItem(id: UUID(), name: "Big Mac", brand: "McDonald's", calories: 550, protein: 25, carbs: 45, fat: 30, servingSize: "1 burger", category: .burger, keywords: ["big mac", "mcdonalds burger", "mcd burger"], imageKeywords: ["big mac", "mcdonalds", "burger", "double patty"]),
            FastFoodItem(id: UUID(), name: "Quarter Pounder", brand: "McDonald's", calories: 520, protein: 30, carbs: 42, fat: 26, servingSize: "1 burger", category: .burger, keywords: ["quarter pounder", "mcdonalds burger"], imageKeywords: ["quarter pounder", "mcdonalds", "burger"]),
            FastFoodItem(id: UUID(), name: "McChicken", brand: "McDonald's", calories: 400, protein: 16, carbs: 39, fat: 21, servingSize: "1 sandwich", category: .sandwich, keywords: ["mcchicken", "chicken sandwich"], imageKeywords: ["mcchicken", "chicken sandwich", "mcdonalds"]),
            FastFoodItem(id: UUID(), name: "McNuggets (6 piece)", brand: "McDonald's", calories: 250, protein: 12, carbs: 15, fat: 15, servingSize: "6 pieces", category: .chicken, keywords: ["mcnuggets", "chicken nuggets", "nuggets"], imageKeywords: ["mcnuggets", "chicken nuggets", "nuggets"]),
            FastFoodItem(id: UUID(), name: "McNuggets (10 piece)", brand: "McDonald's", calories: 420, protein: 20, carbs: 25, fat: 25, servingSize: "10 pieces", category: .chicken, keywords: ["mcnuggets 10", "chicken nuggets 10"], imageKeywords: ["mcnuggets", "chicken nuggets", "nuggets"]),
            FastFoodItem(id: UUID(), name: "French Fries (Medium)", brand: "McDonald's", calories: 340, protein: 4, carbs: 44, fat: 16, servingSize: "1 medium", category: .side, keywords: ["french fries", "fries", "mcdonalds fries"], imageKeywords: ["french fries", "fries", "potato"]),
            FastFoodItem(id: UUID(), name: "French Fries (Large)", brand: "McDonald's", calories: 490, protein: 6, carbs: 63, fat: 23, servingSize: "1 large", category: .side, keywords: ["french fries large", "fries large"], imageKeywords: ["french fries", "fries", "potato"]),
            FastFoodItem(id: UUID(), name: "Filet-O-Fish", brand: "McDonald's", calories: 390, protein: 15, carbs: 38, fat: 19, servingSize: "1 sandwich", category: .sandwich, keywords: ["filet o fish", "fish sandwich"], imageKeywords: ["filet o fish", "fish sandwich", "mcdonalds"]),
            FastFoodItem(id: UUID(), name: "McDouble", brand: "McDonald's", calories: 400, protein: 22, carbs: 33, fat: 20, servingSize: "1 burger", category: .burger, keywords: ["mcdouble", "double burger"], imageKeywords: ["mcdouble", "double burger", "mcdonalds"]),
            
            // Del Taco
            FastFoodItem(id: UUID(), name: "Del Taco (Beef)", brand: "Del Taco", calories: 320, protein: 12, carbs: 36, fat: 16, servingSize: "1 taco", category: .taco, keywords: ["del taco", "beef taco", "taco"], imageKeywords: ["del taco", "taco", "beef taco"]),
            FastFoodItem(id: UUID(), name: "Del Taco (Chicken)", brand: "Del Taco", calories: 280, protein: 14, carbs: 36, fat: 12, servingSize: "1 taco", category: .taco, keywords: ["del taco chicken", "chicken taco"], imageKeywords: ["del taco", "chicken taco", "taco"]),
            FastFoodItem(id: UUID(), name: "Del Combo Burrito", brand: "Del Taco", calories: 580, protein: 22, carbs: 68, fat: 24, servingSize: "1 burrito", category: .taco, keywords: ["del combo burrito", "burrito"], imageKeywords: ["burrito", "del taco", "combo"]),
            FastFoodItem(id: UUID(), name: "Green Burrito", brand: "Del Taco", calories: 520, protein: 18, carbs: 62, fat: 20, servingSize: "1 burrito", category: .taco, keywords: ["green burrito", "del taco green burrito"], imageKeywords: ["green burrito", "burrito", "del taco"]),
            FastFoodItem(id: UUID(), name: "Red Burrito", brand: "Del Taco", calories: 540, protein: 20, carbs: 64, fat: 22, servingSize: "1 burrito", category: .taco, keywords: ["red burrito", "del taco red burrito"], imageKeywords: ["red burrito", "burrito", "del taco"]),
            FastFoodItem(id: UUID(), name: "Crunchtada", brand: "Del Taco", calories: 420, protein: 16, carbs: 42, fat: 22, servingSize: "1 item", category: .taco, keywords: ["crunchtada", "del taco"], imageKeywords: ["crunchtada", "taco", "del taco"]),
            FastFoodItem(id: UUID(), name: "Deluxe Combo Burrito", brand: "Del Taco", calories: 620, protein: 24, carbs: 72, fat: 26, servingSize: "1 burrito", category: .taco, keywords: ["deluxe combo burrito", "deluxe burrito"], imageKeywords: ["deluxe burrito", "burrito", "del taco"]),
            FastFoodItem(id: UUID(), name: "Epic Burrito", brand: "Del Taco", calories: 680, protein: 26, carbs: 76, fat: 28, servingSize: "1 burrito", category: .taco, keywords: ["epic burrito", "del taco epic"], imageKeywords: ["epic burrito", "burrito", "del taco"]),
            FastFoodItem(id: UUID(), name: "Chicken Quesadilla", brand: "Del Taco", calories: 380, protein: 20, carbs: 28, fat: 18, servingSize: "1 quesadilla", category: .taco, keywords: ["chicken quesadilla", "quesadilla"], imageKeywords: ["quesadilla", "del taco"]),
            FastFoodItem(id: UUID(), name: "Steak Quesadilla", brand: "Del Taco", calories: 420, protein: 22, carbs: 30, fat: 20, servingSize: "1 quesadilla", category: .taco, keywords: ["steak quesadilla", "quesadilla"], imageKeywords: ["quesadilla", "del taco"]),
            
            // Taco Bell
            FastFoodItem(id: UUID(), name: "Crunchy Taco", brand: "Taco Bell", calories: 170, protein: 8, carbs: 13, fat: 10, servingSize: "1 taco", category: .taco, keywords: ["crunchy taco", "taco bell", "taco"], imageKeywords: ["crunchy taco", "taco bell", "taco"]),
            FastFoodItem(id: UUID(), name: "Soft Taco", brand: "Taco Bell", calories: 180, protein: 9, carbs: 16, fat: 9, servingSize: "1 taco", category: .taco, keywords: ["soft taco", "taco bell", "taco"], imageKeywords: ["soft taco", "taco bell", "taco"]),
            FastFoodItem(id: UUID(), name: "Bean Burrito", brand: "Taco Bell", calories: 380, protein: 12, carbs: 54, fat: 14, servingSize: "1 burrito", category: .taco, keywords: ["bean burrito", "taco bell", "burrito"], imageKeywords: ["bean burrito", "taco bell", "burrito"]),
            FastFoodItem(id: UUID(), name: "Beef Burrito", brand: "Taco Bell", calories: 420, protein: 16, carbs: 56, fat: 16, servingSize: "1 burrito", category: .taco, keywords: ["beef burrito", "taco bell", "burrito"], imageKeywords: ["beef burrito", "taco bell", "burrito"]),
            FastFoodItem(id: UUID(), name: "Chicken Burrito", brand: "Taco Bell", calories: 400, protein: 18, carbs: 54, fat: 14, servingSize: "1 burrito", category: .taco, keywords: ["chicken burrito", "taco bell", "burrito"], imageKeywords: ["chicken burrito", "taco bell", "burrito"]),
            FastFoodItem(id: UUID(), name: "Crunchwrap Supreme", brand: "Taco Bell", calories: 540, protein: 18, carbs: 48, fat: 28, servingSize: "1 item", category: .taco, keywords: ["crunchwrap supreme", "crunchwrap"], imageKeywords: ["crunchwrap", "taco bell"]),
            FastFoodItem(id: UUID(), name: "Chalupa Supreme", brand: "Taco Bell", calories: 350, protein: 12, carbs: 28, fat: 20, servingSize: "1 item", category: .taco, keywords: ["chalupa supreme", "chalupa"], imageKeywords: ["chalupa", "taco bell"]),
            FastFoodItem(id: UUID(), name: "Gordita Supreme", brand: "Taco Bell", calories: 320, protein: 10, carbs: 26, fat: 18, servingSize: "1 item", category: .taco, keywords: ["gordita supreme", "gordita"], imageKeywords: ["gordita", "taco bell"]),
            FastFoodItem(id: UUID(), name: "Nachos BellGrande", brand: "Taco Bell", calories: 740, protein: 16, carbs: 72, fat: 42, servingSize: "1 order", category: .side, keywords: ["nachos bellgrande", "nachos"], imageKeywords: ["nachos", "taco bell"]),
            
            // Burger King
            FastFoodItem(id: UUID(), name: "Whopper", brand: "Burger King", calories: 660, protein: 28, carbs: 49, fat: 40, servingSize: "1 burger", category: .burger, keywords: ["whopper", "burger king", "bk burger"], imageKeywords: ["whopper", "burger king", "burger"]),
            FastFoodItem(id: UUID(), name: "Whopper Jr.", brand: "Burger King", calories: 340, protein: 14, carbs: 28, fat: 18, servingSize: "1 burger", category: .burger, keywords: ["whopper jr", "whopper junior"], imageKeywords: ["whopper jr", "burger king", "burger"]),
            FastFoodItem(id: UUID(), name: "Chicken Royale", brand: "Burger King", calories: 360, protein: 16, carbs: 35, fat: 18, servingSize: "1 sandwich", category: .sandwich, keywords: ["chicken royale", "burger king chicken"], imageKeywords: ["chicken royale", "burger king", "chicken sandwich"]),
            FastFoodItem(id: UUID(), name: "Bacon King", brand: "Burger King", calories: 1150, protein: 48, carbs: 52, fat: 82, servingSize: "1 burger", category: .burger, keywords: ["bacon king", "burger king"], imageKeywords: ["bacon king", "burger king", "burger"]),
            FastFoodItem(id: UUID(), name: "Double Whopper", brand: "Burger King", calories: 900, protein: 48, carbs: 52, fat: 58, servingSize: "1 burger", category: .burger, keywords: ["double whopper", "burger king"], imageKeywords: ["double whopper", "burger king", "burger"]),
            FastFoodItem(id: UUID(), name: "Chicken Fries", brand: "Burger King", calories: 280, protein: 12, carbs: 24, fat: 16, servingSize: "1 order", category: .chicken, keywords: ["chicken fries", "burger king"], imageKeywords: ["chicken fries", "burger king"]),
            
            // Wendy's
            FastFoodItem(id: UUID(), name: "Dave's Single", brand: "Wendy's", calories: 590, protein: 29, carbs: 39, fat: 34, servingSize: "1 burger", category: .burger, keywords: ["dave's single", "wendy's", "burger"], imageKeywords: ["dave's single", "wendy's", "burger"]),
            FastFoodItem(id: UUID(), name: "Dave's Double", brand: "Wendy's", calories: 870, protein: 48, carbs: 39, fat: 58, servingSize: "1 burger", category: .burger, keywords: ["dave's double", "wendy's", "burger"], imageKeywords: ["dave's double", "wendy's", "burger"]),
            FastFoodItem(id: UUID(), name: "Spicy Chicken Sandwich", brand: "Wendy's", calories: 450, protein: 23, carbs: 44, fat: 20, servingSize: "1 sandwich", category: .sandwich, keywords: ["spicy chicken", "wendy's", "chicken sandwich"], imageKeywords: ["spicy chicken", "wendy's", "chicken sandwich"]),
            FastFoodItem(id: UUID(), name: "Classic Chicken Sandwich", brand: "Wendy's", calories: 420, protein: 22, carbs: 42, fat: 18, servingSize: "1 sandwich", category: .sandwich, keywords: ["classic chicken", "wendy's", "chicken sandwich"], imageKeywords: ["classic chicken", "wendy's", "chicken sandwich"]),
            FastFoodItem(id: UUID(), name: "Baconator", brand: "Wendy's", calories: 950, protein: 39, carbs: 47, fat: 67, servingSize: "1 burger", category: .burger, keywords: ["baconator", "wendy's", "burger"], imageKeywords: ["baconator", "wendy's", "burger"]),
            
            // Subway
            FastFoodItem(id: UUID(), name: "6\" Turkey Breast", brand: "Subway", calories: 280, protein: 18, carbs: 46, fat: 4, servingSize: "1 sandwich", category: .sandwich, keywords: ["turkey breast", "subway", "sandwich"], imageKeywords: ["turkey sandwich", "subway", "sandwich"]),
            FastFoodItem(id: UUID(), name: "6\" Chicken Teriyaki", brand: "Subway", calories: 350, protein: 26, carbs: 47, fat: 6, servingSize: "1 sandwich", category: .sandwich, keywords: ["chicken teriyaki", "subway", "sandwich"], imageKeywords: ["chicken teriyaki", "subway", "sandwich"]),
            FastFoodItem(id: UUID(), name: "6\" Italian BMT", brand: "Subway", calories: 410, protein: 24, carbs: 47, fat: 16, servingSize: "1 sandwich", category: .sandwich, keywords: ["italian bmt", "subway", "sandwich"], imageKeywords: ["italian bmt", "subway", "sandwich"]),
            FastFoodItem(id: UUID(), name: "6\" Meatball Marinara", brand: "Subway", calories: 480, protein: 20, carbs: 58, fat: 18, servingSize: "1 sandwich", category: .sandwich, keywords: ["meatball marinara", "subway", "sandwich"], imageKeywords: ["meatball marinara", "subway", "sandwich"]),
            FastFoodItem(id: UUID(), name: "6\" Tuna", brand: "Subway", calories: 430, protein: 20, carbs: 47, fat: 20, servingSize: "1 sandwich", category: .sandwich, keywords: ["tuna", "subway", "sandwich"], imageKeywords: ["tuna", "subway", "sandwich"]),
            FastFoodItem(id: UUID(), name: "12\" Turkey Breast", brand: "Subway", calories: 560, protein: 36, carbs: 92, fat: 7, servingSize: "1 sandwich", category: .sandwich, keywords: ["turkey breast footlong", "subway", "sandwich"], imageKeywords: ["turkey sandwich", "subway", "sandwich"]),
            
            // KFC
            FastFoodItem(id: UUID(), name: "Original Recipe Chicken (2 pieces)", brand: "KFC", calories: 440, protein: 44, carbs: 11, fat: 24, servingSize: "2 pieces", category: .chicken, keywords: ["original recipe", "kfc", "fried chicken"], imageKeywords: ["kfc", "fried chicken", "original recipe"]),
            FastFoodItem(id: UUID(), name: "Extra Crispy Chicken (2 pieces)", brand: "KFC", calories: 460, protein: 42, carbs: 12, fat: 26, servingSize: "2 pieces", category: .chicken, keywords: ["extra crispy", "kfc", "fried chicken"], imageKeywords: ["kfc", "fried chicken", "extra crispy"]),
            FastFoodItem(id: UUID(), name: "Chicken Tenders (3 pieces)", brand: "KFC", calories: 320, protein: 28, carbs: 18, fat: 16, servingSize: "3 pieces", category: .chicken, keywords: ["chicken tenders", "kfc", "tenders"], imageKeywords: ["chicken tenders", "kfc", "tenders"]),
            FastFoodItem(id: UUID(), name: "Popcorn Chicken", brand: "KFC", calories: 280, protein: 16, carbs: 20, fat: 16, servingSize: "1 order", category: .chicken, keywords: ["popcorn chicken", "kfc"], imageKeywords: ["popcorn chicken", "kfc"]),
            FastFoodItem(id: UUID(), name: "Mashed Potatoes", brand: "KFC", calories: 120, protein: 3, carbs: 21, fat: 3, servingSize: "1 side", category: .side, keywords: ["mashed potatoes", "kfc"], imageKeywords: ["mashed potatoes", "kfc"]),
            
            // Pizza Hut
            FastFoodItem(id: UUID(), name: "Pepperoni Pizza (1 slice)", brand: "Pizza Hut", calories: 290, protein: 12, carbs: 30, fat: 14, servingSize: "1 slice", category: .pizza, keywords: ["pepperoni pizza", "pizza hut", "pizza"], imageKeywords: ["pepperoni pizza", "pizza hut", "pizza"]),
            FastFoodItem(id: UUID(), name: "Cheese Pizza (1 slice)", brand: "Pizza Hut", calories: 250, protein: 10, carbs: 30, fat: 10, servingSize: "1 slice", category: .pizza, keywords: ["cheese pizza", "pizza hut", "pizza"], imageKeywords: ["cheese pizza", "pizza hut", "pizza"]),
            FastFoodItem(id: UUID(), name: "Supreme Pizza (1 slice)", brand: "Pizza Hut", calories: 320, protein: 14, carbs: 32, fat: 16, servingSize: "1 slice", category: .pizza, keywords: ["supreme pizza", "pizza hut", "pizza"], imageKeywords: ["supreme pizza", "pizza hut", "pizza"]),
            FastFoodItem(id: UUID(), name: "Meat Lover's Pizza (1 slice)", brand: "Pizza Hut", calories: 350, protein: 16, carbs: 30, fat: 18, servingSize: "1 slice", category: .pizza, keywords: ["meat lovers pizza", "pizza hut", "pizza"], imageKeywords: ["meat lovers pizza", "pizza hut", "pizza"]),
            
            // Domino's
            FastFoodItem(id: UUID(), name: "Pepperoni Pizza (1 slice)", brand: "Domino's", calories: 280, protein: 11, carbs: 32, fat: 12, servingSize: "1 slice", category: .pizza, keywords: ["pepperoni pizza", "dominos", "pizza"], imageKeywords: ["pepperoni pizza", "dominos", "pizza"]),
            FastFoodItem(id: UUID(), name: "Cheese Pizza (1 slice)", brand: "Domino's", calories: 240, protein: 9, carbs: 32, fat: 8, servingSize: "1 slice", category: .pizza, keywords: ["cheese pizza", "dominos", "pizza"], imageKeywords: ["cheese pizza", "dominos", "pizza"]),
            FastFoodItem(id: UUID(), name: "Supreme Pizza (1 slice)", brand: "Domino's", calories: 310, protein: 13, carbs: 34, fat: 14, servingSize: "1 slice", category: .pizza, keywords: ["supreme pizza", "dominos", "pizza"], imageKeywords: ["supreme pizza", "dominos", "pizza"]),
            
            // Chipotle
            FastFoodItem(id: UUID(), name: "Chicken Burrito Bowl", brand: "Chipotle", calories: 705, protein: 40, carbs: 71, fat: 28, servingSize: "1 bowl", category: .taco, keywords: ["chicken burrito bowl", "chipotle", "burrito bowl"], imageKeywords: ["burrito bowl", "chipotle"]),
            FastFoodItem(id: UUID(), name: "Steak Burrito Bowl", brand: "Chipotle", calories: 745, protein: 42, carbs: 71, fat: 32, servingSize: "1 bowl", category: .taco, keywords: ["steak burrito bowl", "chipotle", "burrito bowl"], imageKeywords: ["burrito bowl", "chipotle"]),
            FastFoodItem(id: UUID(), name: "Chicken Burrito", brand: "Chipotle", calories: 820, protein: 44, carbs: 82, fat: 32, servingSize: "1 burrito", category: .taco, keywords: ["chicken burrito", "chipotle", "burrito"], imageKeywords: ["burrito", "chipotle"]),
            FastFoodItem(id: UUID(), name: "Steak Burrito", brand: "Chipotle", calories: 860, protein: 46, carbs: 82, fat: 36, servingSize: "1 burrito", category: .taco, keywords: ["steak burrito", "chipotle", "burrito"], imageKeywords: ["burrito", "chipotle"]),
            FastFoodItem(id: UUID(), name: "Chicken Salad", brand: "Chipotle", calories: 540, protein: 40, carbs: 41, fat: 24, servingSize: "1 salad", category: .salad, keywords: ["chicken salad", "chipotle", "salad"], imageKeywords: ["salad", "chipotle"]),
            
            // Panera Bread
            FastFoodItem(id: UUID(), name: "Broccoli Cheddar Soup", brand: "Panera Bread", calories: 360, protein: 12, carbs: 24, fat: 24, servingSize: "1 bowl", category: .sandwich, keywords: ["broccoli cheddar soup", "panera", "soup"], imageKeywords: ["soup", "panera"]),
            FastFoodItem(id: UUID(), name: "Chicken Noodle Soup", brand: "Panera Bread", calories: 120, protein: 8, carbs: 16, fat: 4, servingSize: "1 bowl", category: .sandwich, keywords: ["chicken noodle soup", "panera", "soup"], imageKeywords: ["soup", "panera"]),
            FastFoodItem(id: UUID(), name: "Turkey Sandwich", brand: "Panera Bread", calories: 420, protein: 24, carbs: 48, fat: 16, servingSize: "1 sandwich", category: .sandwich, keywords: ["turkey sandwich", "panera", "sandwich"], imageKeywords: ["turkey sandwich", "panera", "sandwich"]),
            FastFoodItem(id: UUID(), name: "Chicken Sandwich", brand: "Panera Bread", calories: 480, protein: 28, carbs: 52, fat: 18, servingSize: "1 sandwich", category: .sandwich, keywords: ["chicken sandwich", "panera", "sandwich"], imageKeywords: ["chicken sandwich", "panera", "sandwich"]),
            
            // In-N-Out
            FastFoodItem(id: UUID(), name: "Double-Double", brand: "In-N-Out", calories: 670, protein: 37, carbs: 39, fat: 41, servingSize: "1 burger", category: .burger, keywords: ["double double", "in n out", "burger"], imageKeywords: ["double double", "in n out", "burger"]),
            FastFoodItem(id: UUID(), name: "Cheeseburger", brand: "In-N-Out", calories: 480, protein: 22, carbs: 39, fat: 27, servingSize: "1 burger", category: .burger, keywords: ["cheeseburger", "in n out", "burger"], imageKeywords: ["cheeseburger", "in n out", "burger"]),
            FastFoodItem(id: UUID(), name: "Hamburger", brand: "In-N-Out", calories: 390, protein: 16, carbs: 39, fat: 19, servingSize: "1 burger", category: .burger, keywords: ["hamburger", "in n out", "burger"], imageKeywords: ["hamburger", "in n out", "burger"]),
            FastFoodItem(id: UUID(), name: "French Fries", brand: "In-N-Out", calories: 395, protein: 7, carbs: 54, fat: 18, servingSize: "1 order", category: .side, keywords: ["french fries", "in n out", "fries"], imageKeywords: ["french fries", "in n out", "fries"]),
            
            // Chick-fil-A
            FastFoodItem(id: UUID(), name: "Chicken Sandwich", brand: "Chick-fil-A", calories: 440, protein: 28, carbs: 41, fat: 16, servingSize: "1 sandwich", category: .sandwich, keywords: ["chicken sandwich", "chick fil a", "chickfila"], imageKeywords: ["chicken sandwich", "chick fil a"]),
            FastFoodItem(id: UUID(), name: "Spicy Chicken Sandwich", brand: "Chick-fil-A", calories: 450, protein: 28, carbs: 42, fat: 18, servingSize: "1 sandwich", category: .sandwich, keywords: ["spicy chicken sandwich", "chick fil a", "chickfila"], imageKeywords: ["spicy chicken sandwich", "chick fil a"]),
            FastFoodItem(id: UUID(), name: "Chicken Nuggets (8 piece)", brand: "Chick-fil-A", calories: 250, protein: 28, carbs: 11, fat: 11, servingSize: "8 pieces", category: .chicken, keywords: ["chicken nuggets", "chick fil a", "chickfila"], imageKeywords: ["chicken nuggets", "chick fil a"]),
            FastFoodItem(id: UUID(), name: "Waffle Fries", brand: "Chick-fil-A", calories: 360, protein: 4, carbs: 44, fat: 18, servingSize: "1 order", category: .side, keywords: ["waffle fries", "chick fil a", "chickfila"], imageKeywords: ["waffle fries", "chick fil a"]),
            
            // Five Guys
            FastFoodItem(id: UUID(), name: "Cheeseburger", brand: "Five Guys", calories: 840, protein: 47, carbs: 39, fat: 55, servingSize: "1 burger", category: .burger, keywords: ["cheeseburger", "five guys", "burger"], imageKeywords: ["cheeseburger", "five guys", "burger"]),
            FastFoodItem(id: UUID(), name: "Bacon Cheeseburger", brand: "Five Guys", calories: 920, protein: 49, carbs: 39, fat: 62, servingSize: "1 burger", category: .burger, keywords: ["bacon cheeseburger", "five guys", "burger"], imageKeywords: ["bacon cheeseburger", "five guys", "burger"]),
            FastFoodItem(id: UUID(), name: "Little Cheeseburger", brand: "Five Guys", calories: 550, protein: 26, carbs: 39, fat: 30, servingSize: "1 burger", category: .burger, keywords: ["little cheeseburger", "five guys", "burger"], imageKeywords: ["little cheeseburger", "five guys", "burger"]),
            FastFoodItem(id: UUID(), name: "French Fries", brand: "Five Guys", calories: 953, protein: 13, carbs: 122, fat: 41, servingSize: "1 order", category: .side, keywords: ["french fries", "five guys", "fries"], imageKeywords: ["french fries", "five guys", "fries"]),
            
            // Shake Shack
            FastFoodItem(id: UUID(), name: "ShackBurger", brand: "Shake Shack", calories: 550, protein: 25, carbs: 35, fat: 34, servingSize: "1 burger", category: .burger, keywords: ["shackburger", "shake shack", "burger"], imageKeywords: ["shackburger", "shake shack", "burger"]),
            FastFoodItem(id: UUID(), name: "Double ShackBurger", brand: "Shake Shack", calories: 770, protein: 40, carbs: 35, fat: 50, servingSize: "1 burger", category: .burger, keywords: ["double shackburger", "shake shack", "burger"], imageKeywords: ["double shackburger", "shake shack", "burger"]),
            FastFoodItem(id: UUID(), name: "Chicken Shack", brand: "Shake Shack", calories: 470, protein: 28, carbs: 42, fat: 22, servingSize: "1 sandwich", category: .sandwich, keywords: ["chicken shack", "shake shack", "chicken sandwich"], imageKeywords: ["chicken shack", "shake shack", "chicken sandwich"]),
            FastFoodItem(id: UUID(), name: "Crinkle Cut Fries", brand: "Shake Shack", calories: 470, protein: 6, carbs: 58, fat: 24, servingSize: "1 order", category: .side, keywords: ["crinkle cut fries", "shake shack", "fries"], imageKeywords: ["crinkle cut fries", "shake shack", "fries"])
        ]
    }
    
    // MARK: - Search Methods
    
    func searchFastFood(query: String) -> [FastFoodItem] {
        let lowercasedQuery = query.lowercased()
        
        return fastFoodItems.filter { item in
            // Check if query matches any keywords
            let keywordMatch = item.keywords.contains { keyword in
                keyword.lowercased().contains(lowercasedQuery)
            }
            
            // Check if query matches item name
            let nameMatch = item.name.lowercased().contains(lowercasedQuery)
            
            // Check if query matches brand
            let brandMatch = item.brand.lowercased().contains(lowercasedQuery)
            
            return keywordMatch || nameMatch || brandMatch
        }
    }
    
    func searchByImageKeywords(_ keywords: [String]) -> [FastFoodItem] {
        let lowercasedKeywords = keywords.map { $0.lowercased() }
        
        return fastFoodItems.filter { item in
            return item.imageKeywords.contains { itemKeyword in
                lowercasedKeywords.contains { keyword in
                    itemKeyword.lowercased().contains(keyword)
                }
            }
        }
    }
    
    func getItemsByBrand(_ brand: String) -> [FastFoodItem] {
        return fastFoodItems.filter { $0.brand.lowercased().contains(brand.lowercased()) }
    }
    
    func getItemsByCategory(_ category: FastFoodCategory) -> [FastFoodItem] {
        return fastFoodItems.filter { $0.category == category }
    }
    
    func getAllBrands() -> [String] {
        let brands = Set(fastFoodItems.map { $0.brand })
        return Array(brands).sorted()
    }
    
    func getAllCategories() -> [FastFoodCategory] {
        return FastFoodCategory.allCases
    }
} 
 