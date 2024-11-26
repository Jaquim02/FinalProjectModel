//
//  ContentView.swift
//  arTest
//
//  Created by Jorge Tovar on 25/11/24.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some View {
        Group {
            if isLoggedIn {
                MainView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "road.lanes")
                    .imageScale(.large)
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                
                Text("Road Sign Detector")
                    .font(.title)
                    .fontWeight(.bold)
                
                NavigationLink(destination: ScanView()) {
                    Label("Road Signs", systemImage: "signpost.right.fill")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                
                NavigationLink(destination: DigitRecognitionView()) {
                    Label("Digit Recognition", systemImage: "number.circle.fill")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .padding(.horizontal)
                
                Button(action: { isLoggedIn = false }) {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
