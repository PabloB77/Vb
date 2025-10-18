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
    @State private var showingSoilDataPopup = false
    @State private var soilData: [SoilDataService.MapUnit] = []
    @State private var isLoading = false
    
    private let soilService = SoilDataService()
    
    var body: some View {
        let modes: MapInteractionModes = isSelecting ? [] : [.pan, .zoom]
        ZStack {
            Map(coordinateRegion: $region, interactionModes: modes)
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
                            fetchSoilData(for: rect)
                        }
                )
            
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
            SoilSelectionPopup(soilData: soilData, selectedRectangle: selectedRectangle, showingSoilDataPopup: $showingSoilDataPopup)
                .frame(minWidth: 500, minHeight: 600)
        }
        .sheet(isPresented: $showingSoilDataPopup) {
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
        let mapWidth: CGFloat = 600.0
        let mapHeight: CGFloat = 650.0
        
        let normalizedX = point.x / mapWidth
        let normalizedY = point.y / mapHeight
        
        let lon = region.center.longitude - (region.span.longitudeDelta / 2) + (Double(normalizedX) * region.span.longitudeDelta)
        let lat = region.center.latitude + (region.span.latitudeDelta / 2) - (Double(normalizedY) * region.span.latitudeDelta)
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    private func fetchSoilData(for rect: MKMapRect) {
        isLoading = true
        
        let centerPoint = MKMapPoint(x: rect.origin.x + rect.size.width / 2,
                                      y: rect.origin.y + rect.size.height / 2)
        let center = centerPoint.coordinate
        
        let topLeft = MKMapPoint(x: rect.origin.x, y: rect.origin.y).coordinate
        let bottomRight = MKMapPoint(x: rect.origin.x + rect.size.width,
                                      y: rect.origin.y + rect.size.height).coordinate
        
        let topLeftLocation = CLLocation(latitude: topLeft.latitude, longitude: topLeft.longitude)
        let bottomRightLocation = CLLocation(latitude: bottomRight.latitude, longitude: bottomRight.longitude)
        let diagonalDistance = topLeftLocation.distance(from: bottomRightLocation)
        
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
                    for unit in data.prefix(10) {
                        print("Soil: \(unit.muname) | Taxonomy: \(unit.taxclname) | %AOI: \(String(format: "%.1f", unit.component_pct_of_aoi))")
                    }
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

struct SoilSelectionPopup: View {
    let soilData: [SoilDataService.MapUnit]
    let selectedRectangle: MKMapRect?
    @Binding var showingSoilDataPopup: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var soilDescription = ""
    @State private var aiOutput = ""
    @State private var isGeneratingDescription = false
    @State private var isGenerating = false
    @State private var hasStartedDescription = false
    @State private var hasStartedAnalysis = false
    @State private var growingZone = ""
    @State private var isLoadingZone = false
    @State private var cropRecommendations = ""
    @State private var isGeneratingCrops = false
    @State private var hasStartedCrops = false
    @State private var parsedSoilData: ParsedSoilData?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if soilData.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("No soil data found for this area")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Try selecting a different area on the map")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if !growingZone.isEmpty {
                                Text("USDA Growing Zone: \(growingZone)")
                                    .font(.headline)
                                    .padding()
                            }
                            
                            if isLoadingZone {
                                Text("Loading growing zone...")
                            }
                            
                            if !soilDescription.isEmpty {
                                Text(soilDescription)
                                    .padding()
                            }
                            
                            if isGeneratingDescription {
                                Text("Generating description...")
                            }
                            
                            if !aiOutput.isEmpty {
                                Text(aiOutput)
                                    .padding()
                            }
                            
                            if isGenerating {
                                Text("Generating analysis...")
                            }
                            
                            if !cropRecommendations.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Crop Recommendations")
                                        .font(.headline)
                                    Text(cropRecommendations)
                                        .textSelection(.enabled)
                                }
                                .padding()
                            }
                            
                            if isGeneratingCrops {
                                Text("Generating crop recommendations...")
                            }
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        showingSoilDataPopup = true
                                    }
                                }) {
                                    Text("View Soil Details")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button(action: {
                                    generateCropRecommendations()
                                }) {
                                    Text("Get Crop Recommendations")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(isGeneratingCrops || parsedSoilData == nil || growingZone.isEmpty)
                            }
                            .padding()
                        }
                    }
                }
            }
            .padding(32)
            .navigationTitle("Area Selected")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            fetchGrowingZone()
            generateSoilDescription()
        }
    }
    
    private func fetchGrowingZone() {
        isLoadingZone = true
        
        guard let rect = selectedRectangle else {
            isLoadingZone = false
            return
        }
        
        let centerPoint = MKMapPoint(x: rect.origin.x + rect.size.width / 2,
                                      y: rect.origin.y + rect.size.height / 2)
        let center = centerPoint.coordinate
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoadingZone = false
                    return
                }
                
                guard let placemarks = placemarks, let placemark = placemarks.first,
                      let zipCode = placemark.postalCode else {
                    self.isLoadingZone = false
                    return
                }
                
                self.fetchZoneFromAPI(zipCode: zipCode)
            }
        }
    }
    
    private func fetchZoneFromAPI(zipCode: String) {
        guard let url = URL(string: "https://phzmapi.org/\(zipCode).json") else {
            isLoadingZone = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoadingZone = false
                
                if let error = error {
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let zone = json["zone"] as? String else {
                    return
                }
                
                self.growingZone = zone
            }
        }.resume()
    }
    
    private func generateSoilDescription() {
        isGeneratingDescription = true
        soilDescription = ""
        
        let soilDataString = soilData.map { unit in
            "Soil: \(unit.muname) | Taxonomy: \(unit.taxclname) | % composition: \(String(format: "%.1f", unit.component_pct_of_aoi))"
        }.joined(separator: "\n")
        
        let prompt1_ = """
You are an expert gardener and soil specialist. Based on the following soil data, write a short, easy-to-understand description. Avoid scientific or technical terms — describe what the soil is like, how it might behave, and what kind of plants or uses it's suitable for. Focus on texture, drainage, fertility, and general landscape characteristics. Follow the rules EXACTLY:\n\n\(soilDataString) Rules:
Output must be 5 sentences
DO NOT begin with anything other than the description
No headers, introductions or conclusions; just the task required dense with info
Goal: Write one brief paragraph summarizing the overall landscape and soil qualities in plain language.
"""
        
        AIManager.generateNVidiaStreamingLiveGeneric(soilData: prompt1_) { chunk in
            DispatchQueue.main.async {
                if !hasStartedDescription {
                    if chunk.contains("\n") {
                        hasStartedDescription = true
                        let lines = chunk.components(separatedBy: "\n")
                        if lines.count > 1 {
                            soilDescription = lines.dropFirst().joined(separator: "\n")
                        }
                    }
                } else {
                    soilDescription += chunk
                }
            }
        } completion: { result in
            DispatchQueue.main.async {
                isGeneratingDescription = false
                if case .success = result {
                    generateSoilAnalysis()
                }
            }
        }
    }
    
    private func generateSoilAnalysis() {
        isGenerating = true
        aiOutput = ""
        
        let soilDataString = soilData.map { unit in
            "Soil: \(unit.muname) | Taxonomy: \(unit.taxclname) | % composition: \(String(format: "%.1f", unit.component_pct_of_aoi))"
        }.joined(separator: "\n")
        
        AIManager.generateNVidiaStreamingLive(soilData: soilDataString) { chunk in
            DispatchQueue.main.async {
                if !hasStartedAnalysis {
                    if chunk.contains("\n") {
                        hasStartedAnalysis = true
                        let lines = chunk.components(separatedBy: "\n")
                        if lines.count > 1 {
                            aiOutput = lines.dropFirst().joined(separator: "\n")
                        }
                    }
                } else {
                    aiOutput += chunk
                }
            }
        } completion: { result in
            DispatchQueue.main.async {
                isGenerating = false
                switch result {
                case .success:
                    parseSoilData()
                case .failure:
                    if aiOutput.isEmpty {
                        aiOutput = "Error generating analysis"
                    }
                }
            }
        }
    }
    
    private func parseSoilData() {
        let lines = aiOutput.components(separatedBy: "\n")
        var parsed = ParsedSoilData()
        
        for line in lines {
            let components = line.components(separatedBy: ": ")
            guard components.count == 2 else { continue }
            
            let key = components[0].trimmingCharacters(in: .whitespaces).lowercased()
            let value = components[1].trimmingCharacters(in: .whitespaces)
            
            switch key {
            case "porosity":
                parsed.porosity = value
            case "organic matter":
                parsed.organicMatter = value
            case "soil texture":
                parsed.soilTexture = value
            case "ph (estimated)":
                parsed.pH = value
            case "drainage":
                parsed.drainage = value
            case "color (estimated)":
                parsed.color = value
            default:
                break
            }
        }
        
        parsedSoilData = parsed
    }
    
    private func generateCropRecommendations() {
        guard let parsed = parsedSoilData, !growingZone.isEmpty else { return }
        
        isGeneratingCrops = true
        cropRecommendations = ""
        
        let dominantSoil = soilData.max(by: { $0.component_pct_of_aoi < $1.component_pct_of_aoi })
        
        let areaInAcres: Double
        if let rect = selectedRectangle {
            let areaInSquareMeters = rect.size.width * rect.size.height
            areaInAcres = areaInSquareMeters * 0.000247105
        } else {
            areaInAcres = 0
        }
        
        let soilDescriptionList = soilData.map { unit in
            "Soil: \(unit.muname) | Taxonomy: \(unit.taxclname) | % composition: \(String(format: "%.1f", unit.component_pct_of_aoi))"
        }.joined(separator: "\n")
        
        let prompt = """
You are an agricultural economist and agronomist specializing in high-value crop selection for specific soil profiles and market opportunities.

SOIL PROFILE:

\(soilDescriptionList)

\(dominantSoil?.taxclname ?? "Unknown")

FARM CONTEXT:

Total acreage: \(String(format: "%.1f", areaInAcres)) acres

USDA Hardiness Zone: \(growingZone)

TASK:

Recommend 10 profitable crops specifically suited to this soil profile. Prioritize crops that:

SOIL COMPATIBILITY (highest priority):
   - Thrive in pH \(parsed.pH)

   - Perform well in \(parsed.drainage) \(parsed.soilTexture) soil

   - Tolerate or benefit from \(parsed.organicMatter) organic matter (or can be amended economically)

   - Compatible with \(dominantSoil?.taxclname ?? "the main soil taxonomy")

ECONOMIC VIABILITY:
   - High profit potential per acre ($/acre gross revenue)

   - Consider both mainstream crops (suitable for large acreage) AND specialty/novelty crops (high value, smaller acreage)

   - Factor in: market demand, processing requirements, labor needs, and harvest logistics proportional to farm area

DIVERSITY STRATEGY:
   - Include 4-5 "anchor crops" suitable for large acreage (100-500+ acres each)

   - Include 4-5 "specialty/novelty crops" with premium pricing (10-100 acres each)

   - Include 1-2 "emerging market" crops with high future potential

ORGANIC CONTEXT: Can include regular crops if organic price is significantly higher. Specify if crop should be organic Prioritize crops with:
Lower pest/disease pressure (reducing input costs)
Premium organic pricing (2-3x conventional)
Good weed competition (important for organic management)
max 3 organic crops, min 1

RESEARCH DEPTH:
Think beyond obvious choices (corn, soybeans, wheat)
Consider: medicinal herbs, specialty vegetables, industrial crops, ethnic market crops, agritourism crops
Include both annual and perennial options
Consider value-added processing opportunities
Consider crops which restore nutrients to soil
Do not include crops such as cannabis or other drugs

OUTPUT FORMAT (for each of 10 crops):
Crop Name (Scientific Name)
Soil Match Analysis: [2-3 sentences on why THIS specific soil is ideal - reference pH, drainage, texture, and CEC considerations]
Economic Profile: [2-3 sentences on market demand, pricing trends, yield expectations, processing/storage requirements]
Scale Recommendation: [Anchor crop: 100-500 acres | Specialty crop: 10-100 acres | Premium crop: 5-50 acres]
Estimated Revenue/Acre: $X - $X (provide range with brief justification)
Key Advantage: [1 sentence on unique selling point for this farm]

Begin with your 10 crop recommendations, ordered from highest to lowest estimated revenue per acre.
"""
        
        AIManager.generateNVidiaStreamingLiveGenericThink(soilData: prompt) { chunk in
            DispatchQueue.main.async {
                if !hasStartedCrops {
                    if chunk.contains("\n") {
                        hasStartedCrops = true
                        let lines = chunk.components(separatedBy: "\n")
                        if lines.count > 1 {
                            cropRecommendations = lines.dropFirst().joined(separator: "\n")
                        }
                    }
                } else {
                    cropRecommendations += chunk
                }
            }
        } completion: { result in
            DispatchQueue.main.async {
                isGeneratingCrops = false
            }
        }
    }
}

struct ParsedSoilData {
    var porosity: String = ""
    var organicMatter: String = ""
    var soilTexture: String = ""
    var pH: String = ""
    var drainage: String = ""
    var color: String = ""
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
                            ForEach(Array(majorSoils.enumerated()), id: \.offset) { index, unit in
                                SoilUnitView(unit: unit)
                            }
                            
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
