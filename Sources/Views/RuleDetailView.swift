import SwiftUI

struct RuleDetailView: View {
    @Binding var rule: Rule
    @EnvironmentObject var store: RuleStore
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Rule Name").sectionLabel()
                        TextField("My Rule", text: $rule.name)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3.weight(.semibold))
                    }
                    .padding(20)

                    Divider()

                    // URL Patterns
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("URL Patterns").sectionLabel()
                            Text("Rule fires if ANY pattern matches. Use * as wildcard.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(rule.urlPatterns.indices, id: \.self) { i in
                            HStack(spacing: 6) {
                                TextField("example.com/*", text: $rule.urlPatterns[i])
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                                Button {
                                    rule.urlPatterns.remove(at: i)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button {
                            rule.urlPatterns.append("")
                        } label: {
                            Label("Add Pattern", systemImage: "plus")
                                .font(.body)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.accent)
                    }
                    .padding(20)

                    Divider()

                    // Header Actions
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Header Actions").sectionLabel()
                            Text("Applied to every matching request, in order.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(rule.headerActions.indices, id: \.self) { i in
                            HStack(spacing: 6) {
                                Picker("", selection: $rule.headerActions[i].op) {
                                    ForEach(HeaderOp.allCases) { op in
                                        Text(op.label).tag(op)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 90)

                                TextField("Header name", text: $rule.headerActions[i].name)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))

                                if rule.headerActions[i].op != .remove {
                                    TextField("Value", text: $rule.headerActions[i].value)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                } else {
                                    Color.clear
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 22)
                                }

                                Button {
                                    rule.headerActions.remove(at: i)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button {
                            rule.headerActions.append(HeaderAction())
                        } label: {
                            Label("Add Header Action", systemImage: "plus")
                                .font(.body)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.accent)
                    }
                    .padding(20)
                }
            }

            // Footer
            Divider()
            HStack {
                if showDeleteConfirm {
                    Text("Delete \"\(rule.name.isEmpty ? "this rule" : rule.name)\"?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Cancel") { showDeleteConfirm = false }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("Delete", role: .destructive) {
                        store.deleteRule(rule)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.small)
                } else {
                    Button("Delete Rule", role: .destructive) {
                        showDeleteConfirm = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }

                Spacer()

                Text("Changes apply immediately")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
}
