import SwiftUI

struct ActionButton: View {
    let state: ActionButtonState
    
    var body: some View {
        Button(action: state.onTap.action) {
            HStack {
                Image(systemName: state.systemImage)
                Text(state.title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(state.isEnabled ? state.color : Color.gray)
            .cornerRadius(10)
        }
        .disabled(!state.isEnabled)
        .accessibilityLabel(state.title)
    }
}

struct ActionButtonState: Equatable {
    let title: String
    let systemImage: String
    let color: Color
    let isEnabled: Bool
    let onTap: UserAction
}
