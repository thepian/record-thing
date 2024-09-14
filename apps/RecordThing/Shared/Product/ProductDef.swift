/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model that represents a smoothie — including its descriptive information and ingredients (and nutrition facts).
*/

import Foundation

struct ProductDef: Identifiable, Codable {
    typealias ID = String;
    
    var id: ID
    var title: String
    var description: AttributedString
    var measuredIngredients: [MeasuredIngredient]
}

extension ProductDef {
    init?(for id: ProductDef.ID) {
        guard let product = ProductDef.all().first(where: { $0.id == id }) else { return nil }
        self = product
    }

    var kilocalories: Int {
        let value = measuredIngredients.reduce(0) { total, ingredient in total + ingredient.kilocalories }
        return Int(round(Double(value) / 10.0) * 10)
    }

    var energy: Measurement<UnitEnergy> {
        return Measurement<UnitEnergy>(value: Double(kilocalories), unit: .kilocalories)
    }

    // The nutritional information for the combined ingredients
    var nutritionFact: NutritionFact {
        let facts = measuredIngredients.compactMap { $0.nutritionFact }
        guard let firstFact = facts.first else {
            print("Could not find nutrition facts for \(title) — using `banana`'s nutrition facts.")
            return .banana
        }
        return facts.dropFirst().reduce(firstFact, +)
    }
    
    var menuIngredients: [MeasuredIngredient] {
        measuredIngredients.filter { $0.id != Ingredient.water.id }
    }
    
    func matches(_ string: String) -> Bool {
        string.isEmpty ||
        title.localizedCaseInsensitiveContains(string) ||
        menuIngredients.contains {
            $0.ingredient.name.localizedCaseInsensitiveContains(string)
        }
    }
}

extension ProductDef: Hashable {
    static func == (lhs: ProductDef, rhs: ProductDef) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - ProductDef List
extension ProductDef {
    @ProductArrayBuilder
    static func all(includingPaid: Bool = true) -> [ProductDef] {
        ProductDef(id: "berry-blue", title: String(localized: "Berry Blue", comment: "ProductDef name")) {
            AttributedString(localized: "*Filling* and *refreshing*, this smoothie will fill you with joy!",
                             comment: "Berry Blue smoothie description")

            Ingredient.orange.measured(with: .cups).scaled(by: 1.5)
            Ingredient.blueberry.measured(with: .cups)
            Ingredient.avocado.measured(with: .cups).scaled(by: 0.2)
        }

        ProductDef(id: "carrot-chops", title: String(localized: "Carrot Chops", comment: "ProductDef name")) {
            AttributedString(localized: "*Packed* with vitamin A and C, Carrot Chops is a great way to start your day!",
                             comment: "Carrot Chops smoothie description")

            Ingredient.orange.measured(with: .cups).scaled(by: 1.5)
            Ingredient.carrot.measured(with: .cups).scaled(by: 0.5)
            Ingredient.mango.measured(with: .cups).scaled(by: 0.5)
        }

        if includingPaid {
            ProductDef(id: "pina-y-coco", title: String(localized: "Piña y Coco", comment: "ProductDef name")) {
                AttributedString(localized: "Enjoy the *tropical* flavors of coconut and pineapple!", comment: "Piña y Coco smoothie description")
                Ingredient.pineapple.measured(with: .cups).scaled(by: 1.5)
                Ingredient.almondMilk.measured(with: .cups)
                Ingredient.coconut.measured(with: .cups).scaled(by: 0.5)
            }

            ProductDef(id: "hulking-lemonade", title: String(localized: "Hulking Lemonade", comment: "ProductDef name")) {
                AttributedString(localized: "This is not just *any* lemonade. It will give you *powers* you'll struggle to control!",
                                  comment: "Hulking Lemonade smoothie description")
                Ingredient.lemon.measured(with: .cups).scaled(by: 1.5)
                Ingredient.spinach.measured(with: .cups)
                Ingredient.avocado.measured(with: .cups).scaled(by: 0.2)
                Ingredient.water.measured(with: .cups).scaled(by: 0.2)
            }

            ProductDef(id: "kiwi-cutie", title: String(localized: "Kiwi Cutie", comment: "ProductDef name")) {
                AttributedString(localized: "Kiwi Cutie is beautiful *inside* ***and*** *out*! Packed with nutrients to start your day!",
                                  comment: "Kiwi Cutie smoothie description")
                Ingredient.kiwi.measured(with: .cups)
                Ingredient.orange.measured(with: .cups)
                Ingredient.spinach.measured(with: .cups)
            }

            ProductDef( id: "lemonberry", title: String(localized: "Lemonberry", comment: "ProductDef name")) {
                AttributedString(localized: "A refreshing blend that's a *real kick*!", comment: "Lemonberry smoothie description")

                Ingredient.raspberry.measured(with: .cups)
                Ingredient.strawberry.measured(with: .cups)
                Ingredient.lemon.measured(with: .cups).scaled(by: 0.5)
                Ingredient.water.measured(with: .cups).scaled(by: 0.5)

            }

            ProductDef(id: "love-you-berry-much", title: String(localized: "Love You Berry Much", comment: "ProductDef name")) {
                AttributedString(localized: "If you *love* berries berry berry much, you will love this one!",
                                 comment: "Love You Berry Much smoothie description")

                Ingredient.strawberry.measured(with: .cups).scaled(by: 0.75)
                Ingredient.blueberry.measured(with: .cups).scaled(by: 0.5)
                Ingredient.raspberry.measured(with: .cups).scaled(by: 0.5)
                Ingredient.water.measured(with: .cups).scaled(by: 0.5)
            }

            ProductDef(id: "mango-jambo", title: String(localized: "Mango Jambo", comment: "ProductDef name")) {
                AttributedString(localized: "Dance around with this *delicious* tropical blend!", comment: "Mango Jambo smoothie description")

                Ingredient.mango.measured(with: .cups)
                Ingredient.pineapple.measured(with: .cups).scaled(by: 0.5)
                Ingredient.water.measured(with: .cups).scaled(by: 0.5)
            }

            ProductDef(id: "one-in-a-melon", title: String(localized: "One in a Melon", comment: "ProductDef name")) {
                AttributedString(localized: "Feel special this summer with the *coolest* drink in our menu!",
                                 comment: "One in a Melon smoothie description")

                Ingredient.watermelon.measured(with: .cups).scaled(by: 2)
                Ingredient.raspberry.measured(with: .cups)
                Ingredient.water.measured(with: .cups).scaled(by: 0.5)
            }

            ProductDef(id: "papas-papaya", title: String(localized: "Papa's Papaya", comment: "ProductDef name")) {
                AttributedString(localized: "Papa would be proud of you if he saw you drinking this!", comment: "Papa's Papaya smoothie description")

                Ingredient.orange.measured(with: .cups)
                Ingredient.mango.measured(with: .cups).scaled(by: 0.5)
                Ingredient.papaya.measured(with: .cups).scaled(by: 0.5)
            }

            ProductDef(id: "peanut-butter-cup", title: String(localized: "Peanut Butter Cup", comment: "ProductDef name")) {
                AttributedString(localized: "Ever wondered what it was like to *drink a peanut butter cup*? Wonder no more!",
                                 comment: "Peanut Butter Cup smoothie description")

                Ingredient.almondMilk.measured(with: .cups)
                Ingredient.banana.measured(with: .cups).scaled(by: 0.5)
                Ingredient.chocolate.measured(with: .tablespoons).scaled(by: 2)
                Ingredient.peanutButter.measured(with: .tablespoons)
            }

            ProductDef(id: "sailor-man", title: String(localized: "Sailor Man", comment: "ProductDef name")) {
                AttributedString(localized: "*Get strong* with this delicious spinach smoothie!", comment: "Sailor Man smoothie description")

                Ingredient.orange.measured(with: .cups).scaled(by: 1.5)
                Ingredient.spinach.measured(with: .cups)
            }

            ProductDef(id: "thats-a-smore", title: String(localized: "That's a Smore!", comment: "ProductDef name")) {
                AttributedString(localized: "When the world seems to rock like you've had too much choc, that's *a smore*!",
                                 comment: "That's a Smore! smoothie description")

                Ingredient.almondMilk.measured(with: .cups)
                Ingredient.coconut.measured(with: .cups).scaled(by: 0.5)
                Ingredient.chocolate.measured(with: .tablespoons)
            }
        }

        ProductDef(id: "thats-berry-bananas", title: String(localized: "That's Berry Bananas!", comment: "ProductDef name")) {
            AttributedString(localized: "You'll go *crazy* with this classic!", comment: "That's Berry Bananas! smoothie description")

            Ingredient.almondMilk.measured(with: .cups)
            Ingredient.banana.measured(with: .cups)
            Ingredient.strawberry.measured(with: .cups)
        }

        if includingPaid {
            ProductDef(id: "tropical-blue", title: String(localized: "Tropical Blue", comment: "ProductDef name")) {
                AttributedString(
                    localized: "A delicious blend of *tropical fruits and blueberries* will have you sambaing around like you never knew you could!",
                                  comment: "Tropical Blue smoothie description")
                Ingredient.almondMilk.measured(with: .cups)
                Ingredient.banana.measured(with: .cups).scaled(by: 0.5)
                Ingredient.blueberry.measured(with: .cups).scaled(by: 0.5)
                Ingredient.mango.measured(with: .cups).scaled(by: 0.5)
            }
        }
    }

    // Used in previews.
    static var berryBlue: ProductDef { ProductDef(for: "berry-blue")! }
    static var kiwiCutie: ProductDef { ProductDef(for: "kiwi-cutie")! }
    static var hulkingLemonade: ProductDef { ProductDef(for: "hulking-lemonade")! }
    static var mangoJambo: ProductDef { ProductDef(for: "mango-jambo")! }
    static var tropicalBlue: ProductDef { ProductDef(for: "tropical-blue")! }
    static var lemonberry: ProductDef { ProductDef(for: "lemonberry")! }
    static var oneInAMelon: ProductDef { ProductDef(for: "one-in-a-melon")! }
    static var thatsASmore: ProductDef { ProductDef(for: "thats-a-smore")! }
    static var thatsBerryBananas: ProductDef { ProductDef(for: "thats-berry-bananas")! }
}

extension ProductDef {
    init(id: ProductDef.ID, title: String, @ProductBuilder _ makeIngredients: () -> (AttributedString, [MeasuredIngredient])) {
        let (description, ingredients) = makeIngredients()
        self.init(id: id, title: title, description: description, measuredIngredients: ingredients)
    }
}

@resultBuilder
enum ProductBuilder {
    static func buildBlock(_ description: AttributedString, _ ingredients: MeasuredIngredient...) -> (AttributedString, [MeasuredIngredient]) {
        return (description, ingredients)
    }

    @available(*, unavailable, message: "first statement of ProductBuilder must be its description String")
    static func buildBlock(_ ingredients: MeasuredIngredient...) -> (String, [MeasuredIngredient]) {
        fatalError()
    }
}

@resultBuilder
enum ProductArrayBuilder {
    static func buildEither(first component: [ProductDef]) -> [ProductDef] {
        return component
    }

    static func buildEither(second component: [ProductDef]) -> [ProductDef] {
        return component
    }

    static func buildOptional(_ component: [ProductDef]?) -> [ProductDef] {
        return component ?? []
    }

    static func buildExpression(_ expression: ProductDef) -> [ProductDef] {
        return [expression]
    }

    static func buildExpression(_ expression: ()) -> [ProductDef] {
        return []
    }

    static func buildBlock(_ products: [ProductDef]...) -> [ProductDef] {
        return products.flatMap { $0 }
    }
}
