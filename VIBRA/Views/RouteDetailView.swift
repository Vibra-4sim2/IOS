import SwiftUI
import MapKit
import Charts

struct RouteDetailView: View {
    var coordinate: CLLocationCoordinate2D
    
    @State private var region: MKCoordinateRegion
    @State private var showDetails = false
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    struct IdentifiableCoordinate: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
    
    var body: some View {
        ZStack {
            // MARK: - Map
            Map(coordinateRegion: $region, annotationItems: [IdentifiableCoordinate(coordinate: coordinate)]) { item in
                MapMarker(coordinate: item.coordinate, tint: .red)
            }
            .ignoresSafeArea()
            
            // MARK: - Top Buttons
            VStack {
                HStack {
                    CircleButton(icon: "chevron.left") {
                        // Action retour
                    }
                    Spacer()
                    CircleButton(icon: "gearshape") {
                        // Action paramètres
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
            }
            
            // MARK: - Floating Buttons
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    CircleButton(icon: "plus.magnifyingglass") {}
                    CircleButton(icon: "minus.magnifyingglass") {}
                    CircleButton(icon: "mappin") {}
                }
                .padding(.trailing, 20)
                .padding(.bottom, 150)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // MARK: - Details Panel
            VStack {
                Spacer()
                
                if showDetails {
                    VStack(spacing: 16) {
                        // Première ligne
                        HStack(spacing: 12) {
                            DetailCard(title: "Departure", value: "Belvedere Park", icon: "figure.walk")
                            DetailCard(title: "Arrival", value: "Lake Tuins", icon: "flag.checkered")
                        }
                        HStack(spacing: 12) {
                            DetailCard(title: "Weather", value: "Sunny, 23°", icon: "sun.max")
                            DetailCard(title: "Duration", value: "1h 45min", icon: "clock")
                        }
                        HStack(spacing: 12) {
                            DetailCard(title: "Distance", value: "32.4 km", icon: "ruler")
                            DetailCard(title: "Elevation", value: "150 m", icon: "mountain.2")
                        }
                        
                        // Performance
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Performance: Average")
                                .foregroundStyle(.white.opacity(0.8))
                                .font(.subheadline)
                            PerformanceChart()
                                .frame(height: 120)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(12)
                        }
                        
                        // Dernière ligne
                        HStack(spacing: 12) {
                            DetailCard(title: "Calories", value: "450 kcal", icon: "flame")
                            DetailCard(title: "Speed", value: "27 km/h", icon: "bolt")
                        }
                        
                        // Bouton paramètre bas
                        HStack {
                            Spacer()
                            CircleButton(icon: "gearshape.fill") {}
                        }
                    }
                    .padding()
                    .background(BlurView(style: .systemThinMaterialDark).opacity(0.9))
                    .cornerRadius(25)
                    .shadow(radius: 10)
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: showDetails)
                }
                
                // Bouton show details
                Button(action: {
                    withAnimation(.spring()) {
                        showDetails.toggle()
                    }
                }) {
                    Text(showDetails ? "Hide details" : "Show details")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 30)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(20)
                        .padding(.bottom, 30)
                }
            }
        }
    }
}

// MARK: - DetailCard (ancien InfoCard)
struct DetailCard: View {
    var title: String
    var value: String
    var icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.8))
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .cornerRadius(15)
    }
}

// MARK: - CircleButton
struct CircleButton: View {
    var icon: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
}

// MARK: - Blur Effect
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Performance Chart
struct PerformanceChart: View {
    let data = [
        (day: "Mon", value: 20),
        (day: "Tue", value: 45),
        (day: "Wed", value: 30),
        (day: "Thu", value: 50),
        (day: "Fri", value: 35)
    ]
    
    var body: some View {
        Chart {
            ForEach(data, id: \.day) { item in
                LineMark(
                    x: .value("Day", item.day),
                    y: .value("Performance", item.value)
                )
                .foregroundStyle(.blue.gradient)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .symbol(Circle().strokeBorder(lineWidth: 2))
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
    }
}

#Preview {
    RouteDetailView(coordinate: CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815))
}
