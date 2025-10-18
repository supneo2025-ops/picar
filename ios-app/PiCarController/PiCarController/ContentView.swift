//
//  ContentView.swift
//  PiCarController
//
//  Root content view
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CarControlViewModel()

    var body: some View {
        MainView()
            .environmentObject(viewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
