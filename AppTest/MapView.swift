import SwiftUI
import MapKit

struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 32.3574, longitude: -82.9071),
        span: MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6)
    )
    
    @State private var selectedRectangle: MKMapRect?
    @State private var isSelecting = false
    @State private var startPoint: CGPoint?
    @State private var endPoint: CGPoint?
    @State private var showingSoilPopup = false
    @State private var soilData: [SoilDataService.MapUnit] = []
    @State private var isLoading = false
    
    private let soilService = SoilDataService()
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, interactionModes: isSelecting ? [] : [.pan, .zoom])
                .mapStyle(.hybrid)
                .frame(width: 600, height: 650)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isSelecting {
                                isSelecting = true
                                startPoint = value.startLocation
                            }
                            endPoint = value.location
                        }
                        .onEnded { value in
                            defer {
                                isSelecting = false
                                startPoint = nil
                                endPoint = nil
                            }
                            guard let start = startPoint, let end = endPoint else { return }
                            let rect = createMapRect(from: start, to: end)
                            selectedRectangle = rect
                            //AIManager.generate()
                            fetchSoilData(for: rect)
                        }
                )
            
            // Selection rectangle overlay
            if isSelecting, let start = startPoint, let end = endPoint {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .fill(Color.blue.opacity(0.2))
                    .frame(
                        width: abs(end.x - start.x),
                        height: abs(end.y - start.y)
                    )
                    .position(
                        x: (start.x + end.x) / 2,
                        y: (start.y + end.y) / 2
                    )
            }
            
            // Loading indicator
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading soil data...")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showingSoilPopup) {
            SoilDataPopup(soilData: soilData)
                .frame(minWidth: 600, minHeight: 500)
        }
    }
    
    private func createMapRect(from start: CGPoint, to end: CGPoint) -> MKMapRect {
        let minX = min(start.x, end.x)
        let maxX = max(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxY = max(start.y, end.y)
        
        let topLeft = CGPoint(x: minX, y: minY)
        let bottomRight = CGPoint(x: maxX, y: maxY)
        
        let topLeftCoord = coordinateFromPoint(topLeft)
        let bottomRightCoord = coordinateFromPoint(bottomRight)
        
        return MKMapRect(
            origin: MKMapPoint(topLeftCoord),
            size: MKMapSize(
                width: MKMapPoint(bottomRightCoord).x - MKMapPoint(topLeftCoord).x,
                height: MKMapPoint(bottomRightCoord).y - MKMapPoint(topLeftCoord).y
            )
        )
    }
    
    private func coordinateFromPoint(_ point: CGPoint) -> CLLocationCoordinate2D {
        // Convert screen point to coordinate using the current map region
        let mapWidth: CGFloat = 600.0
        let mapHeight: CGFloat = 650.0
        
        // Calculate the normalized position (0 to 1) within the map view
        let normalizedX = point.x / mapWidth
        let normalizedY = point.y / mapHeight
        
        // Convert to latitude/longitude using the map region
        // Note: longitude increases left to right, latitude decreases top to bottom
        let lon = region.center.longitude - (region.span.longitudeDelta / 2) + (Double(normalizedX) * region.span.longitudeDelta)
        let lat = region.center.latitude + (region.span.latitudeDelta / 2) - (Double(normalizedY) * region.span.latitudeDelta)
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    private func fetchSoilData(for rect: MKMapRect) {
        isLoading = true
        
        // Calculate the actual center of the rectangle
        let centerPoint = MKMapPoint(x: rect.origin.x + rect.size.width / 2,
                                      y: rect.origin.y + rect.size.height / 2)
        let center = centerPoint.coordinate
        
        // Get the corner coordinates to calculate actual distance
        let topLeft = MKMapPoint(x: rect.origin.x, y: rect.origin.y).coordinate
        let bottomRight = MKMapPoint(x: rect.origin.x + rect.size.width,
                                      y: rect.origin.y + rect.size.height).coordinate
        
        // Calculate actual distance in meters using CLLocation
        let topLeftLocation = CLLocation(latitude: topLeft.latitude, longitude: topLeft.longitude)
        let bottomRightLocation = CLLocation(latitude: bottomRight.latitude, longitude: bottomRight.longitude)
        let diagonalDistance = topLeftLocation.distance(from: bottomRightLocation)
        
        // Use diagonal / sqrt(2) to get approximate side length
        let sideLength = diagonalDistance / sqrt(2.0)
        
        print("DEBUG: Querying center: \(center.latitude), \(center.longitude)")
        print("DEBUG: Side length (meters): \(sideLength)")
        
        soilService.getSoilComposition(
            centerLatitude: center.latitude,
            centerLongitude: center.longitude,
            sideLengthMeters: sideLength
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let data):
                    soilData = data
                    showingSoilPopup = true
                case .failure(let error):
                    soilData = []
                    showingSoilPopup = true
                }
            }
        }
    }
}

struct SoilDataPopup: View {
    let soilData: [SoilDataService.MapUnit]
    @Environment(\.dismiss) private var dismiss
    @State private var showMinorSoils = false
    
    private var majorSoils: [SoilDataService.MapUnit] {
        soilData.filter { $0.component_pct_of_aoi >= 5.0 }
    }
    
    private var minorSoils: [SoilDataService.MapUnit] {
        soilData.filter { $0.component_pct_of_aoi < 5.0 }
    }
    
    private var totalMinorPercentage: Double {
        minorSoils.reduce(0) { $0 + $1.component_pct_of_aoi }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                if soilData.isEmpty {
                    Text("No soil data found for this area")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("Soil Composition")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            // Major soils (>= 5%)
                            ForEach(Array(majorSoils.enumerated()), id: \.offset) { index, unit in
                                SoilUnitView(unit: unit)
                            }
                            
                            // Minor soils group
                            if !minorSoils.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Button(action: {
                                        showMinorSoils.toggle()
                                    }) {
                                        HStack {
                                            Text("Minor Soils (\(String(format: "%.1f", totalMinorPercentage))%)")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: showMinorSoils ? "chevron.down" : "chevron.right")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if showMinorSoils {
                                        ForEach(Array(minorSoils.enumerated()), id: \.offset) { index, unit in
                                            SoilUnitView(unit: unit)
                                                .padding(.leading, 16)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Soil Data")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SoilUnitView: View {
    let unit: SoilDataService.MapUnit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(unit.muname)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(unit.taxclname)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Spacer()
                
                Text("\(String(format: "%.1f", unit.component_pct_of_aoi))% of AOI")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .cornerRadius(8)
    }
}

#Preview {
    MapView()
}
