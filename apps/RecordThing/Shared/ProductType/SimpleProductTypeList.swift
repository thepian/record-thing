import SwiftUI
import Blackbird

struct SimpleProductTypeList: View {
    @BlackbirdLiveModels({ try await ProductType.read(from: $0, orderBy: .ascending(\.$name)) }) var types

    var body: some View {
        Text("Scroll")
        ScrollViewReader { proxy in
            VStack {
                if types.didLoad {
                    Text("List")
                    ForEach(types.results) { productType in
                        NavigationLink(destination: ProductTypeView(product: productType)) {
                            ProductTypeRow(product: productType)
                        }
                    }
                } else {
                    Group {
                        ProgressView()
                        Text("Loading")
                    }
                }
            }
        }
    }
    
}

#Preview {
    @Previewable @StateObject var database = try! Blackbird.Database(path: "/Volumes/Projects/Evidently/record-thing/libs/record_thing/record-thing.sqlite")
    @Previewable @StateObject var model = Model()

    ProductTypeList()
        .environment(\.blackbirdDatabase, database)
        .environmentObject(model)
}
