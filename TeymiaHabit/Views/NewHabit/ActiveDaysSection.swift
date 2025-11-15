import SwiftUI

// MARK: - Active Days Section

struct ActiveDaysSection: View {
    @Binding var activeDays: [Bool]
    @Environment(WeekdayPreferences.self) private var weekdayPrefs
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    private var activeDaysDescription: String {
        let allActive = activeDays.allSatisfy { $0 }
        return allActive ? "everyday".localized : "every_week".localized
    }
    
    var body: some View {
        NavigationLink(destination: ActiveDaysSelectionView(activeDays: $activeDays)) {
            HStack {
                Label(
                    title: { Text("active_days".localized) },
                    icon: {
                        Image("calendar.wed")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.gray.gradient)
                    }
                )
                
                Spacer()
                
                Text(activeDaysDescription)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
}

// MARK: - Active Days Selection View

struct ActiveDaysSelectionView: View {
    @Binding var activeDays: [Bool]
    @Environment(\.dismiss) private var dismiss
    @Environment(WeekdayPreferences.self) private var weekdayPrefs
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    private var weekdaySymbols: [String] {
        calendar.orderedFormattedFullWeekdaySymbols
    }
    
    var body: some View {
        List {
            Section {
                Button {
                    withAnimation(.easeInOut) {
                        if activeDays.allSatisfy({ $0 }) {
                            activeDays = [true] + Array(repeating: false, count: 6)
                        } else {
                            activeDays = Array(repeating: true, count: 7)
                        }
                    }
                } label: {
                    HStack {
                        Text("everyday".localized)
                            .tint(.primary)
                        Spacer()
                        Image("check")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .withAppGradient()
                            .opacity(activeDays.allSatisfy({ $0 }) ? 1 : 0)
                            .animation(.easeInOut, value: activeDays.allSatisfy({ $0 }))
                    }
                }
            }
            
            Section(header: Text("select_days".localized)) {
                ForEach(0..<7) { index in
                    Button {
                        withAnimation(.easeInOut) {
                            activeDays[index].toggle()
                        }
                    } label: {
                        HStack {
                            Text(weekdaySymbols[index])
                                .tint(.primary)
                            Spacer()
                            Image("check")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .withAppGradient()
                                .opacity(activeDays[index] ? 1 : 0)
                                .animation(.easeInOut, value: activeDays[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("active_days".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: activeDays) { oldValue, newValue in
            // Prevent deselecting all days
            if newValue.allSatisfy({ !$0 }) {
                activeDays = oldValue
            }
        }
    }
}
