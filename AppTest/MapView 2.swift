import SwiftUI
import MapKit
import FirebaseAuth

// MARK: - Design System
private struct DesignSystem {
    static let cornerRadius: CGFloat = 12
    static let smallPadding: CGFloat = 8
    static let mediumPadding: CGFloat = 16
    static let largePadding: CGFloat = 24
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 4
    static let cardBackgroundOpacity: Double = 0.9
    
    static let primaryColor = AppColorScheme.primary
    static let secondaryColor = AppColorScheme.accent
    static let backgroundColor = AppColorScheme.cardBackground
    static let secondaryBackground = AppColorScheme.backgroundGradient
    static let textPrimary = AppColorScheme.textPrimary
    static let textSecondary = AppColorScheme.textSecondary
    static let accentColor = AppColorScheme.accent
}

// MARK: - Card View Modifier
struct CardView: ViewModifier {
    var backgroundColor: Color = AppColorScheme.cardBackground.opacity(0.95)
    var cornerRadius: CGFloat = DesignSystem.cornerRadius
    
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.mediumPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
                    .shadow(
                        color: AppColorScheme.overlayLight,
                        radius: DesignSystem.shadowRadius,
                        x: 0,
                        y: DesignSystem.shadowY
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppColorScheme.border, lineWidth: 1)
            )
    }
}

// MARK: - Section Header View
struct SectionHeader: View {
    let title: String
    let systemImage: String?
    
    init(_ title: String, systemImage: String? = nil) {
        self.title = title
        self.systemImage = systemImage
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.smallPadding) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .foregroundColor(DesignSystem.accentColor)
            }
            Text(title)
                .font(.headline)
                .foregroundColor(DesignSystem.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, DesignSystem.smallPadding / 2)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let title: String
    
    var body: some View {
        HStack(spacing: DesignSystem.mediumPadding) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text(title)
                .foregroundColor(DesignSystem.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

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
    private let cropRetrievalSystem = CropRetrievalSystem()
    
    var body: some View {
        let modes: MapInteractionModes = isSelecting ? [] : [.pan, .zoom]
        GeometryReader { geometry in
            ZStack {
                Map(coordinateRegion: $region, interactionModes: modes)
                    .mapStyle(.hybrid)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                let rect = createMapRect(from: start, to: end, mapSize: geometry.size)
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
                SoilSelectionPopup(soilData: soilData, selectedRectangle: selectedRectangle, showingSoilDataPopup: $showingSoilDataPopup, cropRetrievalSystem: cropRetrievalSystem)
                    .frame(minWidth: 500, minHeight: 600)
            }
            .sheet(isPresented: $showingSoilDataPopup) {
                SoilDataPopup(soilData: soilData)
                    .frame(minWidth: 600, minHeight: 500)
            }
        }
    }
    
    private func createMapRect(from start: CGPoint, to end: CGPoint, mapSize: CGSize) -> MKMapRect {
        let minX = min(start.x, end.x)
        let maxX = max(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxY = max(start.y, end.y)
        
        let topLeft = CGPoint(x: minX, y: minY)
        let bottomRight = CGPoint(x: maxX, y: maxY)
        
        let topLeftCoord = coordinateFromPoint(topLeft, mapSize: mapSize)
        let bottomRightCoord = coordinateFromPoint(bottomRight, mapSize: mapSize)
        
        return MKMapRect(
            origin: MKMapPoint(topLeftCoord),
            size: MKMapSize(
                width: MKMapPoint(bottomRightCoord).x - MKMapPoint(topLeftCoord).x,
                height: MKMapPoint(bottomRightCoord).y - MKMapPoint(topLeftCoord).y
            )
        )
    }
    
    private func coordinateFromPoint(_ point: CGPoint, mapSize: CGSize) -> CLLocationCoordinate2D {
        let mapWidth = mapSize.width
        let mapHeight = mapSize.height
        
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

// MARK: - Soil Selection Popup
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
    @State private var showingCropPopup = false
    @State private var ragOutput = ""
    @State private var isGeneratingRAG = false
    
    let cropRetrievalSystem: CropRetrievalSystem
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.backgroundGradient
                    .ignoresSafeArea()
                
                if soilData.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: DesignSystem.mediumPadding) {
                            // Growing Zone Card
                            if !growingZone.isEmpty || isLoadingZone {
                                VStack(alignment: .leading, spacing: DesignSystem.smallPadding) {
                                    SectionHeader("Growing Zone", systemImage: "map")
                                    
                                    if isLoadingZone {
                                        LoadingView(title: "Detecting growing zone...")
                                    } else {
                                        HStack {
                                            Text("USDA \(growingZone)")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(DesignSystem.primaryColor)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "leaf.fill")
                                                .foregroundColor(DesignSystem.secondaryColor)
                                        }
                                    }
                                }
                                .modifier(CardView())
                            }
                            
                            // Soil Analysis Card
                            if isGeneratingDescription || !soilDescription.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.smallPadding) {
                                    SectionHeader("Soil Analysis", systemImage: "magnifyingglass")
                                    
                                    if isGeneratingDescription {
                                        LoadingView(title: "Analyzing soil composition...")
                                    } else if !soilDescription.isEmpty {
                                        Text(soilDescription)
                                            .font(.body)
                                            .foregroundColor(DesignSystem.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .modifier(CardView())
                            }
                            
                            // AI Analysis Card
                            if isGenerating || !aiOutput.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.smallPadding) {
                                    SectionHeader("AI Analysis", systemImage: "sparkles")
                                    
                                    if isGenerating {
                                        LoadingView(title: "Generating analysis...")
                                    } else if !aiOutput.isEmpty {
                                        Text(aiOutput)
                                            .font(.body)
                                            .foregroundColor(DesignSystem.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .modifier(CardView())
                            }
                            
                            // Action Buttons
                            VStack(spacing: DesignSystem.smallPadding) {
                                Button(action: {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        showingSoilDataPopup = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "info.circle")
                                        Text("View Detailed Soil Data")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(DesignSystem.primaryColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(DesignSystem.cornerRadius)
                                }
                                
                                Button(action: {
                                    showingCropPopup = true
                                    runRAGPipeline()
                                }) {
                                    HStack {
                                        if isGeneratingCrops || isGeneratingRAG {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: "leaf.arrow.triangle.circlepath")
                                        }
                                        Text("Get Crop Recommendations")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(DesignSystem.secondaryColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(DesignSystem.cornerRadius)
                                }
                                .disabled(isGeneratingCrops || isGeneratingRAG || parsedSoilData == nil || growingZone.isEmpty)
                                .opacity((isGeneratingCrops || isGeneratingRAG || parsedSoilData == nil || growingZone.isEmpty) ? 0.6 : 1)
                            }
                            .padding(.top, DesignSystem.smallPadding)
                        }
                        .padding(DesignSystem.mediumPadding)
                    }
                }
            }
            .navigationTitle("🌱 Area Analysis")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCropPopup) {
                CropRecommendationsPopup(
                    cropRecommendations: $cropRecommendations,
                    isGenerating: $isGeneratingCrops
                )
                .frame(minWidth: 700, minHeight: 600)
            }
            .onAppear {
                fetchGrowingZone()
                generateSoilDescription()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.mediumPadding) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.secondaryColor)
                .padding(.bottom, DesignSystem.smallPadding)
            
            VStack(spacing: DesignSystem.smallPadding) {
                Text("No Soil Data Found")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.textPrimary)
                
                Text("We couldn't find any soil data for the selected area. Please try a different location.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(DesignSystem.largePadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func runRAGPipeline() {
        guard let parsed = parsedSoilData, !parsed.soilTexture.isEmpty else {
            isGeneratingRAG = false
            return
        }
        
        isGeneratingRAG = true
        
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try cropRetrievalSystem.loadCrops(from: "Crops")
                
                let soilTexture = parsed.soilTexture
                let preferredDrainage = parsed.drainage
                
                let phString = parsed.pH.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                let phDouble = Double(phString) ?? 6.5
                
                let zoneNumber = growingZone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                
                print("DEBUG RAG Input: soilTexture=\(soilTexture), drainage=\(preferredDrainage), pH=\(phDouble), zone=\(zoneNumber)")
                
                let bestCrops = cropRetrievalSystem.findBestCrops(
                    soilType: soilTexture,
                    pH: phDouble,
                    drainage: preferredDrainage,
                    usdaZone: zoneNumber,
                    limit: 10
                )
                
                var output = ""
                for crop in bestCrops.prefix(10) {
                    output += "\(crop.commodityType)\n"
                    output += "Revenue: \(crop.revenuePerAcre)\n"
                    output += "pH: \(crop.preferredPH) | Zones: \(crop.usdaZones)\n"
                    output += "Soil: \(crop.soilType) | Drainage: \(crop.preferredSoilDrainage)\n\n"
                }
                
                DispatchQueue.main.async {
                    ragOutput = output
                    isGeneratingRAG = false
                    generateCropRecommendations()
                }
            } catch {
                DispatchQueue.main.async {
                    isGeneratingRAG = false
                }
            }
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
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            let cleanLine = trimmedLine.replacingOccurrences(of: "^- ", with: "", options: .regularExpression)
            let components = cleanLine.components(separatedBy: ": ")
            
            guard components.count >= 2 else { continue }
            
            let key = components[0].trimmingCharacters(in: .whitespaces).lowercased()
            let value = components.dropFirst().joined(separator: ": ").trimmingCharacters(in: .whitespaces)
            
            let cleanValue = value
                .replacingOccurrences(of: "\\[select one: ", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\]", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            switch key {
            case "porosity":
                parsed.porosity = cleanValue
            case "organic matter":
                parsed.organicMatter = cleanValue
            case "soil texture":
                parsed.soilTexture = cleanValue
            case "ph (estimated)":
                parsed.pH = cleanValue
            case "drainage":
                parsed.drainage = cleanValue
            case "color (estimated)":
                parsed.color = cleanValue
            default:
                break
            }
        }
        
        parsedSoilData = parsed
        print("DEBUG Parsed Soil Data: Texture=\(parsed.soilTexture), Drainage=\(parsed.drainage), pH=\(parsed.pH)")
    }
    
    private func generateCropRecommendations() {
        guard let parsed = parsedSoilData, !growingZone.isEmpty, !ragOutput.isEmpty else { return }
        
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

Considering the following crop recommendations, pick 5-10 of the most fitting crops for this farm. Give a short explanation on why each choice is fitting for the farm, considering its soil type and size.

Crops:
\(ragOutput)

ECONOMIC VIABILITY:
   - High profit potential per acre ($/acre gross revenue)
   - Consider both mainstream crops (suitable for large acreage) AND specialty/novelty crops (high value, smaller acreage)
   - Factor in: market demand, processing requirements, labor needs, and harvest logistics proportional to farm area

DIVERSITY STRATEGY:
   - Include some "anchor crops" suitable for large acreage (100-500+ acres each)
   - Include some "specialty/novelty crops" with premium pricing (10-100 acres each)
   - Include one or two "emerging market" crops with high future potential
   - Two flowers maximum, especially if it is a larger farm

RESEARCH DEPTH:
Consider both annual and perennial options
Consider value-added processing opportunities
Consider crops which restore nutrients to soil

OUTPUT FORMAT (for each crop):
Crop Name (Crop Scientific Name)
Crop Description: [3 sentences on what is this crop, what is it used for/parts used, growth habits, what is it known for]
Soil Match Analysis: [1-2 sentence on why THIS specific soil is ideal - reference pH, drainage, texture, and CEC considerations]
Economic Profile: [1 sentence on market demand, pricing trends, yield expectations, processing/storage requirements]
Estimated Revenue/Acre: $X - $X (restate given range)
Key Advantage: [1 sentence on unique selling point for this farm]

***NO EXTRA FANCY FORMATTING, JUST PLAIN TEXT****

Begin with your crop recommendations, ordered from highest to lowest estimated revenue per acre.
"""
        
        AIManager.generateNVidiaStreamingLiveGenericThink(soilData: prompt, includeThinking: false) { chunk in
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

struct CropRecommendationsPopup: View {
    @Binding var cropRecommendations: String
    @Binding var isGenerating: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var cropImages: [String: NSImage] = [:]
    @State private var selectedCrop: ParsedCrop?
    
    private var parsedCrops: [ParsedCrop] {
            let lines = cropRecommendations.components(separatedBy: "\n")
            var crops: [ParsedCrop] = []
            var currentCrop: ParsedCrop?
            var estimatedRevenue = ""
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                
                if trimmed.range(of: "^\\*?\\*?\\d+\\.\\s*(.+?)\\s*\\(", options: .regularExpression) != nil ||
                   (trimmed.contains("(") && trimmed.contains(")") && !trimmed.contains(":") && !trimmed.contains("Crop")) {
                    
                    if let crop = currentCrop {
                        var finalCrop = crop
                        if !estimatedRevenue.isEmpty {
                            finalCrop.estimatedRevenue = estimatedRevenue
                        }
                        crops.append(finalCrop)
                    }
                    
                    var cropName = trimmed
                    cropName = cropName.replacingOccurrences(of: "^\\*+\\d+\\.\\s*", with: "", options: .regularExpression)
                    cropName = cropName.replacingOccurrences(of: "\\*+$", with: "")
                    
                    if let parenIndex = cropName.firstIndex(of: "(") {
                        cropName = String(cropName[..<parenIndex]).trimmingCharacters(in: .whitespaces)
                    }
                    
                    currentCrop = ParsedCrop(name: cropName, fullText: trimmed)
                    estimatedRevenue = ""
                } else if trimmed.contains("Estimated Revenue/Acre:") {
                    if let colonIndex = trimmed.firstIndex(of: ":") {
                        estimatedRevenue = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                    }
                    if var crop = currentCrop {
                        crop.fullText += "\n" + trimmed
                        currentCrop = crop
                    }
                } else if !trimmed.isEmpty, var crop = currentCrop {
                    crop.fullText += "\n" + trimmed
                    currentCrop = crop
                }
            }
            
            if let crop = currentCrop {
                var finalCrop = crop
                if !estimatedRevenue.isEmpty {
                    finalCrop.estimatedRevenue = estimatedRevenue
                }
                crops.append(finalCrop)
            }
            
            return crops
        }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.backgroundGradient
                    .ignoresSafeArea()
                
                if isGenerating && cropRecommendations.isEmpty {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating crop recommendations...")
                            .font(.headline)
                            .foregroundColor(AppColorScheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(parsedCrops) { crop in
                                CropItemView(crop: crop, selectedCrop: $selectedCrop)
                                    .onAppear {
                                        fetchCropImage(for: crop.name)
                                    }
                            }
                            
                            if isGenerating {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Generating...")
                                        .font(.caption)
                                        .foregroundColor(AppColorScheme.textSecondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Crop Recommendations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedCrop) { crop in
            CropDetailPopup(crop: crop, cropImage: cropImages[crop.name])
                .frame(minWidth: 600, minHeight: 500)
        }
    }
    
    private func fetchCropImage(for cropName: String) {
        guard cropImages[cropName] == nil else { return }
        
        let cleanName = cropName
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
        
        let apiURL = "https://en.wikipedia.org/api/rest_v1/page/summary/\(cleanName)"
        
        guard let url = URL(string: apiURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("SoilMapApp/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 5.0
        
        DispatchQueue.global(qos: .userInitiated).async {
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data else { return }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        var imageURLString: String?
                        
                        if let originalImage = json["originalimage"] as? [String: Any],
                           let source = originalImage["source"] as? String {
                            imageURLString = source
                        }
                        else if let thumbnail = json["thumbnail"] as? [String: Any],
                                let source = thumbnail["source"] as? String {
                            imageURLString = source
                        }
                        
                        if let imageURLString = imageURLString,
                           let imageURL = URL(string: imageURLString) {
                            
                            var imageRequest = URLRequest(url: imageURL)
                            imageRequest.timeoutInterval = 5.0
                            
                            URLSession.shared.dataTask(with: imageRequest) { imageData, _, _ in
                                guard let imageData = imageData, let image = NSImage(data: imageData) else { return }
                                
                                DispatchQueue.main.async {
                                    cropImages[cropName] = image
                                }
                            }.resume()
                        }
                    }
                } catch {
                    print("Error parsing Wikipedia response for \(cropName): \(error)")
                }
            }.resume()
        }
    }
}

struct ParsedCrop: Identifiable {
    let id = UUID()
    let name: String
    var fullText: String
    var estimatedRevenue: String = ""
    
    init(name: String, fullText: String) {
        self.name = name
        self.fullText = fullText
        self.estimatedRevenue = ParsedCrop.extractRevenue(from: fullText)
    }
    
    private static func extractRevenue(from text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            if line.contains("Estimated Revenue/Acre:") || line.contains("Revenue/Acre:") {
                if let colonIndex = line.firstIndex(of: ":") {
                    return String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return "N/A"
    }
}

struct CropItemView: View {
    let crop: ParsedCrop
    @Binding var selectedCrop: ParsedCrop?
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            selectedCrop = crop
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(crop.name)
                        .font(.headline)
                        .foregroundColor(AppColorScheme.primary)
                        .underline()
                    
                    Text("Estimated Revenue: \(crop.estimatedRevenue)")
                        .font(.subheadline)
                        .foregroundColor(AppColorScheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColorScheme.textSecondary)
            }
            .padding()
            .background(isHovered ? AppColorScheme.primary.opacity(0.05) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColorScheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct CropDetailPopup: View {
    let crop: ParsedCrop
    let cropImage: NSImage?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showGardeningVideos = false
    @StateObject private var gardenManager = MyGardenManager()
    @State private var showGardenAdded = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let image = cropImage {
                        HStack {
                            Spacer()
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 300, maxHeight: 300)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                            Spacer()
                        }
                        .padding(.vertical)
                    }
                    
                    Text(crop.fullText)
                        .textSelection(.enabled)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    
                    // Add to Garden Button
                    Button(action: {
                        if let userId = authViewModel.user?.uid {
                            gardenManager.addPlant(crop: crop, userId: userId)
                            showGardenAdded = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showGardenAdded = false
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(showGardenAdded ? "Added to Garden!" : "Add to My Garden")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(showGardenAdded ? Color(red: 0.25, green: 0.70, blue: 0.60) : Color(red: 0.25, green: 0.70, blue: 0.60))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(showGardenAdded)
                    
                    // Gardening Videos Section (only show if user selected gardening)
                    if shouldShowGardeningVideos {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundColor(.blue)
                                Text("Gardening Videos")
                                    .font(.headline)
                                Spacer()
                                Button(showGardeningVideos ? "Hide Videos" : "Show Videos") {
                                    showGardeningVideos.toggle()
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            if showGardeningVideos {
                                GardeningVideoView(cropName: crop.name)
                                    .frame(height: 400)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(crop.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var shouldShowGardeningVideos: Bool {
        // Temporarily show videos for all users for testing
        return true
        // Original logic: return authViewModel.userUsage.lowercased().contains("gardening")
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

// MARK: - Soil Data Popup
struct SoilDataPopup: View {
    let soilData: [SoilDataService.MapUnit]
    @Environment(\.dismiss) private var dismiss
    @State private var showMinorSoils = false
    @State private var selectedSoil: SoilDataService.MapUnit?
    @State private var showingDetail = false
    
    private var majorSoils: [SoilDataService.MapUnit] {
        soilData.filter { $0.component_pct_of_aoi >= 5.0 }
            .sorted { $0.component_pct_of_aoi > $1.component_pct_of_aoi }
    }
    
    private var minorSoils: [SoilDataService.MapUnit] {
        soilData.filter { $0.component_pct_of_aoi < 5.0 }
            .sorted { $0.component_pct_of_aoi > $1.component_pct_of_aoi }
    }
    
    private var totalMinorPercentage: Double {
        minorSoils.reduce(0) { $0 + $1.component_pct_of_aoi }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColorScheme.backgroundGradient
                    .ignoresSafeArea()
                
                if soilData.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: DesignSystem.mediumPadding) {
                            // Summary Card
                            VStack(alignment: .leading, spacing: DesignSystem.smallPadding) {
                                SectionHeader("Area Overview", systemImage: "map")
                                
                                HStack(spacing: DesignSystem.mediumPadding) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(soilData.count)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(DesignSystem.primaryColor)
                                        Text("Soil Types")
                                            .font(.caption)
                                            .foregroundColor(DesignSystem.textSecondary)
                                    }
                                    
                                    Divider()
                                        .frame(height: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(String(format: "%.1f", majorSoils.first?.component_pct_of_aoi ?? 0))%")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(DesignSystem.primaryColor)
                                        Text("Primary Soil")
                                            .font(.caption)
                                            .foregroundColor(DesignSystem.textSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .modifier(CardView())
                            
                            // Major Soils Section
                            if !majorSoils.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.smallPadding) {
                                    SectionHeader("Major Soil Types", systemImage: "leaf.fill")
                                    
                                    VStack(spacing: DesignSystem.smallPadding) {
                                        ForEach(Array(majorSoils.enumerated()), id: \.offset) { index, unit in
                                            SoilUnitCard(unit: unit) {
                                                selectedSoil = unit
                                                showingDetail = true
                                            }
                                        }
                                    }
                                }
                                .modifier(CardView())
                            }
                            
                            // Minor Soils Section
                            if !minorSoils.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.smallPadding) {
                                    Button(action: { withAnimation { showMinorSoils.toggle() } }) {
                                        HStack {
                                            SectionHeader("Minor Soil Types (\(String(format: "%.1f", totalMinorPercentage))%)", 
                                                        systemImage: showMinorSoils ? "chevron.down" : "chevron.right")
                                            
                                            Spacer()
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if showMinorSoils {
                                        VStack(spacing: DesignSystem.smallPadding) {
                                            ForEach(Array(minorSoils.enumerated()), id: \.offset) { index, unit in
                                                SoilUnitCard(unit: unit) {
                                                    selectedSoil = unit
                                                    showingDetail = true
                                                }
                                            }
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                                .modifier(CardView())
                            }
                            
                            // Legend
                            VStack(alignment: .leading, spacing: DesignSystem.smallPadding) {
                                SectionHeader("Legend", systemImage: "info.circle")
                                
                                HStack(spacing: DesignSystem.mediumPadding) {
                                    LegendItem(color: DesignSystem.primaryColor, label: "Major (>5%)")
                                    LegendItem(color: DesignSystem.secondaryColor, label: "Minor (<5%)")
                                }
                            }
                            .modifier(CardView())
                        }
                        .padding(DesignSystem.mediumPadding)
                    }
                }
            }
            .navigationTitle("🌱 Soil Composition")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedSoil) { soil in
                SoilDetailView(soil: soil)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.mediumPadding) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.secondaryColor)
                .padding(.bottom, DesignSystem.smallPadding)
            
            VStack(spacing: DesignSystem.smallPadding) {
                Text("No Soil Data Found")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.textPrimary)
                
                Text("We couldn't find any soil data for the selected area. Please try a different location.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(DesignSystem.largePadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Soil Unit Card
private struct SoilUnitCard: View {
    let unit: SoilDataService.MapUnit
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.mediumPadding) {
                // Color indicator
                Circle()
                    .fill(unit.component_pct_of_aoi >= 5.0 ? DesignSystem.primaryColor : DesignSystem.secondaryColor)
                    .frame(width: 12, height: 12)
                
                // Soil info
                VStack(alignment: .leading, spacing: 2) {
                    Text(unit.muname)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.textPrimary)
                        .lineLimit(1)
                    
                    Text(unit.taxclname)
                        .font(.caption)
                        .foregroundColor(DesignSystem.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Percentage
                Text("\(String(format: "%.1f", unit.component_pct_of_aoi))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(unit.component_pct_of_aoi >= 5.0 ? DesignSystem.primaryColor : DesignSystem.secondaryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((unit.component_pct_of_aoi >= 5.0 ? DesignSystem.primaryColor : DesignSystem.secondaryColor).opacity(0.1))
                    )
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary)
            }
            .padding(DesignSystem.smallPadding)
            .background(DesignSystem.secondaryBackground.opacity(0.5))
            .cornerRadius(DesignSystem.cornerRadius / 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legend Item
private struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: DesignSystem.smallPadding) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.caption)
                .foregroundColor(DesignSystem.textSecondary)
        }
    }
}

// MARK: - Soil Detail View
private struct SoilDetailView: View {
    let soil: SoilDataService.MapUnit
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.mediumPadding) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignSystem.smallPadding) {
                        Text(soil.muname)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.primaryColor)
                        
                        Text(soil.taxclname)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, DesignSystem.smallPadding)
                    
                    // Stats
                    HStack(spacing: DesignSystem.mediumPadding) {
                        StatItem(value: "\(String(format: "%.1f", soil.component_pct_of_aoi))%", 
                                label: "Area Coverage")
                        
                        Divider()
                            .frame(height: 40)
                        
                        StatItem(value: soil.irrcapcl?.capitalized ?? "N/A", 
                                label: "Irrigation")
                        
                        Divider()
                            .frame(height: 40)
                        
                        StatItem(value: soil.drainagecl?.capitalized ?? "N/A", 
                                label: "Drainage")
                    }
                    .padding(.vertical, DesignSystem.smallPadding)
                    
                    // Details
                    VStack(alignment: .leading, spacing: DesignSystem.smallPadding) {
                        DetailRow(label: "Slope:", value: soil.slopegradwta?.capitalized ?? "N/A")
                        DetailRow(label: "Flooding:", value: soil.flodfreqcl?.capitalized ?? "None")
                        DetailRow(label: "Erosion:", value: soil.erocl?.capitalized ?? "N/A")
                        DetailRow(label: "Runoff:", value: soil.runoff?.capitalized ?? "N/A")
                    }
                    .padding(.vertical, DesignSystem.smallPadding)
                    
                    Spacer()
                }
                .padding(DesignSystem.mediumPadding)
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Stat Item
private struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.headline)
                .foregroundColor(DesignSystem.primaryColor)
            
            Text(label)
                .font(.caption)
                .foregroundColor(DesignSystem.textSecondary)
        }
    }
}

// MARK: - Detail Row
private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(DesignSystem.textSecondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.body)
                .foregroundColor(DesignSystem.textPrimary)
            
            Spacer()
        }
    }
}

#Preview {
    MapView()
}
