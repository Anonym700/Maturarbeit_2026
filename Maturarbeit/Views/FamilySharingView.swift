//
//  FamilySharingView.swift
//  Maturarbeit
//
//  Family Sharing mit CKShare
//

import SwiftUI
import CloudKit

struct FamilySharingView: View {
    @EnvironmentObject var appState: AppState
    @State private var shareURL: URL?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingShareSheet = false
    @State private var joinLinkText: String = ""
    @State private var isJoining = false
    @State private var joinSuccessMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xLarge) {
                    // Status Section
                    statusSection
                    
                    // Share Management Section
                    if appState.hasActiveShare {
                        shareManagementSection
                        
                        // Participants Section
                        participantsSection
                    } else {
                        createShareSection
                    }
                    
                    // Join Family Section (ALWAYS visible)
                    joinFamilySection
                }
                .padding(AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.xLarge)
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Family Sharing")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Status")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            HStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: appState.hasActiveShare ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(appState.hasActiveShare ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                    Text(appState.hasActiveShare ? "Family Sharing Active" : "No Family Share")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    if appState.hasActiveShare {
                        Text(appState.isShareOwner ? "You are the organizer" : "You are a participant")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    } else {
                        Text("Create a share to invite your family")
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
    
    // MARK: - Create Share Section
    
    private var createShareSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Get Started")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            Text("Create a family share to sync tasks across all devices. You'll get a link to send to your family members.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Button(action: {
                createShare()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "link.badge.plus")
                        Text("Create Family Share")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.Colors.accent)
                .foregroundColor(.white)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .disabled(isLoading)
            
            if let error = errorMessage {
                Text(error)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.error)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground.opacity(0.5))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Share Management Section
    
    private var shareManagementSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Invite Family")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            Text("Share this link with your family members so they can join and see all tasks.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            if appState.isShareOwner {
                VStack(spacing: AppTheme.Spacing.small) {
                    // Share Link Button
                    Button(action: {
                        shareLink()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Invitation Link")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .padding(AppTheme.Spacing.medium)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                    
                    // Copy Link Button (easier for TestFlight)
                    Button(action: {
                        copyLink()
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Link to Clipboard")
                            Spacer()
                        }
                        .padding(AppTheme.Spacing.medium)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.cardBackground)
                        .foregroundColor(AppTheme.Colors.accent)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(AppTheme.Colors.accent, lineWidth: 1)
                        )
                    }
                    
                    // Copy Success Message
                    if let successMessage = joinSuccessMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(successMessage)
                        }
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.success)
                    }
                }
            } else {
                Text("Only the organizer can invite new members")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(AppTheme.Spacing.small)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.small)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground.opacity(0.5))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Participants Section
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Family Members")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(appState.members) { member in
                    HStack(spacing: AppTheme.Spacing.medium) {
                        Image(systemName: member.role == .parent ? "person.crop.circle.fill" : "figure.wave")
                            .font(.title2)
                            .foregroundColor(AppTheme.Colors.accent)
                            .frame(width: AppTheme.Layout.minTapTarget, height: AppTheme.Layout.minTapTarget)
                            .background(AppTheme.Colors.accent.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                            Text(member.name)
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.text)
                            
                            Text(member.role.displayLabel)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        if member.id == appState.currentUserID {
                            Text("You")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.success)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.Colors.success.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    .padding(AppTheme.Spacing.medium)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
        }
    }
    
    // MARK: - Join Family Section
    
    private var joinFamilySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Join Existing Family")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.text)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
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
            Button(action: {
                joinFamily()
            }) {
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
            if let successMessage = joinSuccessMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(successMessage)
                }
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.success)
            }
            
            // Error Message
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.error)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.Colors.cardBackground.opacity(0.5))
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
    
    // MARK: - Actions
    
    private func createShare() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let url = try await appState.createFamilyShare()
                shareURL = url
                
                // Load participants and determine current user
                await appState.loadShareParticipants()
                await appState.determineCurrentUserFromShare()
                
                isLoading = false
                
                // Automatically show share sheet after creating
                showingShareSheet = true
            } catch {
                errorMessage = "Failed to create share: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func shareLink() {
        Task {
            do {
                let url = try await appState.createFamilyShare()
                shareURL = url
                
                // Ensure participants are loaded
                await appState.loadShareParticipants()
                await appState.determineCurrentUserFromShare()
                
                showingShareSheet = true
            } catch {
                errorMessage = "Failed to get share link: \(error.localizedDescription)"
            }
        }
    }
    
    private func copyLink() {
        Task {
            do {
                let url = try await appState.createFamilyShare()
                
                // Ensure participants are loaded
                await appState.loadShareParticipants()
                await appState.determineCurrentUserFromShare()
                
                // Copy to clipboard
                UIPasteboard.general.string = url.absoluteString
                
                // Show success feedback
                joinSuccessMessage = "Link copied to clipboard!"
                
                // Clear message after 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                joinSuccessMessage = nil
            } catch {
                errorMessage = "Failed to copy link: \(error.localizedDescription)"
            }
        }
    }
    
    private func joinFamily() {
        isJoining = true
        errorMessage = nil
        joinSuccessMessage = nil
        
        Task {
            do {
                // Validate and clean URL
                let cleanedText = joinLinkText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let url = URL(string: cleanedText) else {
                    errorMessage = "Invalid link format"
                    isJoining = false
                    return
                }
                
                // Check if it's an iCloud share link
                guard url.host?.contains("icloud.com") == true else {
                    errorMessage = "This is not an iCloud share link"
                    isJoining = false
                    return
                }
                
                // CRITICAL: Ensure we have the current user's iCloud ID before joining
                if appState.currentICloudUserID == nil {
                    // This will be fetched in AppState init, but let's make sure
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    
                    if appState.currentICloudUserID == nil {
                        errorMessage = "Unable to identify your iCloud account. Please restart the app."
                        isJoining = false
                        return
                    }
                }
                
                // Accept the share via URL
                try await CloudKitManager.shared.acceptShare(from: url)
                
                // CRITICAL: Reload participants AND determine current user
                await appState.loadShareParticipants()
                await appState.determineCurrentUserFromShare()
                
                // Verify that user is now registered
                if !appState.isUserRegistered {
                    errorMessage = "Joined successfully but unable to link account. Check Family tab."
                } else {
                    // Success!
                    joinSuccessMessage = "Successfully joined the family!"
                }
                
                joinLinkText = ""
                isJoining = false
            } catch {
                errorMessage = "Failed to join: \(error.localizedDescription)"
                isJoining = false
            }
        }
    }
}

// MARK: - ShareSheet (UIActivityViewController wrapper)

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

// MARK: - Preview

#Preview {
    FamilySharingView()
        .environmentObject(AppState())
}

