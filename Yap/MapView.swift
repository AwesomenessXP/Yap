//
//  MapView.swift
//  Yap
//
//  Created by Jackie Trinh on 2/23/24.
//

import SwiftUI
import MapKit

let yapMapView = MKMapView()
let camera = MKMapCamera()
var interacted: Bool = false
struct DarkModeMapView: UIViewRepresentable {
    var coord2D: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        yapMapView.delegate = context.coordinator
        camera.centerCoordinate = coord2D
        camera.pitch = 0 // Optional: Adjust the pitch (tilt) of the camera
        yapMapView.setRegion(MKCoordinateRegion(center: coord2D, latitudinalMeters: 10000, longitudinalMeters: 10000), animated: false)
        yapMapView.setCamera(camera, animated: false)
        yapMapView.overrideUserInterfaceStyle = .dark
        yapMapView.showsUserLocation = false
        yapMapView.setUserTrackingMode(.none, animated: false)
        yapMapView.setCameraZoomRange(MKMapView.CameraZoomRange.init(minCenterCoordinateDistance: 1800, maxCenterCoordinateDistance: 1800), animated: false)
        return yapMapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        yapMapView.setUserTrackingMode(.follow, animated: true)
    }
    
    func makeCoordinator() -> DarkModeMapCoordinator {
        return DarkModeMapCoordinator(self)
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
                let identifier = "UserRadarLocation"
                var view: MKAnnotationView
                if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? UserLocationAnnotationView {
                    dequeuedView.annotation = annotation
                    view = dequeuedView
                } else {
                    view = UserLocationAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                }
                return view
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            yapMapView.setUserTrackingMode(.follow, animated: true)
        }

    }
}

class UserLocationAnnotationView: MKAnnotationView {
    private var hostingController: UIHostingController<RadarView>?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.canShowCallout = false
        addSwiftUIView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSwiftUIView()
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSwiftUIView() {
        let swiftUIView = RadarView()
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
        .onAppear(perform: {
            performAnimation()
        })
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

struct MapView: View {
    @EnvironmentObject var locationManager: LocationManager
    
    // State to manage the visibility of the Look Around viewer
    @State private var isLookingAround: Bool = false
    
    @State private var lookAroundScene: MKLookAroundScene? = nil
    
    @State var cameraPosition: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: UserDefaults.standard.double(forKey: "latitude"), longitude: UserDefaults.standard.double(forKey: "longitude"))
    
    var body: some View {
        ZStack {
            DarkModeMapView(coord2D: cameraPosition)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    let lat: CLLocationDegrees = UserDefaults.standard.double(forKey: "latitude")
                    let long: CLLocationDegrees = UserDefaults.standard.double(forKey: "longitude")
                    cameraPosition = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    print("\(lat), \(long)")
                    
                    updateLookAroundScene()
            }
            
            // Button to trigger the Look Around viewer
            VStack {
                
                if isLookingAround, let scene = lookAroundScene {
                    LookAroundPreview(initialScene: scene)
                        .frame(width: 400, height: 350) // Specify the desired height here
                        // You can also specify the width, or use .fixedSize() for intrinsic content size
                        .cornerRadius(12)
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        isLookingAround.toggle() // Toggle the visibility state
                    }) {
                        Image(systemName: "binoculars")
                            .padding()
                            .background(Circle().fill(Color.black))
                            .foregroundColor(.white)
                    }
                .padding()
                }
            }
        }
    }
    
    func updateLookAroundScene() {
        // Simulated function to create MKLookAroundScene from current coordinates
        // Adjust based on actual methods to create or fetch an MKLookAroundScene
        let request = MKLookAroundSceneRequest(coordinate: cameraPosition)
        Task {
            do {
                let scene = try await request.scene
                lookAroundScene = scene
            } catch {
                print("Error fetching LookAroundScene: \(error)")
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
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
