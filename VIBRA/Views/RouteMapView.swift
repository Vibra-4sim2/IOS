// filepath: /Users/mohamedmami/Documents/IOS/VIBRA/Views/RouteMapView.swift
import SwiftUI
import MapKit
import CoreLocation

struct RouteMapView: UIViewRepresentable {
    var routeCoordinates: [CLLocationCoordinate2D]
    var startCoordinate: CLLocationCoordinate2D
    var endCoordinate: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator
        map.pointOfInterestFilter = .excludingAll
        map.showsCompass = false
        map.isRotateEnabled = false
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)

        // Start pin
        let startPin = MKPointAnnotation()
        startPin.coordinate = startCoordinate
        startPin.title = "Départ"
        uiView.addAnnotation(startPin)
        
        // End pin
        let endPin = MKPointAnnotation()
        endPin.coordinate = endCoordinate
        endPin.title = "Arrivée"
        uiView.addAnnotation(endPin)

        if routeCoordinates.count > 1 {
            let poly = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            uiView.addOverlay(poly)
            uiView.setVisibleMapRect(poly.boundingMapRect, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: false)
        } else {
            var rect = MKMapRect.null
            [startCoordinate, endCoordinate].forEach { coord in
                let point = MKMapPoint(coord)
                let r = MKMapRect(x: point.x, y: point.y, width: 0, height: 0)
                rect = rect.union(r)
            }
            uiView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: false)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, MKMapViewDelegate {
        let parent: RouteMapView
        init(_ parent: RouteMapView) { self.parent = parent }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: polyline)
                r.strokeColor = UIColor.systemGreen
                r.lineWidth = 5
                r.lineJoin = .round
                r.lineCap = .round
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
