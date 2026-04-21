import MapKit
import SwiftUI

struct CommuteMapView: View {
    let route: MKRoute?

    private static let origin      = CLLocationCoordinate2D(latitude: 37.6290, longitude: -122.4212)
    private static let destination = CLLocationCoordinate2D(latitude: 37.7879, longitude: -122.3934)

    // Centers the camera between origin and destination with enough padding to show both pins.
    private static let initialRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.709, longitude: -122.407),
        span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.18)
    )

    var body: some View {
        ZStack {
            Map(initialPosition: .region(Self.initialRegion)) {
                if let polyline = route?.polyline {
                    MapPolyline(polyline)
                        .stroke(
                            Color(hex: "FD5A1E").opacity(0.9),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                        )
                }

                Annotation("", coordinate: Self.origin, anchor: .center) {
                    PinView(color: Color(hex: "FD5A1E"), systemImage: "building.2.fill")
                }

                Annotation("", coordinate: Self.destination, anchor: .center) {
                    PinView(color: Color(hex: "27251F"), systemImage: "mappin.circle.fill")
                }
            }
            .mapStyle(.standard)
            .environment(\.colorScheme, .dark)
            .mapControls { }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Skeleton shimmer while route is loading
            if route == nil {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "1A1A1A").opacity(0.75))
                    .frame(height: 260)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "map")
                                .font(.system(size: 28))
                                .foregroundStyle(Color(hex: "444444"))
                            Text("Loading route…")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "444444"))
                        }
                    }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openInMaps()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
    }

    private func openInMaps() {
        let originItem = MKMapItem(placemark: MKPlacemark(coordinate: Self.origin))
        originItem.name = "San Bruno (YouTube HQ)"

        let destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: Self.destination))
        destinationItem.name = "333 Beale St, SF"

        MKMapItem.openMaps(
            with: [originItem, destinationItem],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }
}

// MARK: - Pin

private struct PinView: View {
    let color: Color
    let systemImage: String

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "0D0D0D").ignoresSafeArea()
        CommuteMapView(route: nil)
    }
}
