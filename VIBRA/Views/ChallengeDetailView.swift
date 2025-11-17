// ChallengeDetailView.swift
// VIBRA
//
// Created by mac book pro on 11/10/25.
//*
/*
import SwiftUI
import MapKit

// MARK: - Main View
struct ChallengeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Données statiques pour le challenge
    let challenge = Challenge(
        startDate: "15/10/2025",
        endDate: "15/10/2025",
        weather: "18.7 °C",
        time: "1h 45min",
        distance: "36.1 km",
        difficulty: 3,
        participants: [
            Participant(name: "Yassine Ben Ali", age: 25, level: "Intermediate", email: "yassine@fakedomain.net"),
            Participant(name: "Amira Gharbi", age: 22, level: "Beginner", email: "amira@fakedomain.net"),
            Participant(name: "Karim Trabelsi", age: 28, level: "Advance", email: "karim@fakedomain.net"),
            Participant(name: "Sami Jaziri", age: 30, level: "Expert", email: "dpjark@gmail.com")
        ],
        numberOfParticipants: 12,
        coordinates: [
            CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815),
            CLLocationCoordinate2D(latitude: 36.8165, longitude: 10.1915),
            CLLocationCoordinate2D(latitude: 36.8265, longitude: 10.1715)
        ]
    )
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 16) {
                    headerView
                    mapSection
                    infoSection
                    difficultySection
                    participantsSection
                    participateButton
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
            Spacer()
            Text("Challenge")
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "calendar")
                .foregroundColor(.white)
                .padding(8)
                .background(Color.gray.opacity(0.3))
                .clipShape(Circle())
        }
        .padding()
    }
    
    // MARK: - Map Section
    private var mapSection: some View {
        ChallengeMapView(coordinates: challenge.coordinates)
            .frame(height: 250)
            .cornerRadius(12)
            .overlay(
                Button(action: {
                    // Action vers détails du parcours
                }) {
                    Image(systemName: "map.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .clipShape(Circle())
                }
                .offset(x: 120, y: 100)
            )
            .padding(.horizontal)
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        HStack(spacing: 10) {
            InfoCard(title: "Weather", value: challenge.weather)
            InfoCard(title: "Time", value: challenge.time)
            InfoCard(title: "Distance", value: challenge.distance)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Difficulty Section
    private var difficultySection: some View {
        HStack {
            Text("Difficulty")
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= challenge.difficulty ? "star.fill" : "star")
                        .foregroundColor(index <= challenge.difficulty ? .yellow : .gray)
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Participants Section
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Number of participants: \(challenge.numberOfParticipants)")
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    // Voir tous les participants
                }) {
                    Text("View all")
                        .foregroundColor(.green)
                }
            }
            ForEach(challenge.participants.prefix(4)) { participant in
                ParticipantRow(participant: participant)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Participate Button
    private var participateButton: some View {
        Button(action: {
            // Participer au challenge
        }) {
            Text("Participate")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.8))
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Models
struct Challenge {
    let startDate: String
    let endDate: String
    let weather: String
    let time: String
    let distance: String
    let difficulty: Int
    let participants: [Participant]
    let numberOfParticipants: Int
    let coordinates: [CLLocationCoordinate2D]
}
/*
struct Participant: Identifiable {
    var id: String { email }
    let name: String
    let age: Int
    let level: String
    let email: String
}*/

// MARK: - MapPoint Identifiable
struct MapPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let index: Int
}

// MARK: - MapView
struct ChallengeMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    
    @State private var region: MKCoordinateRegion
    
    private var points: [MapPoint] {
        coordinates.enumerated().map { MapPoint(coordinate: $0.element, index: $0.offset + 1) }
    }
    
    init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
        if let first = coordinates.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion())
        }
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: points) { point in
            MapAnnotation(coordinate: point.coordinate) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .overlay(Text("\(point.index)").font(.caption).foregroundColor(.white))
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
    }
}

// MARK: - InfoCard
struct InfoCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title.capitalized)
                .font(.caption)
                .foregroundColor(.green)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
}

// MARK: - ParticipantRow
struct ParticipantRow: View {
    let participant: Participant
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.gray)
                .font(.system(size: 40))
            VStack(alignment: .leading) {
                Text(participant.name)
                    .foregroundColor(.white)
                    .font(.subheadline)
                Text("-\(participant.age) yo - \(participant.level)")
                    .foregroundColor(.gray)
                    .font(.caption)
                Text(participant.email)
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            Spacer()
        }
    }
}

// MARK: - Preview
struct ChallengeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeDetailView()
    }
}
*/
