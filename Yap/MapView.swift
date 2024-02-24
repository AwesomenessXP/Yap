//
//  MapView.swift
//  Yap
//
//  Created by Jackie Trinh on 2/23/24.
//

import SwiftUI
import MapKit

let mapView = MKMapView()
struct DarkModeMapView: UIViewRepresentable {
    var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.setRegion(region, animated: true)
        mapView.overrideUserInterfaceStyle = .dark
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
    }
    
    func makeCoordinator() -> DarkModeMapCoordinator {
        DarkModeMapCoordinator(self)
    }
    
    class DarkModeMapCoordinator: NSObject, Observable, ObservableObject, MKMapViewDelegate {
        var parent: DarkModeMapView
        var headingImageView: UIImageView? = nil
        
        init(_ parent: DarkModeMapView) {
            self.parent = parent
            super.init()
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                let identifier = "SwiftUIAnnotation"
                var view: MKAnnotationView
                if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? SwiftUIAnnotationView {
                    dequeuedView.annotation = annotation
                    view = dequeuedView
                } else {
                    view = SwiftUIAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }
                return view
            }
            return nil
        }

    }
}

class SwiftUIAnnotationView: MKAnnotationView {
    private var hostingController: UIHostingController<RadarView>?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = false
        addSwiftUIView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSwiftUIView() {
        let swiftUIView: RadarView = RadarView()
        let radarView = swiftUIView as RadarView
        hostingController = UIHostingController(rootView: radarView)
        
        guard let hostingView = hostingController?.view else { return }
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingView)
        
        hostingView.backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            hostingView.widthAnchor.constraint(equalTo: widthAnchor),
            hostingView.heightAnchor.constraint(equalTo: heightAnchor),
            hostingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            hostingView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}


// Extensions for custom colors, gradients, and shapes remain unchanged
extension Color {
    static var customBackgroundColor: Color {
        Color(red: 237.0/255.0, green: 237.0/255.0, blue: 234.0/255.0)
    }
    
    static var customBlueColor: Color {
        Color(red: 81.0/255.0, green: 142.0/255.0, blue: 210/255.0)
    }
}

extension RadialGradient {
    static var customRadialGradient: RadialGradient {
        RadialGradient(gradient: Gradient(colors: [Color.customBlueColor.opacity(0.2), Color.customBackgroundColor.opacity(0.1)]), center: .center, startRadius: 90, endRadius: -10)
    }
}

extension AngularGradient {
    static var customAngularGradient: AngularGradient {
        AngularGradient(gradient:  Gradient(colors: [Color.blue, Color.customBackgroundColor.opacity(0.05)]), center: .center, startAngle: .degrees(90), endAngle: .degrees(-250))
    }
}

struct RadarView: View {
    @State var startAnimation = false
    @State var fadeAnimation1 = false
    @State var fadeAnimation2 = false
    @State var fadeAnimation3 = false

    var body: some View {
        ZStack {
//            ZStack {
//                Circle()
//                    .foregroundColor(Color.customBlueColor)
//                    .opacity(fadeAnimation1 ? 1.0 : 0.1)
//                    .frame(width: 5)
//                    .offset(x: 50, y: 0)
//                    .rotationEffect(.degrees(45))
//                Circle()
//                    .foregroundColor(Color.customBlueColor)
//                    .opacity(fadeAnimation2 ? 1.0 : 0.1)
//                    .frame(width: 10)
//                    .offset(x: 40, y: 0)
//                    .rotationEffect(.degrees(-125))
//                Circle()
//                    .foregroundColor(Color.customBlueColor)
//                    .opacity(fadeAnimation3 ? 1.0 : 0.1)
//                    .frame(width: 14)
//                    .offset(x: 60, y: 0)
//                    .rotationEffect(.degrees(-35))
//            }
            ZStack {
                Circle()
                    .strokeBorder(.gray, lineWidth: 0.3)
                    .frame(width: 60)
                Circle()
                    .strokeBorder(.gray, lineWidth: 0.3)
                    .frame(width: 130)
                Circle()
                    .strokeBorder(.gray, lineWidth: 0.3)
                    .frame(width: 200)
                Circle()
                    .fill(RadialGradient.customRadialGradient)
                    .frame(width: 200)
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 1, height: 200, alignment: .center)
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(width: 1, height: 200, alignment: .center)
                    .rotationEffect(.degrees(90))
                QuadCircle(start: .degrees(100), end: .degrees(270))
                    .fill(AngularGradient.customAngularGradient)
                    .frame(width: 200)
                    .rotationEffect(.degrees(startAnimation ? 360 : 0))
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.customBlueColor)
                    .frame(width: 5, height: 100, alignment: .center)
                    .offset(y: -50)
                    .rotationEffect(.degrees(startAnimation ? 360 : 0))
            }
            Circle()
                .fill(Color.customBlueColor)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(Color.white, lineWidth: 1))
        }
        .onAppear(perform: performAnimation)
    }
    
    private func performAnimation() {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            startAnimation = true
        }
        
        withAnimation(.linear(duration: 0.7)
            .delay((1.5/360) * (90 - 105))
            .repeatForever(autoreverses: true)) {
            fadeAnimation1 = true
        }
        
        withAnimation(.easeInOut(duration: 0.7)
            .delay((1.5/360) * (90 - 80))
            .repeatForever(autoreverses: true)) {
            fadeAnimation2 = true
        }
        
        withAnimation(.linear(duration: 0.5)
            .delay((1.5/360) * (90 - 25))
            .repeatForever(autoreverses: true)) {
            fadeAnimation3 = true
        }
    }
}

// Add QuadCircle struct here as it's part of RadarView dependencies

// Now merging the ContentView with MapView and RadarAnimation
// ContentView struct now uses DarkModeMapView for the map
struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State var cameraPosition: MKCoordinateRegion? = .userRegion
    
    // Radar animation state variables
    @State var startAnimation = false
    @State var fadeAnimation1 = false
    @State var fadeAnimation2 = false
    @State var fadeAnimation3 = false
    
    var body: some View {
        ZStack {
            if let cameraPosition = cameraPosition {
                DarkModeMapView(region: cameraPosition)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear() {
            if let coords = locationManager.location?.last?.coordinate {
                cameraPosition = MKCoordinateRegion(
                    center: coords,
                    latitudinalMeters: 100,
                    longitudinalMeters: 100
                )
            }
        }
    }
}

extension CLLocationCoordinate2D {
    static var userLocation: CLLocationCoordinate2D {
        let lat: CLLocationDegrees = UserDefaults.standard.double(forKey: "latitude")
        let long: CLLocationDegrees = UserDefaults.standard.double(forKey: "longitude")
        return .init(latitude: lat, longitude: long) // User's location
    }
}

extension MKCoordinateRegion {
    static var userRegion: MKCoordinateRegion {
        mapView.setCenter(.userLocation, animated: true)
        return .init(center: .userLocation, latitudinalMeters: 100, longitudinalMeters: 100)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LocationManager())
    }
}

struct QuadCircle: Shape {
    var start: Angle
    var end: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(center: center, radius: rect.midX, startAngle: start, endAngle: end, clockwise: false)
        return path
    }
}

