// PhotoGalleryView.swift
// Photo gallery for viewing captured food images

import SwiftUI
import SwiftData

struct PhotoGalleryView: View {
    @ObservedObject var macroEntryStore: MacroEntryStore
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEntry: MacroEntry?
    @State private var showingCleanupAlert = false
    @State private var isCleaningUp = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(macroEntryStore.entriesWithPhotos) { entry in
                        PhotoThumbnail(entry: entry) {
                            selectedEntry = entry
                        }
                    }
                }
                .padding()
                
                if macroEntryStore.entriesWithPhotos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Photos Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Photos from food scans will appear here. Start by taking a photo of your food!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                }
                
                // Storage info section
                if !macroEntryStore.entriesWithPhotos.isEmpty {
                    storageInfoSection
                }
            }
            .navigationTitle("Food Photos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !macroEntryStore.entriesWithPhotos.isEmpty {
                        Button("Cleanup") {
                            showingCleanupAlert = true
                        }
                        .disabled(isCleaningUp)
                    }
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            PhotoDetailView(entry: entry, macroEntryStore: macroEntryStore)
        }
        .alert("Clean Up Old Photos", isPresented: $showingCleanupAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clean Up", role: .destructive) {
                cleanupPhotos()
            }
        } message: {
            Text("This will remove photos older than 7 days to free up storage space. Food entries will be kept, but their photos will be removed.")
        }
        .onAppear {
            // Schedule automatic cleanup when gallery is viewed
            macroEntryStore.scheduleAutomaticPhotoCleanup()
        }
    }
    
    private var storageInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Storage Info")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Photos stored:")
                    Spacer()
                    Text("\(macroEntryStore.totalPhotoCount)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Storage used:")
                    Spacer()
                    Text("\(String(format: "%.1f", macroEntryStore.estimatedPhotoStorageMB)) MB")
                        .fontWeight(.semibold)
                }
                
                Text("Photos older than 7 days are automatically cleaned up to keep your app lightweight.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private func cleanupPhotos() {
        isCleaningUp = true
        Task {
            await macroEntryStore.cleanupOldPhotos()
            isCleaningUp = false
        }
    }
}

// MARK: - Photo Thumbnail

struct PhotoThumbnail: View {
    let entry: MacroEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let imageData = entry.imageData {
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 110, height: 110)
                            .clipped()
                    }
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                
                // Date overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(entry.timestamp, style: .date)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                            .padding(4)
                    }
                }
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Photo Detail View

struct PhotoDetailView: View {
    let entry: MacroEntry
    @ObservedObject var macroEntryStore: MacroEntryStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var showEditSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Full size image
                    if let imageData = entry.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .cornerRadius(12)
                            .shadow(radius: 8)
                    }
                    
                    // Food details
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(entry.foodName)
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Text(entry.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(entry.dayOfEntry)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        // Macro breakdown with serving size
                        VStack(spacing: 12) {
                            HStack {
                                Text("Nutrition Information")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Spacer()
                                
                                // Serving size indicator
                                HStack(spacing: 4) {
                                    Image(systemName: "scalemass")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(entry.servingSize, specifier: "%.1f") \(entry.servingSizeType.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                            }
                            
                            MacroRow(label: "Calories", value: "\(entry.calories)", color: .orange)
                            MacroRow(label: "Protein", value: "\(entry.protein)g", color: .red)
                            MacroRow(label: "Carbs", value: "\(entry.carbs)g", color: .blue)
                            MacroRow(label: "Fats", value: "\(entry.fats)g", color: .green)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Premium editing hint
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14))
                                Text("Tap 'Edit' to adjust nutrition values and serving size")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Food Photo")
            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showEditSheet = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 16))
                                Text("Edit")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(themeManager.primaryColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(themeManager.primaryColor.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .sheet(isPresented: $showEditSheet) {
            EditMacroEntryView(entry: entry, macroEntryStore: macroEntryStore)
        }
    }
}

// MARK: - Macro Row

struct MacroRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    if let container = try? ModelContainer(for: MacroEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) {
        let context = container.mainContext
        let store = MacroEntryStore(modelContext: context)
        
        return PhotoGalleryView(macroEntryStore: store)
            .task {
                await store.addSampleData()
            }
    } else {
        return Text("Failed to create preview")
    }
} 
