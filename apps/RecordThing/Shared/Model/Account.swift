/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A representation of a customer's account. Used for calculating free smoothie redemption.
*/

struct Account {
    var pointsSpent = 0
    var unstampedPoints = 0
    
    mutating func clearUnstampedPoints() {
        unstampedPoints = 0
    }
}
