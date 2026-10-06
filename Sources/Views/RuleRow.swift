import SwiftUI

struct RuleRow: View {
    @Binding var rule: Rule

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(rule.enabled ? Color.green : Color.secondary.opacity(0.35))
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name.isEmpty ? "Unnamed Rule" : rule.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(rule.urlPreview)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: $rule.enabled)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
        }
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}
