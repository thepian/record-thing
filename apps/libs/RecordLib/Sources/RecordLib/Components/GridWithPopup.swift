//
//  GridWithPopup.swift
//  RecordLib
//
//  Created by Henrik Vendelbo on 24.04.2025.
//

import SwiftUI

public struct GridPopupCard<RowType: Sendable, Content: View>: View where RowType: Equatable, RowType: Identifiable {
    public var item: RowType
    public var presenting: Bool
    public var closeAction: () -> Void = {}
    public var itemContent: (RowType, Bool, @escaping () -> Void, @escaping () -> Void) -> Content
    
    @State private var visibleSide = FlipViewSide.front
    
    public init(
        item: RowType,
        presenting: Bool,
        closeAction: @escaping () -> Void = {},
        @ViewBuilder itemContent: @escaping (RowType, Bool, @escaping () -> Void, @escaping () -> Void) -> Content
    ) {
        self.item = item
        self.presenting = presenting
        self.closeAction = closeAction
        self.itemContent = itemContent
    }
    
    public var body: some View {
        FlipView(visibleSide: visibleSide) {
            itemContent(item, presenting, closeAction, flipCard)
        } back: {
            itemContent(item, presenting, closeAction, flipCard)
        }
        .contentShape(Rectangle())
        .animation(.flipCard, value: visibleSide)
    }
    
    public func flipCard() {
        visibleSide.toggle()
    }
}

public struct GridWithPopup<RowType: Sendable, HeaderView: View, BottomBar: View, ItemContent: View>: View where RowType: Equatable, RowType: Identifiable {
    
    @Binding private var selectedID: RowType.ID?
    @State private var topmostID: RowType.ID?
    @Binding public var didLoad: Bool
    @Binding public var results: [RowType]
    
    @Namespace private var namespace
    let headerView: HeaderView
    let bottomBar: BottomBar
    let itemContent: (RowType, Bool, @escaping () -> Void, @escaping () -> Void) -> ItemContent

    public init(
        results: Binding<[RowType]>,
        didLoad: Binding<Bool>,
        selectedID: Binding<RowType.ID?>,
        @ViewBuilder headerView: () -> HeaderView,
        @ViewBuilder bottomBar: () -> BottomBar,
        @ViewBuilder itemContent: @escaping (RowType, Bool, @escaping () -> Void, @escaping () -> Void) -> ItemContent
    ) {
        self._selectedID = selectedID
        self.headerView = headerView()
        self.bottomBar = bottomBar()
        self._results = results
        self._didLoad = didLoad
        self.itemContent = itemContent
    }
    
    public var body: some View {
        ZStack {
            ScrollView {
                content
                    #if os(macOS)
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                    #endif
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar
            }
            
            if didLoad {
                ForEach(results) { item in
                    let presenting = if selectedID != nil { (selectedID == item.id) } else { false }
                    
                    GridPopupCard(
                        item: item,
                        presenting: presenting,
                        closeAction: deselectItem
                    ) { item, isPresenting, close, flip in
                        itemContent(item, isPresenting, close, flip)
                    }
                    .matchedGeometryEffect(id: item.id, in: namespace, isSource: presenting)
                    .aspectRatio(0.75, contentMode: .fit)
                    .shadow(color: Color.black.opacity(presenting ? 0.2 : 0), radius: 20, y: 10)
                    .padding(20)
                    .opacity(presenting ? 1 : 0)
                    .zIndex(topmostID == item.id ? 1 : 0)
                    .accessibilityElement(children: .contain)
                    .accessibility(sortPriority: presenting ? 1 : 0)
                    .accessibility(hidden: !presenting)
                }
            } else {
                ProgressView()
            }
        }
    }
    
    var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView


            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 16, alignment: .top)], alignment: .center, spacing: 16) {
                ForEach(results) { item in
                    let presenting = if selectedID != nil { (selectedID == item.id) } else { false }
                    Button(action: {
                        select(item: item)
                    }) {
                        itemContent(item, presenting, deselectItem, {})
                            .matchedGeometryEffect(
                                id: item.id,
                                in: namespace,
                                isSource: !presenting
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.squishable(fadeOnPress: false))
                    .aspectRatio(1, contentMode: .fit)
                    .zIndex(topmostID == item.id ? 1 : 0)
                }
            }
        }
//        .padding()
    }
    
    func select(item: RowType) {
        topmostID = item.id
        withAnimation(.openCard) {
            selectedID = item.id
        }
    }
    
    func deselectItem() {
        withAnimation(.closeCard) {
            selectedID = nil
        }
    }
}

