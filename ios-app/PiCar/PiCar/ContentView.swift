//
//  ContentView.swift
//  PiCar
//
//  Root content view for Pi Car Controller
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CarControlViewModel()

    var body: some View {
        MainView()
            .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
}
