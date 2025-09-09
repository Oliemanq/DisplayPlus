import SwiftUI
import Foundation
import MapKit

struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var location: CLLocationCoordinate2D?
    @State private var position: MapCameraPosition = .automatic
    @State private var centerCoordinate: CLLocationCoordinate2D?
    
    var theme: ThemeColors
    
    var body: some View {
        ZStack() {
            Map(position: $position, interactionModes: .all)
                .onMapCameraChange { context in
                    self.centerCoordinate = context.camera.centerCoordinate
                }
                .onAppear {
                    // Set the initial center coordinate when the map appears
                    self.centerCoordinate = position.camera?.centerCoordinate
                }
            
            Image(systemName: "mappin")
                .font(.title)
                .foregroundColor(.red)
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            Button("Done") {
                if let center = centerCoordinate {
                    print("Selected location: \(center.latitude), \(center.longitude)")
                    location = center
                    dismiss()
                }else {
                    print("No location selected")
                    dismiss()
                }
            }
            .padding(12)
            .mainButtonStyle(themeIn: theme)
        }
    }
}
