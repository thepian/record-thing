/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A row used by ProductList that adjusts its layout based on environment and platform
*/

import SwiftUI

struct ProductRow: View {
    var product: ProductDef
    
    @EnvironmentObject private var model: Model

    var body: some View {
        HStack(alignment: .top) {
            let imageClipShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            product.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(imageClipShape)
                .overlay(imageClipShape.strokeBorder(.quaternary, lineWidth: 0.5))
                .accessibility(hidden: true)

            VStack(alignment: .leading) {
                Text(product.title)
                    .font(.headline)
                
                Text(listedIngredients)
                    .lineLimit(2)
                    .accessibility(label: Text("Ingredients: \(listedIngredients).",
                                               comment: "Accessibility label containing the full list of smoothie ingredients"))

                Text(product.energy.formatted(.measurement(width: .wide, usage: .food)))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
    
    var listedIngredients: String {
        guard !product.menuIngredients.isEmpty else { return "" }
        var list = [String]()
        list.append(product.menuIngredients.first!.ingredient.name.localizedCapitalized)
        list += product.menuIngredients.dropFirst().map { $0.ingredient.name.localizedLowercase }
        return ListFormatter.localizedString(byJoining: list)
    }
    
    var cornerRadius: Double {
        #if os(iOS)
        return 10
        #else
        return 4
        #endif
    }
}

// MARK: - Previews

struct ProductRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProductRow(product: .lemonberry)
            ProductRow(product: .thatsASmore)
        }
        .frame(width: 250, alignment: .leading)
        .padding(.horizontal)
        .previewLayout(.sizeThatFits)
        .environmentObject(Model())
    }
}
