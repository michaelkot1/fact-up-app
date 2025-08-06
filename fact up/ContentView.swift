//
//  ContentView.swift
//  fact up
//
//  Created by Michael Kot on 8/5/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: FactViewModel
    
    var body: some View {
        FactCardView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
        .environmentObject(FactViewModel())
}
