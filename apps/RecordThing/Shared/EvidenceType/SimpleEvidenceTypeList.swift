import SwiftUI
import Blackbird
import RecordLib

struct SimpleEvidenceTypeList: View {
    @BlackbirdLiveModels({ try await EvidenceType.read(from: $0, orderBy: .ascending(\.$name)) }) var types

    var body: some View {
        Text("Scroll")
        ScrollViewReader { proxy in
            VStack {
                if types.didLoad {
                    Text("List")
                    ForEach(types.results) { type in
                        NavigationLink(destination: EvidenceTypeView(type: type)) {
                            EvidenceTypeRow(type: type)
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
    @Previewable @StateObject var model = Model(loadedLangConst: "en")

    EvidenceTypeList()
        .environment(\.blackbirdDatabase, database)
        .environmentObject(model)
}
