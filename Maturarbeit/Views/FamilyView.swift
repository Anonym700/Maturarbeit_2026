//
//  FamilyView.swift
//  AemtliApp
//
//  Refactored with complete design system integration
//  Updated: October 2025
//

import SwiftUI

struct FamilyView: View {
    @EnvironmentObject var appState: AppState
    @State private var shareURL: URL?
    @State private var showingShareSheet = false
    @State private var showingLinkCopiedAlert = false
    @State private var joinLinkText: String = ""
    @State private var isJoining = false
    @State private var joinError: String?
    @State private var joinSuccess = false
    @State private var reloadState: ReloadButtonState = .idle
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xLarge) {
                    // Family Sharing Section
                    familySharingSection
                    
                    // Current User Status Section
                    currentUserStatusSection
                    
                    // Join Family Section (always visible)
                    joinFamilySection
                    
                    // Family Members List Section
                    if appState.hasActiveShare {
                        familyMembersSection
                    }
                }
                .padding(AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.xLarge)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Family")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let currentUser = appState.currentUser {
                        RoleBadge(role: currentUser.role.displayLabel)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ReloadButton(state: $reloadState) {
                        await appState.reloadAllData()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Link Copied", isPresented: $showingLinkCopiedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Family invitation link has been copied to clipboard. You can now paste it in any messaging app to share with your family.")
            }
        }
        .task {
            // Load participants when view appears
            if appState.hasActiveShare {
                await appState.loadShareParticipants()
                await appState.determineCurrentUserFromShare()
            }
        }
    }
    
    // MARK: - Family Sharing Section
    
    private var familySharingSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Family Sharing")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            if appState.hasActiveShare {
                // Show active share status
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    HStack(spacing: AppTheme.Spacing.medium) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.Colors.success)
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                            Text("Family Sharing Active")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.text)
                            Text(appState.isShareOwner ? "You are the organizer" : "You are a participant")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Share buttons for owner
                    if appState.isShareOwner {
                        VStack(spacing: AppTheme.Spacing.small) {
                            Button(action: copyLinkToClipboard) {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy Link")
                                    Spacer()
                                }
                                .padding(AppTheme.Spacing.small)
                                .background(AppTheme.Colors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.CornerRadius.small)
                            }
                            
                            Button(action: shareLink) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share via...")
                                    Spacer()
                                }
                                .padding(AppTheme.Spacing.small)
                                .background(AppTheme.Colors.accent.opacity(0.1))
                                .foregroundColor(AppTheme.Colors.accent)
                                .cornerRadius(AppTheme.CornerRadius.small)
                            }
                        }
                    }
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
            } else {
                // Show create share button
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Get started by creating a family share. You'll get a link to send to your family members.")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Button(action: createShare) {
                        HStack {
                            Image(systemName: "link.badge.plus")
                            Text("Create Family Share")
                            Spacer()
                        }
                        .padding(AppTheme.Spacing.medium)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
    }
    
    // MARK: - Join Family Section
    
    private var joinFamilySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Join Existing Family")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Already have an invitation link?")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text("📋 Step 1: Long press the link → Copy")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text("📝 Step 2: Paste it below")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // Text Field for Link
            TextField("Paste iCloud share link here", text: $joinLinkText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.vertical, AppTheme.Spacing.small)
            
            // Join Button
            Button(action: joinFamily) {
                HStack {
                    if isJoining {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "person.badge.plus")
                        Text("Join Family")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.Spacing.medium)
                .background(joinLinkText.isEmpty ? AppTheme.Colors.textSecondary : AppTheme.Colors.success)
                .foregroundColor(.white)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .disabled(joinLinkText.isEmpty || isJoining)
            
            // Success Message
            if joinSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Successfully joined the family!")
                }
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.success)
            }
            
            // Error Message
            if let error = joinError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.error)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Current User Status Section
    
    private var currentUserStatusSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Your Status")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
                .accessibilityAddTraits(.isHeader)
            
            HStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: appState.isUserRegistered ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(appState.isUserRegistered ? AppTheme.Colors.success : AppTheme.Colors.warning)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                    if let currentUser = appState.currentUser {
                        Text(currentUser.name)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.text)
                        Text(currentUser.role.displayLabel)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    } else {
                        Text("Not in a Family")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.text)
                        Text("Create or join a family share")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
    }
    
    // MARK: - Actions
    
    private func createShare() {
        Task {
            do {
                let url = try await appState.createFamilyShare()
                shareURL = url
                
                // Load participants and determine current user
                await appState.loadShareParticipants()
                await appState.determineCurrentUserFromShare()
                
                // Automatically show share sheet
                showingShareSheet = true
                print("✅ Share created, loaded \(appState.members.count) participants")
            } catch {
                print("❌ Failed to create share: \(error)")
            }
        }
    }
    
    private func copyLinkToClipboard() {
        Task {
            do {
                let url = try await appState.createFamilyShare()
                
                // Ensure participants are loaded
                await appState.loadShareParticipants()
                await appState.determineCurrentUserFromShare()
                
                UIPasteboard.general.string = url.absoluteString
                print("📋 Link copied to clipboard: \(url.absoluteString)")
                showingLinkCopiedAlert = true
            } catch {
                print("❌ Failed to get share link: \(error)")
            }
        }
    }
    
    private func shareLink() {
        Task {
            do {
                let url = try await appState.createFamilyShare()
                
                // Ensure participants are loaded
                await appState.loadShareParticipants()
                await appState.determineCurrentUserFromShare()
                
                shareURL = url
                showingShareSheet = true
            } catch {
                print("❌ Failed to get share link: \(error)")
            }
        }
    }
    
    private func joinFamily() {
        isJoining = true
        joinError = nil
        joinSuccess = false
        
        Task {
            do {
                // Validate and clean URL
                let cleanedText = joinLinkText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let url = URL(string: cleanedText) else {
                    joinError = "Invalid link format"
                    isJoining = false
                    return
                }
                
                // Check if it's an iCloud share link
                guard url.host?.contains("icloud.com") == true else {
                    joinError = "This is not an iCloud share link"
                    isJoining = false
                    return
                }
                
                print("🔗 Attempting to join via link: \(url)")
                
                // Ensure we have the current user's iCloud ID
                if appState.currentICloudUserID == nil {
                    print("⚠️ No iCloud user ID yet, waiting...")
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    
                    if appState.currentICloudUserID == nil {
                        joinError = "Unable to identify your iCloud account. Please restart the app."
                        isJoining = false
                        return
                    }
                }
                
                print("   Current iCloud ID: \(appState.currentICloudUserID ?? "none")")
                
                // Accept the share via URL
                try await CloudKitManager.shared.acceptShare(from: url)
                
                // CRITICAL: Reload participants AND determine current user
                await appState.loadShareParticipants()
                await appState.determineCurrentUserFromShare()
                
                // Reload chores so they appear
                await appState.loadChores()
                
                // Verify registration
                if !appState.isUserRegistered {
                    joinError = "Joined successfully but unable to link account"
                    print("⚠️ User joined but not registered")
                } else {
                    // Success!
                    joinSuccess = true
                    print("✅ Joined family via pasted link - User is now registered")
                    print("   Current User: \(appState.currentUser?.name ?? "Unknown") (ID: \(appState.currentUserID?.uuidString ?? "nil"))")
                }
                
                joinLinkText = ""
                isJoining = false
            } catch {
                joinError = "Failed to join: \(error.localizedDescription)"
                isJoining = false
                print("❌ Join family error: \(error)")
            }
        }
    }
    
    // MARK: - Family Members Section
    
    private var familyMembersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Family Members")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(appState.members) { member in
                    FamilyMemberCard(
                        member: member,
                        isCurrentUser: member.id == appState.currentUserID
                    )
                }
            }
        }
    }
}

// MARK: - Family Member Card

struct FamilyMemberCard: View {
    let member: FamilyMember
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Member Icon
            Image(systemName: memberIcon)
                .font(.title2)
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: AppTheme.Layout.minTapTarget, height: AppTheme.Layout.minTapTarget)
                .background(AppTheme.Colors.accent.opacity(0.1))
                .clipShape(Circle())
                .accessibilityHidden(true)
            
            // Member Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                Text(member.name)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.text)
                
                Text(member.role.displayLabel)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            // Active Indicator
            if isCurrentUser {
                HStack(spacing: AppTheme.Spacing.xxSmall) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.success)
                    Text("Active")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.success)
                }
                .accessibilityLabel("Currently active user")
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(member.name), \(member.role.displayLabel)\(isCurrentUser ? ", active" : "")")
    }
    
    private var memberIcon: String {
        switch member.role {
        case .parent:
            return "person.crop.circle.fill"
        case .child:
            return "figure.wave"
        }
    }
}

// MARK: - Previews

#Preview {
    FamilyView()
        .environmentObject(AppState())
}

#Preview("Dark Mode") {
    FamilyView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
