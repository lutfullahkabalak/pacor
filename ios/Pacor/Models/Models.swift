import Foundation

struct AuthResponse: Codable {
    let token: String
    let username: String
    let userId: Int

    enum CodingKeys: String, CodingKey {
        case token, username
        case userId = "user_id"
    }
}

struct PlanSettings: Codable, Equatable {
    var planType: String
    var eatingHours: Int
    var fastingHours: Int
    var fastingMinutes: Int

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case eatingHours = "eating_hours"
        case fastingHours = "fasting_hours"
        case fastingMinutes = "fasting_minutes"
    }

    static let `default` = PlanSettings(
        planType: "custom",
        eatingHours: 8,
        fastingHours: 16,
        fastingMinutes: 0
    )
}

struct MealLog: Codable, Identifiable {
    let id: Int
    let userId: Int
    let loggedAt: String
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case loggedAt = "logged_at"
        case note
    }
}

struct DailyStats: Codable {
    let date: String
    let mealCount: Int
    let sessionCount: Int
    let totalEatingHours: Double
    let longestFastHours: Double
    let currentFastHours: Double
    let targetEatingHours: Int
    let targetFastHours: Int
    let planStatus: String

    enum CodingKeys: String, CodingKey {
        case date
        case mealCount = "meal_count"
        case sessionCount = "session_count"
        case totalEatingHours = "total_eating_hours"
        case longestFastHours = "longest_fast_hours"
        case currentFastHours = "current_fast_hours"
        case targetEatingHours = "target_eating_hours"
        case targetFastHours = "target_fast_hours"
        case planStatus = "plan_status"
    }
}

struct CurrentState: Codable {
    let hoursSinceLastMeal: Double
    let lastMealAt: String?
    let today: DailyStats

    enum CodingKeys: String, CodingKey {
        case hoursSinceLastMeal = "hours_since_last_meal"
        case lastMealAt = "last_meal_at"
        case today
    }
}

struct FastingRecord: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let durationHours: Double
}

struct FastingSummary {
    let count: Int
    let longestHours: Double
    let shortestHours: Double
}

struct CompletionInfo {
    let percent: Int
    let fillRatio: Double
}

struct APIErrorResponse: Decodable {
    let error: String?
}
