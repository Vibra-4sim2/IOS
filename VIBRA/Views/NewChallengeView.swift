import SwiftUI
import MapKit

// MARK: - Identifiable Route Point
struct RoutePoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - NewChallengeView
struct NewChallengeView: View {
    // MARK: - States
    @State private var departureDate = Date()
    @State private var departureTime = Date()
    @State private var arrivalDate = Date()
    @State private var arrivalTime = Date()
    @State private var showSuggestedRoute = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    // MARK: - Data
    private let routePoints: [RoutePoint] = [
        RoutePoint(coordinate: CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815)),
        RoutePoint(coordinate: CLLocationCoordinate2D(latitude: 36.8080, longitude: 10.1900)),
        RoutePoint(coordinate: CLLocationCoordinate2D(latitude: 36.8100, longitude: 10.2000))
    ]

    // MARK: - View
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Header
                HStack {
                    Text("new challenge")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {}) {
                        Text("×")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)

                // MARK: - Input fields
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("departure")
                            .foregroundColor(.gray)
                        DatePicker("", selection: $departureDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .foregroundColor(.white)
                        DatePicker("", selection: $departureTime, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("arrival")
                            .foregroundColor(.gray)
                        DatePicker("", selection: $arrivalDate, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .foregroundColor(.white)
                        DatePicker("", selection: $arrivalTime, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }

                // MARK: - Map section
                ZStack {
                    Map(coordinateRegion: $region, annotationItems: showSuggestedRoute ? routePoints : []) { point in
                        MapPin(coordinate: point.coordinate, tint: .green)
                    }
                    .frame(height: 280)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2)))

                    VStack {
                        Spacer()
                        Button(action: { showSuggestedRoute.toggle() }) {
                            Text(showSuggestedRoute ? "Hide Route" : "suggest a route")
                                .fontWeight(.semibold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                                .padding(.horizontal, 40)
                                .shadow(radius: 6)
                        }
                        Spacer().frame(height: 10)
                    }

                    VStack {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                MapControlButton(icon: "➕")
                                MapControlButton(icon: "➖")
                                MapControlButton(icon: "📍")
                            }
                            .padding(.trailing, 10)
                            .padding(.top, 10)
                        }
                        Spacer()
                    }
                }

                // MARK: - Info section
                HStack(spacing: 20) {
                    VStack {
                        Text("weather")
                            .foregroundColor(.gray)
                        Text("187°C")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)

                    VStack {
                        Text("Time")
                            .foregroundColor(.gray)
                        Text("1h 45min")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)

                    VStack {
                        Text("Distance")
                            .foregroundColor(.gray)
                        Text("36.1 km")
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }

                // MARK: - Create button
                Button(action: {
                    print("Challenge Created ✅")
                }) {
                    Text("create")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - MapControlButton
struct MapControlButton: View {
    var icon: String

    var body: some View {
        Button(action: {}) {
            Text(icon)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview
#Preview {
    NewChallengeView()
}
