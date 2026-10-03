import SwiftUI

struct TripSegmentRowView: View {
    let segment: TripSegmentInput
    let onFromCityChanged: (String) -> Void
    let onToCityChanged: (String) -> Void
    let onTransportChanged: (TripTransportType) -> Void
    let onDelete: () -> Void
    @State private var fromCityDraft: String
    @State private var toCityDraft: String

    init(
        segment: TripSegmentInput,
        onFromCityChanged: @escaping (String) -> Void,
        onToCityChanged: @escaping (String) -> Void,
        onTransportChanged: @escaping (TripTransportType) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.segment = segment
        self.onFromCityChanged = onFromCityChanged
        self.onToCityChanged = onToCityChanged
        self.onTransportChanged = onTransportChanged
        self.onDelete = onDelete
        _fromCityDraft = State(initialValue: segment.fromCityName)
        _toCityDraft = State(initialValue: segment.toCityName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Segment \(segment.order + 1)")
                    .font(.headline)
                    .foregroundStyle(QuoteBoardTheme.primaryText)

                Spacer()

                if segment.order > 0 {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("From city", text: $fromCityDraft)
            .textFieldStyle(.roundedBorder)
            .onChange(of: fromCityDraft) { newValue in
                onFromCityChanged(newValue)
            }
            .onChange(of: segment.fromCityName) { newValue in
                guard newValue != fromCityDraft else { return }
                fromCityDraft = newValue
            }

            TextField("To city", text: $toCityDraft)
            .textFieldStyle(.roundedBorder)
            .onChange(of: toCityDraft) { newValue in
                onToCityChanged(newValue)
            }
            .onChange(of: segment.toCityName) { newValue in
                guard newValue != toCityDraft else { return }
                toCityDraft = newValue
            }

            Picker("Transport", selection: Binding(
                get: { segment.transportType },
                set: onTransportChanged
            )) {
                ForEach(TripTransportType.allCases) { transportType in
                    Text(transportType.displayName).tag(transportType)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: QuoteBoardTheme.panelCornerRadius, style: .continuous)
                .fill(QuoteBoardTheme.panelFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: QuoteBoardTheme.panelCornerRadius, style: .continuous)
                .stroke(QuoteBoardTheme.panelStroke, lineWidth: 1)
        )
    }
}
