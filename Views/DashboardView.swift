/
//  DashboardView.swift
//  AemtliApp
//
//  Created by Privat on 18.06.2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                Text("Today")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: progressPercentage)
                        .stroke(Color.purple, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: progressPercentage)
                    
                    VStack {
                        if progressPercentage >= 1.0 {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressPercentage)
                        } else {
                            Text("\(Int(progressPercentage * 100))%")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Task List
                VStack(spacing: 16) {
                    ForEach(appState.chores) { chore in
                        TaskRowView(chore: chore)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let currentUser = appState.currentUser {
                        Text(currentUser.role.displayLabel)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var progressPercentage: Double {
        let totalChores = Double(appState.chores.count)
        let completedChores = Double(appState.chores.filter { $0.isDone }.count)
        return totalChores > 0 ? completedChores / totalChores : 0
    }
}

struct TaskRowView: View {
    let chore: Chore
    
    var body: some View {
        HStack(spacing: 16) {
            // Target icon
            Image(systemName: "target")
                .font(.system(size: 24))
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Goal: 1")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Completion status
            if chore.isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .background(Color.blue)
                    .clipShape(Circle())
            } else {
                Text("0")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color(red: 32/255, green: 32/255, blue: 36/255))
        .cornerRadius(16)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
